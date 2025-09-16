using Azure.Core;
using DoAnCoSo.Extensions;
using DoAnCoSo.Models;
using DoAnCoSo.Repositories;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System; // Thêm using này cho DateTime


namespace DoAnCoSo.Controllers
{
    //[Authorize] // Nếu bạn muốn yêu cầu đăng nhập cho toàn bộ Controller
    public class ShoppingCartController : Controller
    {
        private readonly IProductRepository _productRepository;
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public ShoppingCartController(IProductRepository productRepository, UserManager<ApplicationUser> userManager, ApplicationDbContext context)
        {
            _productRepository = productRepository;
            _context = context;
            _userManager = userManager;
        }

        // Helper method để lấy sản phẩm từ database (giữ nguyên)
        private async Task<Product> GetProductFromDatabase(int productId)
        {
            var product = await _productRepository.GetByIdAsync(productId);
            return product;
        }

        // GET: /ShoppingCart/Index (Hiển thị giỏ hàng đầy đủ)
        public async Task<IActionResult> Index()
        {
            var userId = _userManager.GetUserId(User);
            if (userId == null)
            {
                return RedirectToPage("/Account/Login", new { area = "Identity" });
            }

            var cartItems = await _context.CartItems
                                          .Where(ci => ci.UserId == userId)
                                          .Include(ci => ci.Product)
                                          .ToListAsync();

            decimal cartTotal = 0;
            if (cartItems != null && cartItems.Any())
            {
                foreach (var item in cartItems)
                {
                    if (item.Product != null)
                    {
                        cartTotal += (item.Product.PriceReduced.HasValue && item.Product.PriceReduced > 0 ? item.Product.PriceReduced.Value : item.Product.Price) * item.Quantity;
                    }
                }
            }

            // --- THAY ĐỔI LỚN TẠI ĐÂY ---
            // Tạo một instance của ShoppingCartViewModel
            var viewModel = new ShoppingCartViewModel
            {
                CartItemsFromDb = cartItems, // Gán danh sách CartItem vào thuộc tính này
                CartTotal = cartTotal        // Gán tổng tiền của toàn bộ giỏ hàng vào thuộc tính này
            };

            // --- KHÔNG CẦN DÙNG ViewBag NỮA ---
            // ViewBag.InitialCartTotalFormatted = initialTotal.ToString("N0");

            // --- TRẢ VỀ VIEWMODEL THAY VÌ LIST<CARTITEM> ---
            return View(viewModel);
        }

        // POST: /ShoppingCart/AddToCart (Thêm sản phẩm vào giỏ hàng đầy đủ)
        [HttpPost] // Thường thêm vào giỏ hàng là thao tác POST
        public async Task<IActionResult> AddToCart(int productId, int quantity = 1, string flavor = null) // Nhận productId và quantity
        {
            // Kiểm tra đăng nhập
            if (!User.Identity.IsAuthenticated)
            {
                return RedirectToPage("/Account/Login", new { area = "Identity" });
            }

            var userId = _userManager.GetUserId(User);
            if (userId == null)
            {
                return RedirectToPage("/Account/Login", new { area = "Identity" });
            }

            var product = await GetProductFromDatabase(productId);
            if (product == null)
            {
                return NotFound("Product not found");
            }

            // Tìm kiếm mục giỏ hàng của người dùng cho sản phẩm này trong DB
            var existingCartItem = await _context.CartItems
                                                 .FirstOrDefaultAsync(ci => ci.UserId == userId 
                                                 && ci.ProductId == productId
                                                 && ci.SelectedFlavor == flavor);

            if (existingCartItem != null)
            {
                // Nếu sản phẩm đã có trong giỏ, tăng số lượng
                existingCartItem.Quantity += quantity;
            }
            else
            {
                // Nếu sản phẩm chưa có, tạo một mục giỏ hàng mới trong DB
                var newCartItem = new CartItem
                {
                    UserId = userId,
                    ProductId = productId,
                    Quantity = quantity,
                    SelectedFlavor = flavor ??"",
                    DateCreated = DateTime.UtcNow // Gán thời gian tạo
                };
                _context.CartItems.Add(newCartItem);
            }

            // Lưu thay đổi vào database
            await _context.SaveChangesAsync();

          
            return RedirectToAction("Index");
        }

        
        [HttpPost]
        public async Task<IActionResult> BuyNow(int productId, int quantity = 1)
        {
            if (!User.Identity.IsAuthenticated)
            {
                return RedirectToPage("/Account/Login", new { area = "Identity" });
            }

            var product = await GetProductFromDatabase(productId);
            if (product == null)
            {
                return NotFound("Product not found");
            }
          
            return RedirectToAction("Checkout", new { isBuyNow = true, buyNowProductId = productId, buyNowQuantity = quantity });

        }

        [HttpPost]
        public async Task<IActionResult> RemoveFromCart([FromBody] RemoveFromCartRequest request) 
        {
            
            Console.WriteLine($"RemoveFromCart called for CartItemId: {request.CartItemId}");

            var userId = _userManager.GetUserId(User);

            if (string.IsNullOrEmpty(userId))
            {
                Console.WriteLine("Lỗi: Không tìm thấy User ID. Người dùng có thể chưa đăng nhập.");
                return Json(new { success = false, message = "Bạn cần đăng nhập để xóa sản phẩm khỏi giỏ hàng." });
            }
            Console.WriteLine($"User ID: {userId}"); 

            var itemToRemove = await _context.CartItems
                                             .FirstOrDefaultAsync(ci => ci.Id == request.CartItemId && ci.UserId == userId); // SỬ DỤNG request.CartItemId

            if (itemToRemove != null)
            {
                try
                {
                    _context.CartItems.Remove(itemToRemove);
                    await _context.SaveChangesAsync();

                    // Cập nhật tổng tiền giỏ hàng sau khi xóa
                    var updatedCartItems = await _context.CartItems
                                                         .Where(ci => ci.UserId == userId)
                                                         .Include(ci => ci.Product)
                                                         .ToListAsync();
                    decimal newOverallCartTotal = updatedCartItems.Sum(ci => (ci.Product.PriceReduced.HasValue && ci.Product.PriceReduced > 0 ? ci.Product.PriceReduced.Value : ci.Product.Price) * ci.Quantity);

                    return Json(new { success = true, message = "Sản phẩm đã được xóa khỏi giỏ hàng thành công.", cartOverallTotal = newOverallCartTotal.ToString("N0") + "đ" });
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Lỗi khi xóa sản phẩm khỏi giỏ hàng (CartItemId: {request.CartItemId}, UserId: {userId}): {ex.Message}");
                    if (ex.InnerException != null)
                    {
                        Console.WriteLine($"Inner exception: {ex.InnerException.Message}");
                    }
                    return Json(new { success = false, message = "Đã xảy ra lỗi server khi xóa sản phẩm. Vui lòng thử lại." });
                }
            }
            else
            {
                Console.WriteLine($"Không tìm thấy CartItem với ID: {request.CartItemId} cho User ID: {userId}.");
                return Json(new { success = false, message = "Không tìm thấy sản phẩm trong giỏ hàng để xóa. Vui lòng làm mới trang." });
            }
        }



        // Trong ShoppingCartController.cs

        [HttpGet]
        public async Task<IActionResult> Checkout(
            [FromQuery] List<int> selectedCartItemIds, // Dành cho giỏ hàng có tích chọn
            [FromQuery] bool isBuyNow = false,
            [FromQuery] int? buyNowProductId = null,
            [FromQuery] int? buyNowQuantity = null,
            [FromQuery] string buyNowFlavor = null)
        {
            var user = await _userManager.GetUserAsync(User);
            if (user == null)
            {
                return RedirectToPage("/Account/Login", new { area = "Identity" });
            }
            var userId = user.Id;

            List<CartItem> itemsToProcess = new List<CartItem>();
            decimal cartTotal = 0;
            bool isBuyNowFlow = false; // Cờ hiệu để biết luồng nào được sử dụng

            // Ưu tiên xử lý giỏ hàng với các mục đã chọn
            if (selectedCartItemIds != null && selectedCartItemIds.Any())
            {
                itemsToProcess = await _context.CartItems
                                               .Where(ci => selectedCartItemIds.Contains(ci.Id) && ci.UserId == userId)
                                               .Include(ci => ci.Product)
                                               .ToListAsync();

                if (!itemsToProcess.Any())
                {
                    TempData["ErrorMessage"] = "Không tìm thấy sản phẩm hợp lệ nào trong giỏ hàng đã chọn.";
                    return RedirectToAction("Index");
                }
            }
            // Nếu không có mục giỏ hàng nào được chọn, kiểm tra "Mua ngay"
            else if (isBuyNow && buyNowProductId.HasValue && buyNowQuantity.HasValue && buyNowQuantity.Value > 0)
            {
                var product = await GetProductFromDatabase(buyNowProductId.Value); // <-- SỬ DỤNG _productRepository

                if (product != null)
                {
                    var buyNowItem = new CartItem
                    {
                        ProductId = buyNowProductId.Value,
                        Quantity = buyNowQuantity.Value,
                        Product = product,
                        SelectedFlavor = buyNowFlavor ?? ""
                    };
                    itemsToProcess.Add(buyNowItem);
                    isBuyNowFlow = true;
                }
                else
                {
                    TempData["ErrorMessage"] = "Sản phẩm 'Mua ngay' không tồn tại.";
                    return RedirectToAction("Index");
                }
            }
            else
            {
                TempData["ErrorMessage"] = "Vui lòng chọn sản phẩm để thanh toán hoặc sử dụng chức năng mua ngay.";
                return RedirectToAction("Index");
            }

            // Tính toán tổng tiền
            foreach (var item in itemsToProcess)
            {
                if (item.Product != null)
                {
                    cartTotal += (item.Product.PriceReduced.HasValue && item.Product.PriceReduced > 0 ? item.Product.PriceReduced.Value : item.Product.Price) * item.Quantity;
                }
            }

            var viewModel = new CheckoutViewModel
            {
                CartItemsFromDb = itemsToProcess,
                CartTotal = cartTotal,
                IsBuyNowCheckout = isBuyNowFlow,
                BuyNowProductId = isBuyNowFlow ? buyNowProductId : null,
                BuyNowQuantity = isBuyNowFlow ? buyNowQuantity : null,
                BuyNowFlavor = isBuyNowFlow ? buyNowFlavor : null,

              
                SelectedCartItemIds = itemsToProcess.Where(ci => ci.Id != 0).Select(ci => ci.Id).ToList()
               
            };
            viewModel.Order = new Order
            {
                Status = OrderStatusEnum.ChoXacNhan
                // Bạn có thể gán các thuộc tính mặc định khác của Order tại đây nếu cần
            };

            return View(viewModel);
        }

        // Trong ShoppingCartController.cs

        [HttpPost]
        public async Task<IActionResult> Checkout(CheckoutViewModel model)
        {
            var user = await _userManager.GetUserAsync(User);
            if (user == null)
            {
                return RedirectToPage("/Account/Login", new { area = "Identity" });
            }
            var userId = user.Id;

            List<CartItem> itemsForOrder = new List<CartItem>();

            if (model.IsBuyNowCheckout)
            {
                if (model.BuyNowProductId.HasValue && model.BuyNowQuantity.HasValue && model.BuyNowQuantity.Value > 0)
                {
                    var product = await GetProductFromDatabase(model.BuyNowProductId.Value);

                    if (product != null)
                    {
                        var buyNowItem = new CartItem
                        {
                            ProductId = model.BuyNowProductId.Value,
                            Quantity = model.BuyNowQuantity.Value,
                            Product = product,
                            SelectedFlavor = model.BuyNowFlavor ?? ""
                        };
                        itemsForOrder.Add(buyNowItem);
                    }
                }
                if (!itemsForOrder.Any())
                {
                    TempData["ErrorMessage"] = "Không tìm thấy sản phẩm 'Mua ngay' hợp lệ để thanh toán.";
                    return RedirectToAction("Index");
                }
            }
            else
            {
                if (model.SelectedCartItemIds == null || !model.SelectedCartItemIds.Any())
                {
                    TempData["ErrorMessage"] = "Vui lòng chọn sản phẩm để thanh toán.";
                    return RedirectToAction("Index");
                }

                itemsForOrder = await _context.CartItems
                                               .Where(ci => model.SelectedCartItemIds.Contains(ci.Id) && ci.UserId == userId)
                                               .Include(ci => ci.Product)
                                               .ToListAsync();

                if (itemsForOrder == null || !itemsForOrder.Any())
                {
                    TempData["ErrorMessage"] = "Không tìm thấy sản phẩm hợp lệ nào trong giỏ hàng đã chọn.";
                    return RedirectToAction("Index");
                }
            }

            var order = model.Order;
            order.UserId = userId;
            order.OrderDate = DateTime.UtcNow;
            order.Status = OrderStatusEnum.ChoXacNhan;

            order.OrderDetails = new List<OrderDetail>();
            decimal total = 0;

            foreach (var item in itemsForOrder)
            {
                if (item.Product != null)
                {
                    var orderDetail = new OrderDetail
                    {
                        ProductId = item.ProductId,
                        Quantity = item.Quantity,
                        Price = item.Product.PriceReduced.HasValue && item.Product.PriceReduced > 0 ? (decimal)item.Product.PriceReduced.Value : item.Product.Price,
                        SelectedFlavor = item.SelectedFlavor ?? "",
                    };
                    order.OrderDetails.Add(orderDetail);
                    total += orderDetail.Price * orderDetail.Quantity;
                }
            }
            order.TotalPrice = total;

            if (!order.OrderDetails.Any())
            {
                TempData["ErrorMessage"] = "Không có chi tiết đơn hàng nào được tạo. Vui lòng thử lại.";
                return RedirectToAction("Index");
            }

            try
            {
                _context.Orders.Add(order);
                await _context.SaveChangesAsync();

                if (!model.IsBuyNowCheckout)
                {
                    var cartItemsToRemove = await _context.CartItems
                                                          .Where(ci => model.SelectedCartItemIds.Contains(ci.Id) && ci.UserId == userId)
                                                          .ToListAsync();

                    if (cartItemsToRemove.Any())
                    {
                        _context.CartItems.RemoveRange(cartItemsToRemove);
                        await _context.SaveChangesAsync();
                    }
                }

                return View("OrderCompleted", order);
            }
            catch (DbUpdateException ex)
            {
                Console.WriteLine($"DbUpdateException error: {ex.Message}");
                Console.WriteLine($"Inner Exception: {ex.InnerException?.Message}");
                ModelState.AddModelError("", "Có lỗi xảy ra khi xử lý đơn hàng. Vui lòng thử lại.");
                await LoadCheckoutViewModelForError(model, userId);
                return View("Checkout", model);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Lỗi khi xử lý đơn hàng: {ex.Message}");
                ModelState.AddModelError("", "Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.");
                await LoadCheckoutViewModelForError(model, userId);
                return View("Checkout", model);
            }
        }

        private async Task LoadCheckoutViewModelForError(CheckoutViewModel model, string userId)
        {
            if (model.IsBuyNowCheckout)
            {
                if (model.BuyNowProductId.HasValue && model.BuyNowQuantity.HasValue)
                {
                    var product = await GetProductFromDatabase(model.BuyNowProductId.Value);
                    if (product != null)
                    {
                        model.CartItemsFromDb = new List<CartItem>
                {
                    new CartItem
                    {
                        ProductId = model.BuyNowProductId.Value,
                        Quantity = model.BuyNowQuantity.Value,
                        Product = product,
                        SelectedFlavor = model.BuyNowFlavor ?? ""
                    }
                };
                        model.CartTotal = (product.PriceReduced.HasValue && product.PriceReduced > 0 ? product.PriceReduced.Value : product.Price) * model.BuyNowQuantity.Value;
                    }
                }
            }
            else
            {
                if (model.SelectedCartItemIds != null && model.SelectedCartItemIds.Any())
                {
                    model.CartItemsFromDb = await _context.CartItems
                                                         .Include(ci => ci.Product)
                                                         .Where(ci => model.SelectedCartItemIds.Contains(ci.Id) && ci.UserId == userId)
                                                         .ToListAsync();
                    model.CartTotal = model.CartItemsFromDb.Sum(item =>
                        (item.Product.PriceReduced.HasValue && item.Product.PriceReduced > 0
                            ? item.Product.PriceReduced.Value
                            : item.Product.Price) * item.Quantity);
                }
            }
        }


        [HttpPost]
        public async Task<IActionResult> UpdateQuantity([FromBody] UpdateQuantityRequest request)
        {
            // Kiểm tra request có null không (có thể xảy ra nếu JSON body lỗi)
            if (request == null)
            {
                return BadRequest(new { success = false, message = "Dữ liệu yêu cầu không hợp lệ." });
            }

            var cartItemId = request.CartItemId; // Lấy CartItem.Id từ request
            var productId = request.ProductId; // Giữ lại ProductId để tham chiếu nếu cần
            var quantity = request.Quantity;

            // Kiểm tra đăng nhập
            if (!User.Identity.IsAuthenticated)
            {
                return Unauthorized(new { success = false, message = "Người dùng chưa đăng nhập." });
            }

            var userId = _userManager.GetUserId(User);
            if (userId == null)
            {
                return Unauthorized(new { success = false, message = "Người dùng chưa đăng nhập." });
            }

            // Đảm bảo số lượng hợp lệ (>= 0 để xử lý xóa)
            if (quantity < 0)
            {
                quantity = 1; // Mặc định về 1 nếu số lượng âm, hoặc có thể trả lỗi BadRequest
            }

            // Tìm mục giỏ hàng chính xác bằng CartItem.Id và UserId
            var cartItem = await _context.CartItems
                                         .FirstOrDefaultAsync(ci => ci.Id == cartItemId && ci.UserId == userId); // <--- Dòng đã sửa: Tìm theo CartItem.Id

            if (cartItem == null)
            {
                // Không tìm thấy mục giỏ hàng
                return NotFound(new { success = false, message = "Không tìm thấy sản phẩm trong giỏ hàng." });
            }

            // Xử lý trường hợp số lượng là 0 => xóa sản phẩm
            if (quantity == 0)
            {
                _context.CartItems.Remove(cartItem);
                await _context.SaveChangesAsync();

                // Tính lại tổng tiền giỏ hàng sau khi xóa
                var allCartItemsAfterRemove = await _context.CartItems
                                                            .Where(ci => ci.UserId == userId)
                                                            .Include(ci => ci.Product)
                                                            .ToListAsync();
                decimal cartOverallTotalAfterRemove = allCartItemsAfterRemove.Sum(ci => (ci.Product?.PriceReduced.HasValue == true && ci.Product.PriceReduced > 0 ? ci.Product.PriceReduced.Value : ci.Product.Price) * ci.Quantity);

                return Json(new { success = true, action = "removed", itemId = cartItem.Id, cartOverallTotal = cartOverallTotalAfterRemove.ToString("N0") + "đ" });
            }

            // Cập nhật số lượng
            cartItem.Quantity = quantity;

            // Lưu thay đổi vào database
            try
            {
                await _context.SaveChangesAsync();

                // Lấy lại thông tin sản phẩm để tính giá
                var product = await GetProductFromDatabase(cartItem.ProductId);
                if (product == null)
                {
                    return StatusCode(500, new { success = false, message = "Sản phẩm không tồn tại trong database." });
                }

                var itemTotalPrice = (product.PriceReduced.HasValue && product.PriceReduced > 0 ? product.PriceReduced.Value : product.Price) * cartItem.Quantity;

                // Tính lại tổng tiền toàn bộ giỏ hàng
                var allCartItems = await _context.CartItems
                                                 .Where(ci => ci.UserId == userId)
                                                 .Include(ci => ci.Product)
                                                 .ToListAsync();
                decimal cartOverallTotal = allCartItems.Sum(ci => (ci.Product?.PriceReduced.HasValue == true && ci.Product.PriceReduced > 0 ? ci.Product.PriceReduced.Value : ci.Product.Price) * ci.Quantity);


                return Json(new { success = true, message = "Cập nhật số lượng thành công.", itemId = cartItem.Id, newQuantity = cartItem.Quantity, itemTotalPrice = itemTotalPrice.ToString("N0") + "đ", cartOverallTotal = cartOverallTotal.ToString("N0") + "đ" });
            }
            catch (DbUpdateConcurrencyException)
            {
                return StatusCode(500, new { success = false, message = "Lỗi cập nhật dữ liệu đồng thời." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = "Đã xảy ra lỗi server: " + ex.Message });
            }
        }
    }
}