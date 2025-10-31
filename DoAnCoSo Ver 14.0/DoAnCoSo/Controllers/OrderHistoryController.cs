using DoAnCoSo.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;


public class OrderHistoryController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;

    public OrderHistoryController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
    {
        _context = context;
        _userManager = userManager;
    }

    public async Task<IActionResult> Index()
    {
        var currentUser = await _userManager.GetUserAsync(User);
        List<Order> orders = new List<Order>();

        if (currentUser != null)
        {
            orders = await _context.Orders
                .Where(o => o.UserId == currentUser.Id)
                .Include(o => o.OrderDetails)
                    .ThenInclude(od => od.Product)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync();
        }
        else
        {
            TempData["InfoMessage"] = "Vui lòng đăng nhập để xem lịch sử đặt hàng của bạn.";
        }

        return View(orders);
    }

    [HttpPost]
    public async Task<IActionResult> CancelOrder(int id)
    {
        var order = await _context.Orders.FirstOrDefaultAsync(o => o.Id == id);
        var currentUser = await _userManager.GetUserAsync(User);

        if (order == null)
        {
            TempData["ErrorMessage"] = "Không tìm thấy đơn hàng này.";
            return RedirectToAction(nameof(Index));
        }

        if (order.UserId != currentUser.Id)
        {
            TempData["ErrorMessage"] = "Bạn không có quyền hủy đơn hàng này.";
            return RedirectToAction(nameof(Index));
        }

        // Kiểm tra điều kiện: Admin chưa xác nhận (trạng thái là "Chờ xác nhận")
        if (order.Status == OrderStatusEnum.ChoXacNhan)
        {
            order.Status = OrderStatusEnum.DaHuy; // Cập nhật trạng thái thành "Đã hủy"
            _context.Update(order);
            await _context.SaveChangesAsync();
            TempData["SuccessMessage"] = "Đơn hàng đã được hủy thành công.";
        }
        else
        {
            TempData["ErrorMessage"] = "Đơn hàng đã được xác nhận hoặc đang trong quá trình xử lý, không thể hủy.";
        }

        return RedirectToAction(nameof(Index));
    }

    // Trong OrderHistoryController.cs
    public async Task<IActionResult> Details(int id)
    {
        var currentUser = await _userManager.GetUserAsync(User);
        if (currentUser == null)
        {
            return NotFound($"Không tìm thấy người dùng với ID '{_userManager.GetUserId(User)}'.");
        }

        var order = await _context.Orders
            .Include(o => o.OrderDetails)
                .ThenInclude(od => od.Product)
                 .Include(o => o.OrderPromotions)              // 🟢 Thêm dòng này: lấy danh sách giảm giá được áp dụng cho đơn này
            .ThenInclude(op => op.Promotion)
            .Where(o => o.Id == id && o.UserId == currentUser.Id) // Chỉ lấy đơn hàng của người dùng hiện tại
            .FirstOrDefaultAsync();

        if (order == null)
        {
            return NotFound("Không tìm thấy đơn hàng bạn yêu cầu hoặc bạn không có quyền truy cập.");
        }

        return View(order);
    }
}