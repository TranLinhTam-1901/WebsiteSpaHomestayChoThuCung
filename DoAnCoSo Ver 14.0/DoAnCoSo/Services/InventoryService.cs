using DoAnCoSo.Models;
using Microsoft.EntityFrameworkCore;
namespace DoAnCoSo.Services
{
    public interface IInventoryService
    {
        Task AdjustStockAsync(int productId, int delta, string reason = "Manual",
                              string? referenceId = null, string? byUserId = null, string? note = null,CancellationToken ct = default);
        Task<bool> DeductForOrderAsync(int orderId, string? byUserId = null, CancellationToken ct = default);

        Task<bool> RestockForOrderAsync(int orderId, string? byUserId = null, CancellationToken ct = default);
        Task<int> GetAvailableAsync(int productId);

        Task ReserveForOrderAsync(int orderId, string byUserId);

        Task UnreserveForOrderAsync(int orderId, string byUserId);
        Task ConfirmOrderAtomicallyAsync(int orderId, string byUserId, CancellationToken ct = default);
        Task CancelOrderAtomicallyAsync(int orderId, string byUserId, CancellationToken ct = default);
    }
    public class InventoryService : IInventoryService
    {
        private readonly ApplicationDbContext _db;
        public InventoryService(ApplicationDbContext db) => _db = db;

        public async Task AdjustStockAsync(int productId, int delta, string reason = "Manual",
                                           string? referenceId = null, string? byUserId = null,
                                            string? note = null, CancellationToken ct = default)
        {
            await using var tx = await _db.Database.BeginTransactionAsync(ct);

            await AdjustStockCoreAsync(productId, delta, reason, referenceId, byUserId, note, ct);

            await tx.CommitAsync(ct);
        }

        public async Task<bool> DeductForOrderAsync(int orderId, string? byUserId = null, CancellationToken ct = default)
        {
            await using var tx = await _db.Database.BeginTransactionAsync(ct);

            var order = await _db.Orders
                .Include(o => o.OrderDetails)
                .FirstOrDefaultAsync(o => o.Id == orderId, ct);
            if (order == null) return false;

            var ids = order.OrderDetails.Select(d => d.ProductId).Distinct().ToList();
            var products = await _db.Products.Where(p => ids.Contains(p.Id)).ToListAsync(ct);

            // Kiểm tồn đủ
            foreach (var d in order.OrderDetails)
            {
                var p = products.First(x => x.Id == d.ProductId);
                if (p.StockQuantity < d.Quantity)
                    throw new InvalidOperationException($"\"{p.Name}\" không đủ tồn (cần {d.Quantity}, còn {p.StockQuantity}).");
            }

            // Trừ kho + log
            foreach (var d in order.OrderDetails)
            {
                var p = products.First(x => x.Id == d.ProductId);
                p.StockQuantity -= d.Quantity;
                p.ReservedQuantity -= d.Quantity; // ✅ giảm luôn hàng đã giữ
                p.SoldQuantity += d.Quantity;

                _db.InventoryLogs.Add(new InventoryLog
                {
                    ProductId = d.ProductId,
                    QuantityChange = -d.Quantity,
                    Reason = "OrderConfirmed",
                    ReferenceId = order.Id.ToString(),
                    PerformedByUserId = byUserId,
                    CreatedAt = DateTime.UtcNow
                });
            }

            await _db.SaveChangesAsync(ct);
            await tx.CommitAsync(ct);
            return true;
        }

        public async Task<bool> RestockForOrderAsync(int orderId, string? byUserId = null, CancellationToken ct = default)
        {
            await using var tx = await _db.Database.BeginTransactionAsync(ct);

            var order = await _db.Orders
                .Include(o => o.OrderDetails)
                .FirstOrDefaultAsync(o => o.Id == orderId, ct);
            if (order == null) return false;

            foreach (var d in order.OrderDetails)
            {
                await AdjustStockInternal(d.ProductId, +d.Quantity, "OrderCanceled", order.Id.ToString(), byUserId, ct);
            }

            await tx.CommitAsync(ct);
            return true;
        }

        // Nội bộ: không mở transaction lồng nhau
        private async Task AdjustStockInternal(int productId, int delta, string reason, string? referenceId, string? byUserId, CancellationToken ct)
        {
            var p = await _db.Products.FirstAsync(x => x.Id == productId, ct);

            checked
            {
                p.StockQuantity += delta;
                if (delta < 0) p.SoldQuantity += Math.Abs(delta);
            }

            _db.InventoryLogs.Add(new InventoryLog
            {
                ProductId = productId,
                QuantityChange = delta,
                Reason = reason,
                ReferenceId = referenceId,
                PerformedByUserId = byUserId,
                CreatedAt = DateTime.UtcNow
            });

            await _db.SaveChangesAsync(ct);
        }

        public async Task<int> GetAvailableAsync(int productId)
        {
            var p = await _db.Products.AsNoTracking()
        .FirstOrDefaultAsync(x => x.Id == productId);

            if (p == null) return 0;

            var available = p.StockQuantity - p.ReservedQuantity;
            return available < 0 ? 0 : available;
        }

        public async Task ReserveForOrderAsync(int orderId, string byUserId)
        {
            var strategy = _db.Database.CreateExecutionStrategy();
            await strategy.ExecuteAsync(async () =>
            {
                await using var tx = await _db.Database.BeginTransactionAsync();
                await ReserveForOrderCoreAsync(orderId, byUserId, CancellationToken.None);
                await tx.CommitAsync();
            });
        }

        public async Task UnreserveForOrderAsync(int orderId, string byUserId)
        {
            var strategy = _db.Database.CreateExecutionStrategy();
            await strategy.ExecuteAsync(async () =>
            {
                await using var tx = await _db.Database.BeginTransactionAsync();
                await UnreserveForOrderCoreAsync(orderId, byUserId, CancellationToken.None);
                await tx.CommitAsync();
            });
        }

        public async Task ConfirmOrderAtomicallyAsync(int orderId, string byUserId, CancellationToken ct = default)
        {
            var strategy = _db.Database.CreateExecutionStrategy();
            await strategy.ExecuteAsync(async () =>
            {
                await using var tx = await _db.Database.BeginTransactionAsync(ct);

                var order = await _db.Orders
                    .Include(o => o.OrderDetails)
                    .FirstOrDefaultAsync(o => o.Id == orderId, ct)
                    ?? throw new InvalidOperationException("Order not found.");

                if (order.Status != OrderStatusEnum.ChoXacNhan)
                    throw new InvalidOperationException("Order is not pending.");

                // 1) Bỏ giữ (KHÔNG mở transaction mới)
                await UnreserveForOrderCoreAsync(orderId, byUserId, ct);

                // 2) Kiểm tồn, trừ kho + 3) tăng sold
                foreach (var d in order.OrderDetails)
                {
                    var p = await _db.Products.FirstAsync(x => x.Id == d.ProductId, ct);
                    if (p.StockQuantity < d.Quantity)
                        throw new InvalidOperationException($"\"{p.Name}\" không đủ tồn (cần {d.Quantity}, còn {p.StockQuantity}).");

                    await AdjustStockCoreAsync(
                        d.ProductId, -d.Quantity,
                        "OrderConfirmed", $"Order:{order.Id}", byUserId,
                        $"Confirm order #{order.Id}", ct);

                    await IncreaseSoldCoreAsync(d.ProductId, d.Quantity, ct);
                }

                // 4) đổi trạng thái
                order.Status = OrderStatusEnum.DaXacNhan;
                await _db.SaveChangesAsync(ct);

                await tx.CommitAsync(ct);
            });
        }

        public async Task CancelOrderAtomicallyAsync(int orderId, string byUserId, CancellationToken ct = default)
        {
            var strategy = _db.Database.CreateExecutionStrategy();
            await strategy.ExecuteAsync(async () =>
            {
                await using var tx = await _db.Database.BeginTransactionAsync(ct);

                var order = await _db.Orders
                    .Include(o => o.OrderDetails)
                    .FirstOrDefaultAsync(o => o.Id == orderId, ct)
                    ?? throw new InvalidOperationException("Order not found.");

                // Đã trừ kho chưa? (dựa log)
                bool committed = await _db.InventoryLogs.AnyAsync(l =>
                    l.Reason == "OrderConfirmed" && l.ReferenceId == $"Order:{orderId}", ct);

                if (committed)
                {
                    // Hoàn kho thật + giảm sold
                    foreach (var d in order.OrderDetails)
                    {
                        await AdjustStockCoreAsync(
                            d.ProductId, +d.Quantity,
                            "OrderCanceledRestock", $"Order:{order.Id}", byUserId,
                            $"Cancel order #{order.Id} - restock", ct);

                        await DecreaseSoldCoreAsync(d.ProductId, d.Quantity, ct);
                    }
                }
                else
                {
                    // Chưa trừ kho → chỉ bỏ giữ
                    await UnreserveForOrderCoreAsync(orderId, byUserId, ct);
                }

                order.Status = OrderStatusEnum.DaHuy;
                await _db.SaveChangesAsync(ct);

                await tx.CommitAsync(ct);
            });
        }

        // === CORE (KHÔNG mở transaction) ==========================================
        private async Task AdjustStockCoreAsync(
            int productId, int delta, string reason, string? referenceId, string? byUserId, string? note, CancellationToken ct)
        {
            var p = await _db.Products.FirstOrDefaultAsync(x => x.Id == productId, ct)
                    ?? throw new InvalidOperationException("Không tìm thấy sản phẩm.");

            checked { p.StockQuantity += delta; } // + nhập, - xuất

            _db.InventoryLogs.Add(new InventoryLog
            {
                ProductId = productId,
                QuantityChange = delta,
                Reason = reason,
                ReferenceId = referenceId,
                PerformedByUserId = byUserId,
                Note = note,
                CreatedAt = DateTime.UtcNow
            });

            await _db.SaveChangesAsync(ct);
        }

        private async Task ReserveForOrderCoreAsync(int orderId, string byUserId, CancellationToken ct)
        {
            var order = await _db.Orders
                .Include(o => o.OrderDetails).ThenInclude(d => d.Product)
                .FirstOrDefaultAsync(o => o.Id == orderId, ct)
                ?? throw new InvalidOperationException("Không tìm thấy đơn hàng để giữ hàng.");

            foreach (var d in order.OrderDetails)
            {
                var p = d.Product!;
                var available = p.StockQuantity - p.ReservedQuantity;
                if (available < d.Quantity)
                    throw new InvalidOperationException($"Không đủ hàng cho '{p.Name}' (còn {available}).");

                p.ReservedQuantity += d.Quantity;

                _db.InventoryLogs.Add(new InventoryLog
                {
                    ProductId = p.Id,
                    QuantityChange = -d.Quantity,
                    Reason = "OrderReserved",
                    ReferenceId = order.Id.ToString(),
                    PerformedByUserId = byUserId,
                    CreatedAt = DateTime.UtcNow
                });
            }
            await _db.SaveChangesAsync(ct);
        }

        private async Task UnreserveForOrderCoreAsync(int orderId, string byUserId, CancellationToken ct)
        {
            var order = await _db.Orders
                .Include(o => o.OrderDetails).ThenInclude(d => d.Product)
                .FirstOrDefaultAsync(o => o.Id == orderId, ct)
                ?? throw new InvalidOperationException("Không tìm thấy đơn hàng để bỏ giữ.");

            foreach (var d in order.OrderDetails)
            {
                var p = d.Product!;
                if (p.ReservedQuantity < d.Quantity)
                    throw new InvalidOperationException($"Số giữ tạm không đủ để hoàn cho '{p.Name}'.");

                p.ReservedQuantity -= d.Quantity;

                _db.InventoryLogs.Add(new InventoryLog
                {
                    ProductId = p.Id,
                    QuantityChange = +d.Quantity,
                    Reason = "OrderUnreserved",
                    ReferenceId = order.Id.ToString(),
                    PerformedByUserId = byUserId,
                    CreatedAt = DateTime.UtcNow
                });
            }
            await _db.SaveChangesAsync(ct);
        }

        private async Task IncreaseSoldCoreAsync(int productId, int qty, CancellationToken ct)
        {
            var p = await _db.Products.FirstAsync(x => x.Id == productId, ct);
            p.SoldQuantity += qty;
            await _db.SaveChangesAsync(ct);
        }

        private async Task DecreaseSoldCoreAsync(int productId, int qty, CancellationToken ct)
        {
            var p = await _db.Products.FirstAsync(x => x.Id == productId, ct);
            p.SoldQuantity = Math.Max(0, p.SoldQuantity - qty);
            await _db.SaveChangesAsync(ct);
        }


    }

}
