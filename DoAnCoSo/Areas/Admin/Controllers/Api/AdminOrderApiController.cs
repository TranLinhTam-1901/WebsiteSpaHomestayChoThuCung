using DoAnCoSo.Models;
using DoAnCoSo.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Areas.Admin.Controllers.Api
{
    [Area("Admin")]
    [Route("api/admin/Orders")]
    [ApiController]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Roles = "Admin")]
    public class AdminOrderApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IInventoryService _inventory;

        public AdminOrderApiController(ApplicationDbContext context, UserManager<ApplicationUser> userManager, IInventoryService inventory)
        {
            _context = context;
            _userManager = userManager;
            _inventory = inventory;
        }

        // 1. Lấy danh sách toàn bộ đơn hàng
        [HttpGet]
        public async Task<IActionResult> GetOrders()
        {
            var orders = await _context.Orders
                .Include(o => o.User)
                .Include(o => o.OrderDetails)
                .OrderByDescending(o => o.OrderDate)
                .AsNoTracking()
                .Select(o => new {
                    o.Id,
                    o.OrderDate,
                    o.TotalPrice,
                    Status = o.Status.ToString(),
                    BankStatus = o.bankStatus.ToString(),

                    // --- THÔNG TIN NGƯỜI ĐẶT (NGƯỜI GỬI) ---
                    // Lấy từ bảng User đã link với đơn hàng
                    SenderName = o.User != null ? o.User.FullName : "Khách vãng lai",
                    SenderPhone = o.User != null ? o.User.PhoneNumber : "N/A",
                    SenderEmail = o.User != null ? o.User.Email : "N/A",

                    // --- THÔNG TIN NGƯỜI NHẬN (Tại địa chỉ giao) ---
                    CustomerName = o.CustomerName,
                    PhoneNumber = o.PhoneNumber,
                    ShippingAddress = o.ShippingAddress,

                    o.PaymentMethod,
                    o.Notes,
                    ItemCount = o.OrderDetails.Count
                })
                .ToListAsync();

            return Ok(orders);
        }

        // 2. Chi tiết đơn hàng
        [HttpGet("{id}")]
        public async Task<IActionResult> GetDetails(int id)
        {
            var order = await _context.Orders
                .Include(o => o.User)
                .Include(o => o.OrderDetails)
                    .ThenInclude(od => od.Product)
                .Include(o => o.OrderPromotions)
                    .ThenInclude(op => op.Promotion)
                .FirstOrDefaultAsync(m => m.Id == id);

            if (order == null)
            {
                return NotFound(new { message = "Không tìm thấy đơn hàng." });
            }

            // TÍNH TOÁN GIÁ TRỊ (Dựa trên OrderDetails để chính xác tuyệt đối)
            // Giá gốc = Tổng (Số lượng * Giá niêm yết của từng món)
            var originalPrice = order.OrderDetails.Sum(od => od.Quantity * od.Price);

            // Giảm giá = Giá gốc - Thành tiền thực tế
            var discount = originalPrice - order.TotalPrice;

            return Ok(new
            {
                // --- THÔNG TIN ĐƠN HÀNG ---
                order.Id,
                order.OrderDate,
                OriginalPrice = originalPrice, // Giá gốc (Dòng đầu tiên trong hình)
                Discount = discount,           // Giảm giá (Dòng trừ tiền)
                order.TotalPrice,              // Thành tiền (Dòng màu xanh)
                Status = order.Status.ToString(),
                BankStatus = order.bankStatus.ToString(),

                // --- THÔNG TIN NGƯỜI ĐẶT (Người gửi/Người đặt) ---
                Customer = new
                {
                    // Hiển thị ở dòng "Người đặt"
                    FullName = order.User?.FullName ?? order.CustomerName,
                    Email = order.User?.Email ?? ""
                },

                // --- THÔNG TIN GIAO HÀNG (Người nhận) ---
                // Đảm bảo truyền các trường này để UI không hiện "Chưa cung cấp"
                order.CustomerName,    // Người nhận
                order.PhoneNumber,     // Số điện thoại
                order.ShippingAddress, // Địa chỉ giao hàng
                order.PaymentMethod,   // Phương thức thanh toán (COD/Bank)
                order.Notes,           // Ghi chú (Ví dụ: "okie", "alo")

                // --- CHI TIẾT SẢN PHẨM ---
                Details = order.OrderDetails.Select(od => new {
                    od.ProductId,
                    ProductName = od.Product != null ? od.Product.Name : "Sản phẩm không xác định",
                    od.Quantity,
                    od.Price,
                    // Ưu tiên VariantName, nếu trống thì dùng SelectedFlavor cho "Phân loại"
                    VariantName = !string.IsNullOrEmpty(od.VariantName) ? od.VariantName : od.SelectedFlavor
                }),

                // --- DANH SÁCH KHUYẾN MÃI ---
                Promotions = order.OrderPromotions?.Select(op => new {
                    op.PromotionId,
                    // Thay 'Title' bằng 'Name' nếu Model Promotion của bạn dùng 'Name'
                    PromotionName = op.Promotion != null ? op.Promotion.Title : "Khuyến mãi"
                })
            });
        }

        // 3. Xác nhận đơn hàng
        [HttpPost("confirm/{id}")]
        public async Task<IActionResult> Confirm(int id)
        {
            var order = await _context.Orders.FirstOrDefaultAsync(o => o.Id == id);
            if (order == null) return NotFound(new { message = "Không tìm thấy đơn hàng." });

            if (order.Status != OrderStatusEnum.ChoXacNhan)
                return BadRequest(new { message = "Đơn hàng không ở trạng thái 'Chờ xác nhận'." });

            try
            {
                var userId = _userManager.GetUserId(User);
                await _inventory.ConfirmOrderAtomicallyAsync(id, userId);

                await _context.Entry(order).ReloadAsync();

                if (IsManualPaidMethod(order.PaymentMethod))
                {
                    order.bankStatus = BankStatusEnum.DaThanhToan;
                    await _context.SaveChangesAsync();
                }

                return Ok(new { message = "Xác nhận đơn hàng thành công.", status = order.Status.ToString() });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        // 4. Hủy đơn hàng
        [HttpPost("cancel/{id}")]
        public async Task<IActionResult> Cancel(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound(new { message = "Không tìm thấy đơn hàng." });

            try
            {
                var userId = _userManager.GetUserId(User);
                await _inventory.CancelOrderAtomicallyAsync(id, userId);
                return Ok(new { message = "Đơn hàng đã được hủy thành công." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        private static bool IsManualPaidMethod(string? method)
        {
            if (string.IsNullOrWhiteSpace(method)) return false;
            return method.Equals("COD", StringComparison.OrdinalIgnoreCase)
                || method.Equals("BankTransfer", StringComparison.OrdinalIgnoreCase);
        }
    }
}