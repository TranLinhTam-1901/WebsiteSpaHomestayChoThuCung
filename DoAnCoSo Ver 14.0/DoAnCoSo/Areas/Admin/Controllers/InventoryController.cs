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
            var products = await _context.Products
            .Select(p => new InventoryDashboardViewModel
            {
                ProductId = p.Id,
                ProductName = p.Name,
                StockQuantity = p.StockQuantity,
                SoldQuantity = p.SoldQuantity,
                ReservedQuantity = p.ReservedQuantity,
                LowStockThreshold = p.LowStockThreshold
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
            var logs = await _context.InventoryLogs
            .Include(l => l.Product)
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


    }
}
