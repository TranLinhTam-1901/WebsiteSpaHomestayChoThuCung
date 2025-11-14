using DoAnCoSo.Models;
using DoAnCoSo.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

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
                                       .Include(o => o.OrderPromotions)             
                                           .ThenInclude(op => op.Promotion)
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
                // Cập nhật trạng thái đơn hàng
                order.Status = OrderStatusEnum.DaXacNhan;

                // Nếu là COD → xem như đã thanh toán khi admin xác nhận
                if (order.PaymentMethod == "COD")
                {
                    order.bankStatus = BankStatusEnum.DaThanhToan;
                }

                // Nếu là Banking thì không cần đổi vì đã thanh toán tự động trước đó
                _context.Update(order);
                await _context.SaveChangesAsync();

                try
                {
                    await _inventory.DeductForOrderAsync(order.Id,
                    byUserId: _userManager.GetUserId(User));
                    TempData["SuccessMessage"] = "✅ Đơn hàng đã xác nhận và đã trừ kho.";
                }
                catch (Exception ex)
                {
                  
                    TempData["ErrorMessage"] = "Xác nhận thất bại do tồn kho: " + ex.Message;
                }
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
            else if (order.Status == OrderStatusEnum.DaXacNhan || order.bankStatus == BankStatusEnum.DaThanhToan)
            {
                // ✅ Đơn đã xác nhận → hoàn kho thật
                try
                {
                    await _inventory.RestockForOrderAsync(order.Id,
                        byUserId: _userManager.GetUserId(User));
                }
                catch (Exception ex)
                {
                    TempData["ErrorMessage"] = "Không thể hoàn kho: " + ex.Message;
                    return RedirectToAction(nameof(Index));
                }

                order.Status = OrderStatusEnum.DaHuy;
                _context.Update(order);
                await _context.SaveChangesAsync();

                TempData["SuccessMessage"] = "Đơn hàng đã hủy và đã hoàn kho.";
            }
            else if (order.Status == OrderStatusEnum.ChoXacNhan)
            {
                // ✅ Đơn chưa xác nhận → chỉ bỏ giữ hàng tạm
                try
                {
                    await _inventory.UnreserveForOrderAsync(order.Id,
                        byUserId: _userManager.GetUserId(User));
                }
                catch (Exception ex)
                {
                    TempData["ErrorMessage"] = "Không thể bỏ giữ hàng tạm: " + ex.Message;
                    return RedirectToAction(nameof(Index));
                }

                order.Status = OrderStatusEnum.DaHuy;
                _context.Update(order);
                await _context.SaveChangesAsync();

                TempData["SuccessMessage"] = "Đơn hàng đã hủy và đã bỏ giữ hàng tạm.";
            }
            else
            {
                TempData["ErrorMessage"] = "Trạng thái đơn hàng không hợp lệ để hủy.";
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