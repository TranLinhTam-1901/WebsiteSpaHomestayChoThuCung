using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")] // Chỉ thêm dòng này nếu bạn đang sử dụng ASP.NET Core Areas
    [Authorize(Roles = "Admin")] // Yêu cầu người dùng phải có Role "Admin" để truy cập
    public class OrderController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public OrderController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
            _userManager = userManager;
        }

        // 1. Admin xem toàn bộ lịch sử đặt hàng
        public async Task<IActionResult> Index()
        {
            var orders = await _context.Orders
                                       .Include(o => o.User) // Include thông tin người dùng
                                       .Include(o => o.OrderDetails)
                                           .ThenInclude(od => od.Product)
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
                                      .FirstOrDefaultAsync(m => m.Id == id);
            if (order == null)
            {
                return NotFound();
            }

            return View(order);
        }

        // 2. Xác nhận đơn hàng
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Confirm(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy đơn hàng.";
                return RedirectToAction(nameof(Index));
            }

            if (order.Status == OrderStatusEnum.ChoXacNhan)
            {
                order.Status = OrderStatusEnum.DaXacNhan; // Chuyển trạng thái sang "Đã xác nhận"
                _context.Update(order);
                await _context.SaveChangesAsync();
                TempData["SuccessMessage"] = "Đơn hàng đã được xác nhận thành công.";
            }
            else
            {
                TempData["ErrorMessage"] = "Đơn hàng không ở trạng thái 'Chờ xác nhận' để xác nhận.";
            }

            return RedirectToAction(nameof(Index));
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

            if (order.Status == OrderStatusEnum.ChoXacNhan)
            {
                order.Status = OrderStatusEnum.DaHuy;
                _context.Update(order);
                await _context.SaveChangesAsync();

                TempData["SuccessMessage"] = "Đơn hàng đã được hủy thành công.";
            }
            else
            {
                TempData["ErrorMessage"] = "Chỉ có thể hủy đơn hàng ở trạng thái 'Chờ xác nhận'.";
            }

            return RedirectToAction(nameof(Index));
        }

        // 4. Xóa đơn hàng (Hard Delete)
        // CẦN CỰC KỲ CẨN TRỌNG VỚI HÀNH ĐỘNG NÀY!
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