using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DoAnCoSo.Services;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")] 
    [Authorize(Roles = "Admin")] 
    public class OrderController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IInventoryService _inventory;

        public OrderController(ApplicationDbContext context, UserManager<ApplicationUser> userManager, IInventoryService inventory)
        {
            _context = context;
            _userManager = userManager;
            _inventory = inventory;
        }

        // 1. Admin xem toàn bộ lịch sử đặt hàng
        public async Task<IActionResult> Index()
        {

            var orders = await _context.Orders
                .Include(o => o.User) 
            .Include(o => o.OrderDetails)
            .ThenInclude(od => od.Product)
             .ThenInclude(p => p.Variants)
            .Include(o => o.OrderPromotions)
            .ThenInclude(op => op.Promotion) 
        .OrderByDescending(o => o.OrderDate)
        .ToListAsync();
            return View(orders);
        }

        // Chi tiết đơn hàng cho Admin
        public async Task<IActionResult> Details(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var order = await _context.Orders
            .Include(o => o.User)
            .Include(o => o.OrderDetails)
                .ThenInclude(od => od.Product)
                 .ThenInclude(p => p.Variants)
            .Include(o => o.OrderPromotions)             
                .ThenInclude(op => op.Promotion)
            .FirstOrDefaultAsync(m => m.Id == id);

            if (order == null)
            {
                return NotFound();
            }

            return View(order);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Confirm(int id)
        {
            // Lấy order để kiểm tra nhanh trước khi gọi service (tránh exception không cần thiết)
            var order = await _context.Orders
                .AsTracking()
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy đơn hàng.";
                return RedirectToAction(nameof(Index));
            }

            if (order.Status != OrderStatusEnum.ChoXacNhan)
            {
                TempData["ErrorMessage"] = "Đơn hàng không ở trạng thái 'Chờ xác nhận'.";
                return RedirectToAction(nameof(Index));
            }

            try
            {
                // 1) Gọi service: service TỰ lo toàn bộ kho + set DaXacNhan trong 1 transaction
                await _inventory.ConfirmOrderAtomicallyAsync(id, _userManager.GetUserId(User));

                // 2) Đồng bộ thực thể về trạng thái mới nhất sau khi service commit
                await _context.Entry(order).ReloadAsync();

                // 3) Nếu là thanh toán thủ công (COD/Chuyển khoản thủ công) thì cập nhật bankStatus
                if (IsManualPaidMethod(order.PaymentMethod))
                {
                    order.bankStatus = BankStatusEnum.DaThanhToan;
                    // order đang được tracking, chỉ cần SaveChanges
                    await _context.SaveChangesAsync();
                }

                TempData["SuccessMessage"] = "✅ Xác nhận đơn hàng thành công.";
            }
            catch (InvalidOperationException ex)
            {
                // Ví dụ: "Order is not pending." hoặc thiếu tồn kho...
                TempData["ErrorMessage"] = "❌ Xác nhận thất bại: " + ex.Message;
            }
            catch (DbUpdateConcurrencyException)
            {
                TempData["ErrorMessage"] = "❌ Xung đột dữ liệu, vui lòng thử lại.";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "❌ Lỗi không xác định: " + ex.Message;
            }

            return RedirectToAction(nameof(Index));
        }

        // Sau này chuyển sang auto-banking, bạn chỉ cần sửa logic trong hàm này
        private static bool IsManualPaidMethod(string? method)
        {
            if (string.IsNullOrWhiteSpace(method)) return false;

            return method.Equals("COD", StringComparison.OrdinalIgnoreCase)
                || method.Equals("BankTransfer", StringComparison.OrdinalIgnoreCase);
            // TODO (future): khi có webhook banking, bỏ "BankTransfer" khỏi đây.
        }


        // 3. Hủy đơn hàng (dành cho Admin)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Cancel(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy đơn hàng này.";
                return RedirectToAction(nameof(Index));
            }

            try
            {
                // Service tự quyết: nếu đã trừ kho → hoàn kho; nếu chưa → chỉ unreserve; rồi set DaHuy
                await _inventory.CancelOrderAtomicallyAsync(id, _userManager.GetUserId(User));
                TempData["SuccessMessage"] = "✅ Đơn hàng đã hủy đúng quy tắc.";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "Hủy thất bại: " + ex.Message;
            }

            return RedirectToAction(nameof(Index));
        }

        // 4. Xóa đơn hàng    
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            var order = await _context.Orders
                                      .Include(o => o.OrderDetails) // Cần include để xóa chi tiết đơn hàng nếu cần
                                      .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy đơn hàng để xóa.";
                return RedirectToAction(nameof(Index));
            }

            try
            {
                // Xóa các chi tiết đơn hàng trước (nếu có Foreign Key cascade delete thì không cần dòng này)
                _context.OrderDetails.RemoveRange(order.OrderDetails);
                _context.Orders.Remove(order);
                await _context.SaveChangesAsync();
                TempData["SuccessMessage"] = "Đơn hàng đã được xóa thành công.";
            }
            catch (DbUpdateException ex)
            {
                // Xử lý lỗi nếu có ràng buộc khóa ngoại không cho phép xóa
                TempData["ErrorMessage"] = $"Lỗi khi xóa đơn hàng: {ex.Message}. Có thể có các ràng buộc dữ liệu khác.";
                // Log chi tiết ex.InnerException?.Message cho mục đích debug
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Đã xảy ra lỗi không mong muốn khi xóa đơn hàng: {ex.Message}";
            }

            return RedirectToAction(nameof(Index));
        }
    }
}