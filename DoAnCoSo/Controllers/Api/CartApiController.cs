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
    [Route("api/cart")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
    public class CartApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IInventoryService _inventory;

        public CartApiController(
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager,
            IInventoryService inventory)
        {
            _context = context;
            _userManager = userManager;
            _inventory = inventory;
        }
        [HttpGet]
        public async Task<IActionResult> GetCart()
        {
            var userId = _userManager.GetUserId(User);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var cartItems = await _context.CartItems
                .Where(ci => ci.UserId == userId)
                .Include(ci => ci.Product)
                    .ThenInclude(p => p.Variants)
                .OrderByDescending(ci => ci.DateCreated)
                .ToListAsync();

            var resultItems = new List<object>();

            int totalQty = 0;
            decimal totalAmount = 0;

            foreach (var ci in cartItems)
            {
                ProductVariant? variant = null;
                int available;
                decimal price;

                if (ci.VariantId.HasValue)
                {
                    variant = ci.Product.Variants
                        .FirstOrDefault(v => v.Id == ci.VariantId && v.IsActive);

                    if (variant == null)
                        continue; // biến thể bị xóa → bỏ item

                    available = Math.Max(0, variant.StockQuantity - variant.ReservedQuantity);
                    price = variant.PriceOverride ?? ci.Product.Price;
                }
                else
                {
                    available = await _inventory.GetAvailableAsync(ci.ProductId);
                    price = ci.Product.Price;
                }

                bool isOutOfStock = available <= 0;

                var subtotal = price * ci.Quantity;

                totalQty += ci.Quantity;
                totalAmount += subtotal;

                resultItems.Add(new
                {
                    cartItemId = ci.Id,

                    productId = ci.ProductId,
                    productName = ci.Product.Name,
                    imageUrl = ci.Product.ImageUrl,

                    variantId = ci.VariantId,
                    variantName = ci.SelectedVariantName ?? "Mặc định",

                    price,
                    quantity = ci.Quantity,
                    stockAvailable = available,
                    isOutOfStock,

                    subtotal
                });
            }

            return Ok(new
            {
                items = resultItems,
                totalQuantity = totalQty,
                totalAmount
            });
        }


        [HttpPost("add")]
        public async Task<IActionResult> AddToCart([FromBody] AddToCartRequest req)
        {
            var userId = _userManager.GetUserId(User);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var product = await _context.Products
                .Include(p => p.Variants)
                .FirstOrDefaultAsync(p => p.Id == req.ProductId);

            if (product == null || product.IsDeleted || !product.IsActive)
                return BadRequest("Sản phẩm không hợp lệ.");

            if (product.Variants.Any() && !req.VariantId.HasValue)
            {
                return BadRequest("Vui lòng chọn phân loại sản phẩm.");
            }

            bool hasVariant = req.VariantId.HasValue && req.VariantId > 0;
            int available;

            ProductVariant? variant = null;

            if (hasVariant)
            {
                variant = product.Variants
                    .FirstOrDefault(v => v.Id == req.VariantId && v.IsActive);

                if (variant == null)
                    return BadRequest("Biến thể không hợp lệ.");

                available = Math.Max(0, variant.StockQuantity - variant.ReservedQuantity);
            }
            else
            {
                available = await _inventory.GetAvailableAsync(product.Id);
            }

            int addQty = req.Quantity <= 0 ? 1 : req.Quantity;

            var existingQty = await _context.CartItems
                .Where(ci =>
                    ci.UserId == userId &&
                    ci.ProductId == product.Id &&
                    ci.VariantId == (hasVariant ? req.VariantId : null))
                .Select(ci => ci.Quantity)
                .FirstOrDefaultAsync();

            //if (addQty + existingQty > available)
            //    return BadRequest($"Chỉ còn {available} sản phẩm trong kho.");

            var cartItem = await _context.CartItems.FirstOrDefaultAsync(ci =>
                ci.UserId == userId &&
                ci.ProductId == product.Id &&
                ci.VariantId == (hasVariant ? req.VariantId : null));

            if (cartItem != null)
            {
                cartItem.Quantity += addQty;
            }
            else
            {
                _context.CartItems.Add(new CartItem
                {
                    UserId = userId,
                    ProductId = product.Id,
                    VariantId = hasVariant ? req.VariantId : null,
                    SelectedVariantName = variant?.Name,
                    Quantity = addQty,
                    DateCreated = DateTime.UtcNow
                });
            }

            await _context.SaveChangesAsync();

            int cartCount = await _context.CartItems
                .Where(ci => ci.UserId == userId)
                .SumAsync(ci => ci.Quantity);

            return Ok(new AddToCartResponse
            {
                Success = true,
                Message = "Đã thêm vào giỏ hàng",
                CartItemCount = cartCount
            });
        }

        [HttpPut("update")]
        public async Task<IActionResult> UpdateCartItem([FromBody] UpdateCartItemRequest req)
        {
            var userId = _userManager.GetUserId(User);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            if (req.Quantity <= 0)
                return BadRequest("Số lượng không hợp lệ.");

            var cartItem = await _context.CartItems
                .Include(ci => ci.Product)
                    .ThenInclude(p => p.Variants)
                .FirstOrDefaultAsync(ci =>
                    ci.Id == req.CartItemId &&
                    ci.UserId == userId);

            if (cartItem == null)
                return NotFound("Không tìm thấy sản phẩm trong giỏ.");

            int available;

            if (cartItem.VariantId.HasValue)
            {
                var variant = cartItem.Product.Variants
                    .FirstOrDefault(v => v.Id == cartItem.VariantId && v.IsActive);

                if (variant == null)
                    return BadRequest("Biến thể không hợp lệ.");

                available = Math.Max(0, variant.StockQuantity - variant.ReservedQuantity);
            }
            else
            {
                available = await _inventory.GetAvailableAsync(cartItem.ProductId);
            }

            //if (req.Quantity > available)
            //    return BadRequest($"Chỉ còn {available} sản phẩm trong kho.");

            cartItem.Quantity = req.Quantity;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Success = true,
                Message = "Cập nhật giỏ hàng thành công"
            });
        }

        [HttpDelete("remove/{cartItemId}")]
        public async Task<IActionResult> RemoveCartItem(int cartItemId)
        {
            var userId = _userManager.GetUserId(User);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var cartItem = await _context.CartItems
                .FirstOrDefaultAsync(ci =>
                    ci.Id == cartItemId &&
                    ci.UserId == userId);

            if (cartItem == null)
                return NotFound("Không tìm thấy sản phẩm trong giỏ.");

            _context.CartItems.Remove(cartItem);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Success = true,
                Message = "Đã xóa sản phẩm khỏi giỏ hàng"
            });
        }
        [HttpPost("buynow")]
        public async Task<IActionResult> BuyNow([FromBody] BuyNowRequestDto req)
        {
            if (req.Quantity <= 0)
                req.Quantity = 1;

            var product = await _context.Products
                .Include(p => p.Variants)
                .FirstOrDefaultAsync(p => p.Id == req.ProductId);

            if (product == null)
                return NotFound(new { message = "Sản phẩm không tồn tại." });

            if (product.IsDeleted || !product.IsActive)
                return BadRequest(new { message = "Sản phẩm đã ngừng kinh doanh." });


            if (product.Variants.Any() && !req.VariantId.HasValue)
            {
                return BadRequest(new
                {
                    message = "Vui lòng chọn phân loại sản phẩm."
                });
            }

            if (req.VariantId != null)
            {
                var v = product.Variants
                    ?.FirstOrDefault(x => x.Id == req.VariantId.Value);

                if (v == null)
                    return BadRequest(new { message = "Biến thể không hợp lệ." });

                //var available = Math.Max(0, v.StockQuantity - v.ReservedQuantity);
                //if (req.Quantity > available)
                //    return BadRequest(new
                //    {
                //        message = $"Biến thể '{v.Name}' chỉ còn {available} sản phẩm."
                //    });
            }
            //else
            //{
            //    var available = await _inventory.GetAvailableAsync(req.ProductId);
            //    if (req.Quantity > available)
            //        return BadRequest(new
            //        {
            //            message = $"Sản phẩm chỉ còn {available} sản phẩm."
            //        });
            //}

            // ✅ OK → trả dữ liệu cho app đi checkout
            return Ok(new BuyNowResponseDto
            {
                Success = true,
                ProductId = req.ProductId,
                Quantity = req.Quantity,
                VariantId = req.VariantId,
                BuyNowFlavor = req.BuyNowFlavor
            });
        }
    }
}
