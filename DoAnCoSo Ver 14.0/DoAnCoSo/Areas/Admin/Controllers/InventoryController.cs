using DoAnCoSo.Models;
using DoAnCoSo.Services;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory;
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
        public async Task<IActionResult> Index(string? search, int? categoryId, bool showHidden = false)
        {
            ViewBag.OptionLabel = "Tùy chọn";

            // Gửi dữ liệu danh mục sang View
            ViewBag.Categories = await _context.Categories
                .OrderBy(c => c.Name)
                .ToListAsync();

            ViewBag.CategoryId = categoryId;
            ViewBag.ShowHidden = showHidden;

            // ================================
            // ⭐ BƯỚC 1: TẠO QUERY SẢN PHẨM
            // ================================
            var query = _context.Products
                .Include(p => p.Category)
                .Include(p => p.Variants)
                .AsQueryable();

            // ❌ MẶC ĐỊNH KHÔNG HIỂN THỊ SẢN PHẨM ẨN
            if (!showHidden)
            {
                query = query.Where(p => p.IsActive && !p.IsDeleted);
            }

            // ⭐ Nếu có chọn Category → lọc theo danh mục
            if (categoryId.HasValue && categoryId.Value > 0)
            {
                query = query.Where(p => p.CategoryId == categoryId.Value);
            }

            // ⭐ Lấy danh sách rawProduct để tính tồn kho
            var rawProducts = await query
                .Select(p => new
                {
                    Product = p,
                    TotalStock = p.Variants.Any()
                        ? p.Variants.Sum(v => (int?)v.StockQuantity) ?? 0
                        : p.StockQuantity
                })
                .ToListAsync();



            // Nếu có từ khoá → lọc
            if (!string.IsNullOrWhiteSpace(search))
            {
                string keyword = search.ToLower();

            // Nếu nhập số => lọc theo tồn kho thật
            if (int.TryParse(keyword, out int num))
            {
                rawProducts = rawProducts
                    .Where(x => x.TotalStock == num)
                    .ToList();
            }
            else
            {
                // Nếu nhập chữ => lọc theo tên/thương hiệu/category
                rawProducts = rawProducts.Where(x =>
                    x.Product.Name.ToLower().Contains(keyword) ||
                    (x.Product.Trademark != null && x.Product.Trademark.ToLower().Contains(keyword)) ||
                    (x.Product.Category != null && x.Product.Category.Name.ToLower().Contains(keyword))
           
                ).ToList();
            }
                    }

            var products = rawProducts
            .Select(p => new InventoryDashboardViewModel
            {
                ProductId = p.Product.Id,
                ProductName = p.Product.Name,
                StockQuantity = p.TotalStock,

                SoldQuantity = p.Product.Variants.Any()
                    ? p.Product.Variants.Sum(v => (int?)v.SoldQuantity) ?? 0
                    : p.Product.SoldQuantity,

                ReservedQuantity = p.Product.Variants.Any()
                    ? p.Product.Variants.Sum(v => (int?)v.ReservedQuantity) ?? 0
                    : p.Product.ReservedQuantity,

                LowStockThreshold = p.Product.LowStockThreshold,
                VariantCount = p.Product.Variants.Count()
            })
            .OrderByDescending(p => p.ProductId)
            .ToList();


            ViewBag.Search = search;

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
        public async Task<IActionResult> Logs(
            bool showAll = false,
            string? search = null,
            DateTime? fromDate = null,
            DateTime? toDate = null
            )
        {
            ViewBag.ShowAll = showAll;
            ViewBag.Search = search;
            ViewBag.FromDate = fromDate;
            ViewBag.ToDate = toDate;

            var query = _context.InventoryLogs
            .Include(l => l.Product)
            .Include(l => l.Variant)
            .AsQueryable();

            // Nếu KHÔNG bật "Hiện tất cả" → lọc sản phẩm đang hoạt động
            if (!showAll)
            {
                query = query.Where(l =>
                    l.Product != null &&
                    l.Product.IsActive &&
                    !l.Product.IsDeleted
                );
            }

            // ============================
            // LỌC NGÀY (LOCAL → UTC)
            // ============================
            var vnTimeZone = TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time");

            if (fromDate.HasValue)
            {
                // from local: 22/11/2025 00:00 (giờ VN)
                var fromLocal = fromDate.Value.Date;
                var fromUtc = TimeZoneInfo.ConvertTimeToUtc(fromLocal, vnTimeZone);

                query = query.Where(l => l.CreatedAt >= fromUtc);
            }

            if (toDate.HasValue)
            {
                // to local exclusive: 24/11/2025 00:00 (nếu chọn To = 23)
                var toLocalExclusive = toDate.Value.Date.AddDays(1);
                var toUtcExclusive = TimeZoneInfo.ConvertTimeToUtc(toLocalExclusive, vnTimeZone);

                query = query.Where(l => l.CreatedAt < toUtcExclusive);
            }

            // Lấy 200 log mới nhất sau khi đã lọc
            var logs = await query
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

            var userMap = users.ToDictionary(x => x.Id, x => x.Display);
            ViewBag.UserMap = userMap;

            if (!string.IsNullOrWhiteSpace(search))
            {
                string keyword = search.ToLower().Trim();

                logs = logs.Where(l =>
                    // Tên sản phẩm
                    (l.Product != null && l.Product.Name.ToLower().Contains(keyword))

                    // Người thực hiện (FullName, Email hoặc UserName)
                    || (!string.IsNullOrEmpty(l.PerformedByUserId)
                        && userMap.ContainsKey(l.PerformedByUserId)
                        && userMap[l.PerformedByUserId].ToLower().Contains(keyword))

                    // Lý do (tìm theo mã hoặc mô tả tiếng Việt hiển thị)
                    || l.Reason.ToLower().Contains(keyword)
                    || GetReasonDisplay(l.Reason).ToLower().Contains(keyword)

                ).ToList();
            }
            return View(logs);
        }
        private string GetReasonDisplay(string reason)
        {
            return reason switch
            {
                "OrderReserved" => "Giữ hàng cho đơn hàng",
                "OrderUnreserved" => "Bỏ giữ hàng cho đơn hàng",
                "OrderConfirmed" => "Xuất kho cho đơn hàng",
                "OrderCanceledRestock" => "Hoàn kho từ đơn hàng",
                "AdjustStock" => "Điều chỉnh tồn kho",
                "ExportStock" => "Xuất kho",
                "ImportStock" => "Nhập kho",
                "InitialImport" => "Khởi tạo tồn kho ban đầu",
                "ImportStockVariant" => "Nhập kho theo biến thể",
                "ExportStockVariant" => "Xuất kho theo biến thể",
                _ => reason
            };
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

        public async Task<IActionResult> LogDetails(int id)
        {
            var log = await _context.InventoryLogs
                .Include(l => l.Product)
                .Include(l => l.Variant)
                .FirstOrDefaultAsync(l => l.Id == id);

            var user = await _context.Users
             .Where(u => u.Id == log.PerformedByUserId)
             .Select(u => new { u.FullName })
             .FirstOrDefaultAsync();

            ViewBag.ActorName = user?.FullName ?? "Không rõ";

            if (log == null) return NotFound();

            return PartialView("_LogDetailsPartial", log);
        }

    }
}
