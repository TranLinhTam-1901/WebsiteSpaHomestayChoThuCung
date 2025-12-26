using DoAnCoSo.DTO.Order;
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Controllers.Api
{
    [ApiController]
    [Route("api/OrderHistory")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
    public class OrderHistoryApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public OrderHistoryApiController(
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        // ✅ TEST API
        [HttpGet("ping")]
        [AllowAnonymous]
        public IActionResult Ping()
        {
            return Ok("OrderHistory API is running");
        }

        // GET api/OrderHistory
        [HttpGet]
        public async Task<IActionResult> GetOrders()
        {
            var currentUser = await _userManager.GetUserAsync(User);
            if (currentUser == null)
                return Unauthorized();

            var orders = await _context.Orders
                .Where(o => o.UserId == currentUser.Id)
                .Include(o => o.OrderDetails)
                    .ThenInclude(od => od.Product)
                .Include(o => o.OrderPromotions)
                    .ThenInclude(op => op.Promotion)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync();

            var result = orders.Select(o => new OrderDto
            {
                Id = o.Id,
                OrderDate = o.OrderDate,
                CustomerName = o.CustomerName ?? "",
                PhoneNumber = o.PhoneNumber ?? "",
                ShippingAddress = o.ShippingAddress ?? "",   // ⭐ thêm
                PaymentMethod = o.PaymentMethod ?? "",       // ⭐ thêm
                Notes = o.Notes ?? "",
                Status = o.Status.ToString(),
                TotalPrice = o.TotalPrice,
                Discount = o.OrderPromotions?.Sum(x => x.DiscountApplied) ?? 0,
                PromoCode = o.OrderPromotions?.FirstOrDefault()?.Promotion?.Code,
                Items = o.OrderDetails.Select(od => new OrderItemDto
                {
                    Name = od.Product.Name,
                    Option = od.VariantName ?? od.SelectedFlavor ?? "",
                    Quantity = od.Quantity,
                    Price = od.Price,
                    DiscountedPrice = od.DiscountedPrice
                }).ToList()
            });

            return Ok(result);
        }

        // POST api/OrderHistory/cancel/5
        [HttpPost("cancel/{id}")]
        public async Task<IActionResult> CancelOrder(int id)
        {
            var currentUser = await _userManager.GetUserAsync(User);
            if (currentUser == null)
                return Unauthorized();

            var order = await _context.Orders.FindAsync(id);
            if (order == null)
                return NotFound();

            if (order.UserId != currentUser.Id)
                return Forbid();

            if (order.Status != OrderStatusEnum.ChoXacNhan)
                return BadRequest("Không thể hủy đơn này");

            order.Status = OrderStatusEnum.DaHuy;
            await _context.SaveChangesAsync();

            return Ok();
        }
    }
}
