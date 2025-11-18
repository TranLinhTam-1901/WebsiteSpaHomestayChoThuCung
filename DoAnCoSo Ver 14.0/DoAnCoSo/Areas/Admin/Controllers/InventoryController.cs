using DoAnCoSo.Models;
using DoAnCoSo.Services;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin")]
    public class InventoryController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public InventoryController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        // Dashboard - Tồn kho
        public async Task<IActionResult> Index()
        {
            ViewBag.OptionLabel = "Tùy chọn";

            var products = await _context.Products
                .Select(p => new InventoryDashboardViewModel
                {
                    ProductId = p.Id,
                    ProductName = p.Name,

                    // Tổng hợp theo biến thể nếu có
                    StockQuantity = p.Variants.Any()
                        ? p.Variants.Sum(v => (int?)v.StockQuantity) ?? 0
                        : p.StockQuantity,

                    SoldQuantity = p.Variants.Any()
                        ? p.Variants.Sum(v => (int?)v.SoldQuantity) ?? 0
                        : p.SoldQuantity,

                    // ✅ Giữ tạm (đơn) tổng theo biến thể
                    ReservedQuantity = p.Variants.Any()
                        ? p.Variants.Sum(v => (int?)v.ReservedQuantity) ?? 0
                        : p.ReservedQuantity,

                    LowStockThreshold = p.LowStockThreshold,
                    VariantCount = p.Variants.Count()
                })
                .OrderBy(p => p.ProductName)
                .ToListAsync();

            return View(products);
        }

        // Nhập kho (Import)       
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ImportStock(int productId, int quantity, string? note, 
            [FromServices] IInventoryService inventory)
        {
            if (quantity <= 0)
            {
                TempData["ErrorMessage"] = "Số lượng nhập phải lớn hơn 0.";
                return RedirectToAction(nameof(Index));
            }

            var product = await _context.Products.FindAsync(productId);
            if (product == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy sản phẩm.";
                return RedirectToAction(nameof(Index));
            }

            var refId = Guid.NewGuid().ToString();
            //var byUser = User.Identity?.Name
            //             ?? User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
            //             ?? "System"; 
            var byUser = _userManager.GetUserId(User) ?? "System";
            // Sử dụng AdjustStockAsync từ InventoryService
            await inventory.AdjustStockAsync(productId, quantity, "ImportStock", refId, byUser, note: note);

            TempData["SuccessMessage"] = $"Đã nhập thêm {quantity} sản phẩm '{product.Name}'.";
            return RedirectToAction(nameof(Index));
        }

        //Xuất kho / Điều chỉnh (Export)      
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ExportStock(int productId, int quantity, string? note,
            [FromServices] IInventoryService inventory)
        {
            if (quantity <= 0)
            {
                TempData["ErrorMessage"] = "Số lượng xuất phải lớn hơn 0.";
                return RedirectToAction(nameof(Index));
            }


            var product = await _context.Products.FindAsync(productId);
            if (product == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy sản phẩm.";
                return RedirectToAction(nameof(Index));
            }


            if (product.StockQuantity < quantity)
            {
                TempData["ErrorMessage"] = $"Không đủ tồn kho để xuất ({product.StockQuantity} cái còn lại).";
                return RedirectToAction(nameof(Index));
            }

            var refId = Guid.NewGuid().ToString();
            var byUser = _userManager.GetUserId(User) ?? "System"; 
            await inventory.AdjustStockAsync(productId, -quantity, "ExportStock", refId, byUser, note: note);

            

            TempData["SuccessMessage"] = $"Đã xuất {quantity} sản phẩm '{product.Name}'.";
            return RedirectToAction(nameof(Index));
        }

        //Lịch sử giao dịch kho
        public async Task<IActionResult> Logs()
        {
            //ViewBag.OptionLabel = "Tùy chọn";
            var logs = await _context.InventoryLogs
            .Include(l => l.Product)
            .Include(l => l.Variant)
            .OrderByDescending(l => l.CreatedAt)
            .Take(200)
            .ToListAsync();

            var userIds = logs.Where(l => !string.IsNullOrEmpty(l.PerformedByUserId))
                     .Select(l => l.PerformedByUserId)
                     .Distinct()
                     .ToList();

            var users = await _context.Users
                   .Where(u => userIds.Contains(u.Id))
                   .Select(u => new { u.Id, Display = u.FullName ?? u.Email ?? u.UserName })
                   .ToListAsync();
            ViewBag.UserMap = users.ToDictionary(x => x.Id, x => x.Display);
            return View(logs);
        }

        // Xem danh sách biến thể của 1 sản phẩm
        [HttpGet]
        public async Task<IActionResult> Variants(int productId,
            [FromServices] IInventoryService inventory)
        {
            ViewBag.OptionLabel = "Tùy chọn";

            var product = await _context.Products
                .Include(p => p.Variants)
                .FirstOrDefaultAsync(p => p.Id == productId);

            if (product == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy sản phẩm.";
                return RedirectToAction(nameof(Index));
            }

            // lấy giữ tạm (hold) theo VariantId từ giỏ hàng
            var holds = await inventory.GetVariantCartHoldsAsync(product.Id);
            ViewBag.Holds = holds; // Dictionary<int variantId, int holdQty>

            // (Giữ nguyên VM bạn đang dùng)
            var vm = new InventoryVariantListViewModel
            {
                ProductId = product.Id,
                ProductName = product.Name,
                Variants = product.Variants
                    .OrderBy(v => v.Name)
                    .Select(v => new InventoryVariantRowViewModel
                    {
                        VariantId = v.Id,
                        VariantName = v.Name,
                        StockQuantity = v.StockQuantity,
                        ReservedQuantity = v.ReservedQuantity,
                        SoldQuantity = v.SoldQuantity,
                        LowStockThreshold = v.LowStockThreshold
                        // Không chạm cấu trúc VM để tránh sửa lan — hold sẽ đọc từ ViewBag
                    })
                    .ToList()
            };

            return View(vm);
        }

        // Nhập theo biến thể
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ImportVariant(int variantId, int quantity, string? note,
            [FromServices] IInventoryService inventory)
        {
            if (quantity <= 0)
            {
                TempData["ErrorMessage"] = "Số lượng nhập phải lớn hơn 0.";
                return Redirect(Request.Headers["Referer"].ToString());
            }

            var v = await _context.ProductVariants.Include(x => x.Product).FirstOrDefaultAsync(x => x.Id == variantId);
            if (v == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy biến thể.";
                return Redirect(Request.Headers["Referer"].ToString());
            }

            var refId = Guid.NewGuid().ToString();
            var byUser = _userManager.GetUserId(User) ?? "System";

            await inventory.AdjustStockVariantAsync(variantId, quantity, "ImportStockVariant", refId, byUser, note);
            TempData["SuccessMessage"] = $"Đã nhập +{quantity} cho biến thể '{v.Name}' ({v.Product.Name}).";

            return RedirectToAction(nameof(Variants), new { productId = v.ProductId });
        }

        // Xuất theo biến thể
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ExportVariant(int variantId, int quantity, string? note,
            [FromServices] IInventoryService inventory)
        {
            if (quantity <= 0)
            {
                TempData["ErrorMessage"] = "Số lượng xuất phải lớn hơn 0.";
                return Redirect(Request.Headers["Referer"].ToString());
            }

            var v = await _context.ProductVariants.Include(x => x.Product).FirstOrDefaultAsync(x => x.Id == variantId);
            if (v == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy biến thể.";
                return Redirect(Request.Headers["Referer"].ToString());
            }

            var available = v.StockQuantity; // Admin xuất kho: kiểm tồn thật
            if (available < quantity)
            {
                TempData["ErrorMessage"] = $"Không đủ tồn cho biến thể '{v.Name}'. Còn {available}.";
                return RedirectToAction(nameof(Variants), new { productId = v.ProductId });
            }

            var refId = Guid.NewGuid().ToString();
            var byUser = _userManager.GetUserId(User) ?? "System";

            await inventory.AdjustStockVariantAsync(variantId, -quantity, "ExportStockVariant", refId, byUser, note);
            TempData["SuccessMessage"] = $"Đã xuất -{quantity} cho biến thể '{v.Name}' ({v.Product.Name}).";

            return RedirectToAction(nameof(Variants), new { productId = v.ProductId });
        }

    }
}
