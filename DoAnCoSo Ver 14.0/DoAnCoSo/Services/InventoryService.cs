using DoAnCoSo.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
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

        Task AdjustStockVariantAsync(int variantId, int delta, string reason = "Manual",
        string? referenceId = null, string? byUserId = null, string? note = null, CancellationToken ct = default);

        Task<int> GetAvailableVariantAsync(int variantId);

        // IInventoryService
        Task<Dictionary<int, int>> GetVariantCartHoldsAsync(int productId, CancellationToken ct = default);

    }
    public class InventoryService : IInventoryService
    {
        private readonly ApplicationDbContext _db;
        public InventoryService(ApplicationDbContext db) => _db = db;

        public async Task AdjustStockAsync(
        int productId, int delta, string reason = "Manual",
        string? referenceId = null, string? byUserId = null,
        string? note = null, CancellationToken ct = default)
        {
            // Chỉ mở transaction nếu chưa có transaction ngoài
            var hasOuterTx = _db.Database.CurrentTransaction != null;
            IDbContextTransaction? tx = null;

            if (!hasOuterTx)
                tx = await _db.Database.BeginTransactionAsync(ct);

            await AdjustStockCoreAsync(productId, delta, reason, referenceId, byUserId, note, ct);

            if (!hasOuterTx && tx is not null)
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

                // 2) Kiểm tồn & trừ kho đúng cấp (variant nếu có, ngược lại product)
                foreach (var d in order.OrderDetails)
                {
                    if (d.VariantId != null)
                    {
                        // ✅ Trường hợp có biến thể: kiểm tồn ở biến thể
                        var v = await _db.ProductVariants.FirstAsync(x => x.Id == d.VariantId.Value, ct);
                        if (v.StockQuantity < d.Quantity)
                            throw new InvalidOperationException(
                                $"Biến thể \"{v.Name}\" không đủ tồn (cần {d.Quantity}, còn {v.StockQuantity}).");

                        // Trừ kho ở biến thể (đồng thời log VariantId và tự cập nhật SoldQuantity của biến thể)
                        await AdjustStockVariantAsync(
                            d.VariantId.Value,
                            -d.Quantity,
                            reason: "OrderConfirmed",
                            referenceId: $"Order:{order.Id}",
                            byUserId: byUserId,
                            note: $"Confirm order #{order.Id} - variant",
                            ct: ct
                        );
                    }
                    else
                    {
                        // ✅ Trường hợp không có biến thể: kiểm tồn ở sản phẩm
                        var p = await _db.Products.FirstAsync(x => x.Id == d.ProductId, ct);
                        if (p.StockQuantity < d.Quantity)
                            throw new InvalidOperationException(
                                $"\"{p.Name}\" không đủ tồn (cần {d.Quantity}, còn {p.StockQuantity}).");

                        await AdjustStockCoreAsync(
                            d.ProductId,
                            -d.Quantity,
                            reason: "OrderConfirmed",
                            referenceId: $"Order:{order.Id}",
                            byUserId: byUserId,
                            note: $"Confirm order #{order.Id}",
                            ct: ct
                        );
                    }

                    // ✅ Luôn cộng sold cấp sản phẩm để thống kê tổng theo Product
                    await IncreaseSoldCoreAsync(d.ProductId, d.Quantity, ct);
                }

                // 3) Đổi trạng thái
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
                    foreach (var d in order.OrderDetails)
                    {
                        if (d.VariantId != null)
                        {
                            await AdjustStockVariantAsync(
                                d.VariantId.Value,
                                +d.Quantity,
                                reason: "OrderCanceledRestock",
                                referenceId: $"Order:{order.Id}",
                                byUserId: byUserId,
                                note: $"Cancel order #{order.Id} - restock variant",
                                ct: ct
                            );
                            await DecreaseSoldVariantCoreAsync(d.VariantId.Value, d.Quantity, ct);
                        }
                        else
                        {
                            await AdjustStockCoreAsync(
                                d.ProductId,
                                +d.Quantity,
                                reason: "OrderCanceledRestock",
                                referenceId: $"Order:{order.Id}",
                                byUserId: byUserId,
                                note: $"Cancel order #{order.Id} - restock",
                                ct: ct
                            );
                        }

                        await DecreaseSoldCoreAsync(d.ProductId, d.Quantity, ct);
                    }
                }


                order.Status = OrderStatusEnum.DaHuy;
                await _db.SaveChangesAsync(ct);

                await tx.CommitAsync(ct);
            });
        }
        private async Task DecreaseSoldVariantCoreAsync(int variantId, int quantity, CancellationToken ct)
        {
            var v = await _db.ProductVariants.FirstOrDefaultAsync(x => x.Id == variantId, ct)
                    ?? throw new InvalidOperationException("Không tìm thấy biến thể.");

            // Không cho âm
            var newSold = v.SoldQuantity - quantity;
            v.SoldQuantity = newSold < 0 ? 0 : newSold;

            await _db.SaveChangesAsync(ct);
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

                if (d.VariantId != null)
                {
                    var v = await _db.ProductVariants.FirstAsync(x => x.Id == d.VariantId.Value, ct);
                    var vAvail = v.StockQuantity - v.ReservedQuantity;
                    if (vAvail < d.Quantity)
                        throw new InvalidOperationException($"Không đủ hàng cho biến thể '{v.Name}' (còn {vAvail}).");

                    v.ReservedQuantity += d.Quantity; // ✅ giữ tạm ở biến thể
                }
                else
                {
                    p.ReservedQuantity += d.Quantity;  // giữ tạm ở sản phẩm (không biến thể)
                }

                _db.InventoryLogs.Add(new InventoryLog
                {
                    ProductId = p.Id,
                    VariantId = d.VariantId,        // ✅ log theo biến thể nếu có
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
                if (d.VariantId != null)
                {
                    var v = await _db.ProductVariants.FirstAsync(x => x.Id == d.VariantId.Value, ct);
                    if (v.ReservedQuantity < d.Quantity)
                        throw new InvalidOperationException($"Giữ tạm biến thể '{v.Name}' không đủ để hoàn.");
                    v.ReservedQuantity -= d.Quantity; // ✅ trả giữ tạm ở biến thể
                }
                else
                {
                    if (p.ReservedQuantity < d.Quantity)
                        throw new InvalidOperationException($"Giữ tạm sản phẩm '{p.Name}' không đủ để hoàn.");
                    p.ReservedQuantity -= d.Quantity;
                }

                _db.InventoryLogs.Add(new InventoryLog
                {
                    ProductId = p.Id,
                    VariantId = d.VariantId,
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

        public async Task AdjustStockVariantAsync(
        int variantId, int delta, string reason = "Manual",
        string? referenceId = null, string? byUserId = null,
        string? note = null, CancellationToken ct = default)
        {
            // Chỉ mở transaction nếu chưa có transaction ngoài
            var hasOuterTx = _db.Database.CurrentTransaction != null;
            IDbContextTransaction? tx = null;

            if (!hasOuterTx)
                tx = await _db.Database.BeginTransactionAsync(ct);

            var v = await _db.ProductVariants.FirstOrDefaultAsync(x => x.Id == variantId, ct)
                    ?? throw new InvalidOperationException("Không tìm thấy biến thể.");

            checked
            {
                v.StockQuantity += delta;
                if (delta < 0) v.SoldQuantity += Math.Abs(delta);
                if (v.StockQuantity < 0) throw new InvalidOperationException("Tồn biến thể không được âm.");
            }

            _db.InventoryLogs.Add(new InventoryLog
            {
                ProductId = v.ProductId,
                VariantId = v.Id,
                QuantityChange = delta,
                Reason = reason,
                ReferenceId = referenceId,
                PerformedByUserId = byUserId,
                Note = note,
                CreatedAt = DateTime.UtcNow
            });

            await _db.SaveChangesAsync(ct);
            await RecalcProductTotalStockAsync(v.ProductId, ct);

            if (!hasOuterTx && tx is not null)
                await tx.CommitAsync(ct);
        }

        private async Task RecalcProductTotalStockAsync(int productId, CancellationToken ct = default)
        {
            var total = await _db.ProductVariants
                .Where(v => v.ProductId == productId && v.IsActive)
                .SumAsync(v => (int?)v.StockQuantity, ct) ?? 0;

            var p = await _db.Products.FirstOrDefaultAsync(x => x.Id == productId, ct);
            if (p != null)
            {
                p.StockQuantity = total;
                await _db.SaveChangesAsync(ct);
            }
        }

        public async Task<int> GetAvailableVariantAsync(int variantId)
        {
            var v = await _db.ProductVariants.AsNoTracking().FirstOrDefaultAsync(x => x.Id == variantId);
            return v == null ? 0 : (v.StockQuantity - v.ReservedQuantity);
        }


        public async Task<Dictionary<int, int>> GetVariantCartHoldsAsync(int productId, CancellationToken ct = default)
        {
            return await _db.CartItems
                .Where(ci => ci.ProductId == productId && ci.VariantId != null)
                .GroupBy(ci => ci.VariantId!.Value)
                .Select(g => new { VariantId = g.Key, Hold = g.Sum(x => x.Quantity) })
                .ToDictionaryAsync(x => x.VariantId, x => x.Hold, ct);
        }

    }

}
