using DoAnCoSo.DTO.Product;
using DoAnCoSo.Models;
using DoAnCoSo.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Controllers.Api
{
    [ApiController]
    [Route("api/checkout")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]

    public class CheckoutApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IInventoryService _inventory;

        public CheckoutApiController(
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager,
            IInventoryService inventory)
        {
            _context = context;
            _userManager = userManager;
            _inventory = inventory;
        }

        // ============================================
        // POST /api/checkout
        // ============================================
        [HttpPost]
        public async Task<IActionResult> Checkout([FromBody] CheckoutRequestDto dto)
        {
            var user = await _userManager.GetUserAsync(User);
            if (user == null)
                return Unauthorized();

            var userId = user.Id;
            var itemsForOrder = new List<CartItem>();

            // =========================
            // 1️⃣ LẤY SẢN PHẨM
            // =========================
            if (dto.IsBuyNowCheckout)
            {
                if (!dto.BuyNowProductId.HasValue || !dto.BuyNowQuantity.HasValue || dto.BuyNowQuantity <= 0)
                    return BadRequest(new { message = "Dữ liệu BuyNow không hợp lệ." });

                var product = await _context.Products.FindAsync(dto.BuyNowProductId.Value);
                if (product == null)
                    return BadRequest(new { message = "Không tìm thấy sản phẩm." });


                bool hasVariants = await _context.ProductVariants
                    .AnyAsync(v => v.ProductId == product.Id);

                if (hasVariants && !dto.BuyNowVariantId.HasValue)
                {
                    return BadRequest(new
                    {
                        message = "Sản phẩm này có biến thể, vui lòng chọn biến thể."
                    });
                }

                string? variantName = null;
                if (dto.BuyNowVariantId.HasValue)
                {
                    var v = await _context.ProductVariants.FindAsync(dto.BuyNowVariantId.Value);
                    variantName = v?.Name;
                }

                itemsForOrder.Add(new CartItem
                {
                    ProductId = product.Id,
                    Product = product,
                    Quantity = dto.BuyNowQuantity.Value,
                    VariantId = dto.BuyNowVariantId,
                    SelectedVariantName = variantName,
                    SelectedFlavor = dto.BuyNowFlavor ?? ""
                });
            }
            else
            {
                if (dto.SelectedCartItemIds == null || !dto.SelectedCartItemIds.Any())
                    return BadRequest(new { message = "Vui lòng chọn sản phẩm để thanh toán." });

                itemsForOrder = await _context.CartItems
                    .Where(ci => dto.SelectedCartItemIds.Contains(ci.Id) && ci.UserId == userId)
                    .Include(ci => ci.Product)
                    .ToListAsync();

                if (!itemsForOrder.Any())
                    return BadRequest(new { message = "Không có sản phẩm hợp lệ trong giỏ hàng." });
            }

            // =========================
            // 2️⃣ KIỂM TRA SẢN PHẨM
            // =========================
            foreach (var item in itemsForOrder)
            {
                if (item.Product == null || item.Product.IsDeleted || !item.Product.IsActive)
                {
                    return BadRequest(new
                    {
                        message = $"Sản phẩm '{item.Product?.Name ?? item.ProductId.ToString()}' đã ngừng bán."
                    });
                }
            }

            // =========================
            // 3️⃣ KIỂM TỒN KHO
            //// =========================
            //foreach (var item in itemsForOrder)
            //{
            //    int available;
            //    if (item.VariantId.HasValue)
            //    {
            //        var v = await _context.ProductVariants.FindAsync(item.VariantId.Value);
            //        available = v == null ? 0 : Math.Max(0, v.StockQuantity - v.ReservedQuantity);
            //    }
            //    else
            //    {
            //        available = await _inventory.GetAvailableAsync(item.ProductId);
            //    }

            //    if (item.Quantity > available)
            //    {
            //        return BadRequest(new
            //        {
            //            message = $"Sản phẩm '{item.Product.Name}' chỉ còn {available} cái."
            //        });
            //    }
            //}

            // =========================
            // 4️⃣ TẠO ORDER
            // =========================
            var order = new Order
            {
                UserId = userId,
                CustomerName = user.FullName ?? user.UserName ?? "Khách hàng",
                PhoneNumber = user.PhoneNumber ?? "0000000000",
                OrderDate = DateTime.UtcNow,
                Status = OrderStatusEnum.ChoXacNhan,
                PaymentMethod = dto.PaymentMethod,
                Notes = dto.Notes,
                OrderDetails = new List<OrderDetail>()
            };

            decimal total = 0;

            foreach (var item in itemsForOrder)
            {
                var basePrice = item.Product!.PriceReduced.HasValue && item.Product.PriceReduced > 0
                    ? item.Product.PriceReduced.Value
                    : item.Product.Price;

                var detail = new OrderDetail
                {
                    ProductId = item.ProductId,
                    Quantity = item.Quantity,
                    VariantId = item.VariantId,
                    VariantName = item.SelectedVariantName,
                    SelectedFlavor = item.SelectedFlavor,
                    OriginalPrice = basePrice,
                    DiscountedPrice = basePrice,
                    Price = basePrice
                };

                order.OrderDetails.Add(detail);
                total += basePrice * item.Quantity;
            }

            order.TotalPrice = total;
            _context.Orders.Add(order);

            // =========================
            // 5️⃣ ÁP KHUYẾN MÃI (ĐẠI TRÀ)
            // =========================
            if (!string.IsNullOrWhiteSpace(dto.PromoCode))
            {
                var code = dto.PromoCode.Trim().ToUpper();

                var promo = await _context.Promotions.FirstOrDefaultAsync(p =>
                    p.Code.ToUpper() == code &&
                    p.IsActive &&
                    p.StartDate <= DateTime.Now &&
                    p.EndDate >= DateTime.Now);

                if (promo == null)
                    return BadRequest(new { message = "Mã khuyến mãi không hợp lệ." });

                if (promo.MaxUsagePerUser.HasValue)
                {
                    int userUsedCount = await _context.OrderPromotions
                        .CountAsync(op =>
                            op.PromotionId == promo.Id &&
                            op.Order.UserId == userId);

                    if (userUsedCount >= promo.MaxUsagePerUser.Value)
                    {
                        return BadRequest(new
                        {
                            message = "Bạn đã sử dụng mã khuyến mãi này tối đa số lần cho phép."
                        });
                    }
                }
                if (promo.MinOrderValue.HasValue && total < promo.MinOrderValue.Value)
                    return BadRequest(new
                    {
                        message = $"Đơn hàng chưa đạt {promo.MinOrderValue:N0}đ để áp mã."
                    });

                decimal discountAmount = promo.IsPercent
                    ? total * (promo.Discount / 100)
                    : promo.Discount;

                if (discountAmount > total)
                    discountAmount = total;

                order.TotalPrice = total - discountAmount;

                foreach (var d in order.OrderDetails)
                {
                    var ratio = (d.OriginalPrice * d.Quantity) / total;
                    var lineDiscount = discountAmount * ratio;
                    var perUnit = lineDiscount / d.Quantity;

                    d.DiscountedPrice = Math.Round(d.OriginalPrice - perUnit, 2);
                    d.Price = d.DiscountedPrice;
                }

                _context.OrderPromotions.Add(new OrderPromotion
                {
                    PromotionId = promo.Id,
                    Order = order,
                    CodeUsed = promo.Code,
                    DiscountApplied = discountAmount,
                    UsedAt = DateTime.Now
                });
            }

            // =========================
            // 6️⃣ SAVE + GIỮ HÀNG
            // =========================

            if (!dto.IsBuyNowCheckout)
            {
                _context.CartItems.RemoveRange(itemsForOrder);
            }

            await _context.SaveChangesAsync();
            //await _inventory.ReserveForOrderAsync(order.Id, userId);

            return Ok(new
            {
                message = "Đặt hàng thành công",
                orderId = order.Id,
                total = order.TotalPrice
            });
        }
    
}
}
