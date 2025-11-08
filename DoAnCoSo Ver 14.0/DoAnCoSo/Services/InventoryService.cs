using DoAnCoSo.Models;
using Microsoft.EntityFrameworkCore;
namespace DoAnCoSo.Services
{
    public interface IInventoryService
    {
        Task AdjustStockAsync(int productId, int delta, string reason = "Manual",
                              string? referenceId = null, string? byUserId = null, CancellationToken ct = default);

        Task<bool> DeductForOrderAsync(int orderId, string? byUserId = null, CancellationToken ct = default);

        Task<bool> RestockForOrderAsync(int orderId, string? byUserId = null, CancellationToken ct = default);
        Task<int> GetAvailableAsync(int productId);

        Task ReserveForOrderAsync(int orderId, string byUserId);

        Task UnreserveForOrderAsync(int orderId, string byUserId);
    }
    public class InventoryService : IInventoryService
    {
        private readonly ApplicationDbContext _db;
        public InventoryService(ApplicationDbContext db) => _db = db;

        public async Task AdjustStockAsync(int productId, int delta, string reason = "Manual",
                                           string? referenceId = null, string? byUserId = null, CancellationToken ct = default)
        {
            await using var tx = await _db.Database.BeginTransactionAsync(ct);

            var p = await _db.Products.FirstOrDefaultAsync(x => x.Id == productId, ct)
                    ?? throw new InvalidOperationException("Không tìm thấy sản phẩm.");

            checked
            {
                p.StockQuantity += delta;          // + nhập, - xuất
                if (delta < 0) p.SoldQuantity += Math.Abs(delta);
            }

            _db.InventoryLogs.Add(new InventoryLog
            {
                ProductId = productId,
                QuantityChange = delta,
                Reason = reason,                   // Manual | OrderConfirmed | OrderCanceled
                ReferenceId = referenceId,         // vd: orderId
                PerformedByUserId = byUserId,
                CreatedAt = DateTime.UtcNow
            });

            await _db.SaveChangesAsync(ct);
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
            var p = await _db.Products
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == productId);

            return p?.StockQuantity ?? 0;
        }

        public async Task ReserveForOrderAsync(int orderId, string byUserId)
        {
            await using var tx = await _db.Database.BeginTransactionAsync();

            var order = await _db.Orders
                .Include(o => o.OrderDetails)
                .ThenInclude(d => d.Product)
                .FirstOrDefaultAsync(o => o.Id == orderId);

            if (order == null)
                throw new Exception("Không tìm thấy đơn hàng để giữ hàng.");

            foreach (var detail in order.OrderDetails)
            {
                var product = detail.Product;
                if (product == null)
                    throw new Exception($"Không tìm thấy sản phẩm ID {detail.ProductId}.");

                var available = product.StockQuantity - product.ReservedQuantity;
                if (available < detail.Quantity)
                    throw new Exception($"Không đủ hàng cho sản phẩm '{product.Name}' (còn {available}).");

                // ✅ Giữ tạm hàng
                product.ReservedQuantity += detail.Quantity;

                // ✅ Ghi log giữ hàng
                _db.InventoryLogs.Add(new InventoryLog
                {
                    ProductId = product.Id,
                    QuantityChange = -detail.Quantity,
                    Reason = "OrderReserved",
                    ReferenceId = order.Id.ToString(),
                    PerformedByUserId = byUserId,
                    CreatedAt = DateTime.UtcNow
                });
            }

            await _db.SaveChangesAsync();
            await tx.CommitAsync();
        }

        public async Task UnreserveForOrderAsync(int orderId, string byUserId)
        {
            await using var tx = await _db.Database.BeginTransactionAsync();

            var order = await _db.Orders
                .Include(o => o.OrderDetails)
                .ThenInclude(d => d.Product)
                .FirstOrDefaultAsync(o => o.Id == orderId);

            if (order == null)
                throw new Exception("Không tìm thấy đơn hàng để bỏ giữ hàng.");

            foreach (var detail in order.OrderDetails)
            {
                var product = detail.Product;
                if (product == null)
                    throw new Exception($"Không tìm thấy sản phẩm ID {detail.ProductId}.");

                if (product.ReservedQuantity < detail.Quantity)
                    throw new Exception($"Số lượng giữ tạm không đủ để hoàn cho {product.Name}.");

                product.ReservedQuantity -= detail.Quantity;

                _db.InventoryLogs.Add(new InventoryLog
                {
                    ProductId = product.Id,
                    QuantityChange = +detail.Quantity,
                    Reason = "OrderUnreserved",
                    ReferenceId = order.Id.ToString(),
                    PerformedByUserId = byUserId,
                    CreatedAt = DateTime.UtcNow
                });
            }

            await _db.SaveChangesAsync();
            await tx.CommitAsync();
        }


    }

}
