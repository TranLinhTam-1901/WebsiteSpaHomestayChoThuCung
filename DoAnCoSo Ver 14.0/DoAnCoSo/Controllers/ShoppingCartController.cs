using DoAnCoSo.Models;
using DoAnCoSo.Repositories;
using DoAnCoSo.Services;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Controllers
{
    //[Authorize] // Nếu bạn muốn yêu cầu đăng nhập cho toàn bộ Controller
    public class ShoppingCartController : Controller
    {
        private readonly IProductRepository _productRepository;
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly EmailService _emailService;


        public ShoppingCartController(IProductRepository productRepository,
                                      UserManager<ApplicationUser> userManager,
                                      ApplicationDbContext context,
                                      EmailService emailService)
        {
            _productRepository = productRepository;
            _context = context;
            _userManager = userManager;
            _emailService = emailService;
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
                    SelectedFlavor = flavor ?? "",
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

            // --- Lấy sản phẩm ---
            if (model.IsBuyNowCheckout)
            {
                if (model.BuyNowProductId.HasValue && model.BuyNowQuantity.HasValue && model.BuyNowQuantity.Value > 0)
                {
                    var product = await GetProductFromDatabase(model.BuyNowProductId.Value);
                    if (product != null)
                    {
                        itemsForOrder.Add(new CartItem
                        {
                            ProductId = model.BuyNowProductId.Value,
                            Quantity = model.BuyNowQuantity.Value,
                            Product = product,
                            SelectedFlavor = model.BuyNowFlavor ?? ""
                        });
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

                if (!itemsForOrder.Any())
                {
                    TempData["ErrorMessage"] = "Không tìm thấy sản phẩm hợp lệ nào trong giỏ hàng đã chọn.";
                    return RedirectToAction("Index");
                }
            }

            // --- Tạo Order ---
            var order = model.Order;
            order.UserId = userId;
            order.OrderDate = DateTime.UtcNow;
            order.Status = OrderStatusEnum.ChoXacNhan;
            order.OrderDetails = new List<OrderDetail>();
            order.PaymentMethod = model.Order.PaymentMethod;

            decimal total = 0;
            foreach (var item in itemsForOrder)
            {
                if (item.Product != null)
                {
                    var price = item.Product.PriceReduced.HasValue && item.Product.PriceReduced > 0
                        ? (decimal)item.Product.PriceReduced.Value
                        : item.Product.Price;

                    var orderDetail = new OrderDetail
                    {
                        ProductId = item.ProductId,
                        Quantity = item.Quantity,
                        Price = price,
                        SelectedFlavor = item.SelectedFlavor ?? ""
                    };

                    order.OrderDetails.Add(orderDetail);
                    total += orderDetail.Price * orderDetail.Quantity;
                }
            }
            order.TotalPrice = total;
            _context.Orders.Add(order);
            // --- Áp dụng khuyến mãi nếu người dùng nhập mã ---
            if (!string.IsNullOrEmpty(model.PromoCode))
            {
                string code = model.PromoCode.Trim().ToUpper();

                var promo = await _context.Promotions
                    .FirstOrDefaultAsync(p =>
                        p.Code.ToUpper() == code &&
                        p.IsActive &&
                        p.StartDate <= DateTime.Now &&
                        p.EndDate >= DateTime.Now);

                if (promo != null)
                {
                    if (promo.IsPrivate)
                    {
                        bool allowed = await _context.UserPromotions
                            .AnyAsync(up => up.UserId == user.Id && up.PromotionId == promo.Id);

                        if (!allowed)
                        {
                            TempData["ErrorMessage"] = "❌ Mã này không dành cho tài khoản của bạn.";
                            promo = null;
                        }
                    }
                    // ✅ Kiểm tra số lượt dùng
                    int usedCount = await _context.OrderPromotions.CountAsync(op => op.PromotionId == promo.Id);
                    if (promo.MaxUsage.HasValue && usedCount >= promo.MaxUsage.Value)
                    {
                        TempData["ErrorMessage"] = "Mã khuyến mãi đã hết lượt sử dụng.";
                        promo = null;
                    }

                    // 🧩 ĐÃ THÊM: Kiểm tra số lần user đã dùng mã
                    if (promo != null && promo.MaxUsagePerUser.HasValue)
                    {
                        int userUsedCount = await _context.OrderPromotions
                            .CountAsync(op => op.PromotionId == promo.Id && op.Order.UserId == user.Id);

                        if (userUsedCount >= promo.MaxUsagePerUser.Value)
                        {
                            TempData["ErrorMessage"] = "Bạn đã sử dụng mã này tối đa số lần cho phép.";
                            promo = null;
                        }
                    }
                    // ✅ Kiểm tra điều kiện tối thiểu
                    if (promo != null)
                    {
                        if (promo.MinOrderValue.HasValue && total < promo.MinOrderValue.Value)
                        {
                            TempData["ErrorMessage"] = $"Đơn hàng chưa đạt giá trị tối thiểu ({promo.MinOrderValue:N0}đ) để sử dụng mã này.";
                        }
                        else
                        {
                            // ✅ Tính số tiền giảm
                            decimal discountAmount = promo.IsPercent
                                ? total * (promo.Discount / 100)
                                : promo.Discount;

                            // Không cho âm
                            if (discountAmount > total)
                                discountAmount = total;

                            // ✅ Giảm vào tổng tiền
                            order.TotalPrice = total - discountAmount;
                            Console.WriteLine($"✅ Tổng sau giảm: {order.TotalPrice} (Giảm {discountAmount})");

                            // ✅ Ghi nhận việc dùng mã
                            var orderPromo = new OrderPromotion
                            {
                                PromotionId = promo.Id,
                                Order = order,
                                CodeUsed = promo.Code,
                                DiscountApplied = discountAmount,
                                UsedAt = DateTime.Now
                            };

                            _context.OrderPromotions.Add(orderPromo);
                            // 🧩 ĐÃ THÊM: Đánh dấu mã đã dùng trong UserPromotion (nếu tồn tại)
                            var userPromo = await _context.UserPromotions
                                .FirstOrDefaultAsync(up => up.UserId == user.Id && up.PromotionId == promo.Id);

                            if (userPromo != null)
                            {
                                userPromo.IsUsed = true;
                                userPromo.UsedAt = DateTime.Now;
                            }
                        }
                    }
                }
                else
                {
                    TempData["ErrorMessage"] = "Mã khuyến mãi không hợp lệ hoặc đã hết hạn.";
                }
            }
            else
            {
                // Không có mã khuyến mãi → tổng tiền là tổng gốc
                order.TotalPrice = total;
            }      


            if (!order.OrderDetails.Any())
            {
                TempData["ErrorMessage"] = "Không có chi tiết đơn hàng nào được tạo. Vui lòng thử lại.";
                return RedirectToAction("Index");
            }

            if(order.PaymentMethod == "BankTransfer")
            {
                await _context.SaveChangesAsync();
                return RedirectToAction(
                    actionName: "Payment",
                    controllerName: "BankTransfer",
                    routeValues: new { orderId = order.Id }
                );
            }

            try
            {
                //order.TotalPrice = total;

                // 1. Lưu đơn hàng
                //_context.Orders.Add(order);
                await _context.SaveChangesAsync();

                // 2. Gửi email xác nhận (nếu lỗi → chỉ log, không phá Checkout)
                try
                {
                    var customerEmail = user.Email;

                    // ✅ Chuyển giờ UTC sang giờ VN
                    var vnTimeZone = TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time"); // Windows
                    var vnDate = TimeZoneInfo.ConvertTimeFromUtc(order.OrderDate.ToUniversalTime(), vnTimeZone);

                    string body = $@"
                    <h2>🎉 Cảm ơn {user.FullName} đã đặt hàng tại PawHouse!</h2>
                    <p><b>Mã đơn:</b> {order.Id}</p>
                    <p><b>Ngày đặt:</b> {vnDate:dd/MM/yyyy HH:mm}</p>
                    <p><b>Chi tiết đơn hàng:</b></p>
                    <table border='1' cellpadding='5' cellspacing='0'>
                        <tr>
                            <th>Sản phẩm</th>
                            <th>Số lượng</th>
                            <th>Giá</th>
                            <th>Thành tiền</th>
                        </tr>";

                    foreach (var detail in order.OrderDetails)
                    {
                        var product = await _context.Products.FindAsync(detail.ProductId);
                        body += $@"
                        <tr>
                            <td>{product?.Name}</td>
                            <td>{detail.Quantity}</td>
                            <td>{detail.Price:N0}đ</td>
                            <td>{(detail.Price * detail.Quantity):N0}đ</td>
                        </tr>";
                    }

                    body += $@"
                    </table>
                    <p><b>Tổng cộng:</b> {order.TotalPrice:N0}đ</p>
                    <p>Chúng tôi sẽ liên hệ để xác nhận đơn hàng trong thời gian sớm nhất.</p>";

                    await _emailService.SendEmailAsync(customerEmail, "Đặt thành công đơn hàng #" + order.Id, body);
                }
                catch (Exception exMail)
                {
                    Console.WriteLine($"⚠️ Lỗi gửi mail: {exMail.Message}");
                }

                // 3. Xóa sản phẩm trong giỏ hàng nếu không phải "Mua ngay"
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

                // 4. Trả về trang hoàn tất
                return View("OrderCompleted", order);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Lỗi khi xử lý đơn hàng: {ex.Message}");
                ModelState.AddModelError("", "Có lỗi xảy ra khi xử lý đơn hàng. Vui lòng thử lại.");
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
                                         .FirstOrDefaultAsync(ci => ci.Id == cartItemId && ci.UserId == userId); 

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

        [HttpGet]
        public async Task<IActionResult> GetValidPromos(decimal cartTotal)
        {
            var now = DateTime.Now;
            var user = await _userManager.GetUserAsync(User);
            var userId = user?.Id;

            // Lấy id các promo đã gán riêng cho user (nếu có)
            var assignedIds = userId == null
                ? new List<int>()
                : await _context.UserPromotions
                    .Where(up => up.UserId == userId)
                    .Select(up => up.PromotionId)
                    .ToListAsync();

            // Lấy các mã public, còn hạn, còn hiệu lực
            var promos = await _context.Promotions
                .Where(p => p.IsActive && p.StartDate <= now && p.EndDate >= now)
                .ToListAsync();

            // Lọc theo giá trị tối thiểu, lượt dùng, v.v.
            var validPromos = new List<object>();
            foreach (var p in promos)
            {
                if (p.IsPrivate)
                {
                    if (user == null)
                        continue;

                    bool allowed = await _context.UserPromotions
                        .AnyAsync(up => up.UserId == user.Id && up.PromotionId == p.Id);

                    if (!allowed)
                        continue;
                }

                if (p.MinOrderValue.HasValue && cartTotal < p.MinOrderValue.Value)
                    continue;

                if (p.MaxUsage.HasValue)
                {
                    int used = await _context.OrderPromotions.CountAsync(op => op.PromotionId == p.Id);
                    if (used >= p.MaxUsage.Value)
                        continue;
                }
                bool isUsed = false;
                if (user != null && p.MaxUsagePerUser.HasValue)
                {
                    int userUsedCount = await _context.OrderPromotions
                        .CountAsync(op => op.PromotionId == p.Id && op.Order.UserId == user.Id);
                    isUsed = userUsedCount >= p.MaxUsagePerUser.Value;
                }
                validPromos.Add(new
                {
                    p.Id,
                    p.Code,
                    p.Title,
                    p.Discount,
                    p.IsPercent,
                    p.EndDate,
                    p.MinOrderValue,
                    Description = p.ShortDescription ?? "",
                    IsUsedByUser = isUsed // đanh dấu đã dùng bởi user
                });      
            }
            //validPromos = validPromos
            //.GroupBy(p => (string)p.Code)
            //.Select(g => g.First())
            //.ToList();

            return Json(validPromos);
        }
        [HttpPost]
        public async Task<IActionResult> ValidatePromo([FromBody] PromoCheckRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.Code))
                return Json(new { success = false, message = "⚠️ Vui lòng nhập mã khuyến mãi." });

            var code = request.Code.Trim().ToUpper();
            var total = request.CartTotal;
            var now = DateTime.Now;

            var promo = await _context.Promotions
                .FirstOrDefaultAsync(p => p.Code.ToUpper() == code
                                          && p.IsActive
                                          && p.StartDate <= now
                                          && p.EndDate >= now);

            if (promo == null)
                return Json(new { success = false, message = "❌ Mã khuyến mãi không hợp lệ hoặc đã hết hạn." });

            // 🧩 Nếu mã là riêng tư → kiểm tra quyền sử dụng
            var user = await _userManager.GetUserAsync(User);
            if (promo.IsPrivate)
            {
                if (user == null)
                    return Json(new { success = false, message = "❌ Bạn cần đăng nhập để sử dụng mã này." });

                bool allowed = await _context.UserPromotions
                    .AnyAsync(up => up.UserId == user.Id && up.PromotionId == promo.Id);

                if (!allowed)
                    return Json(new { success = false, message = "❌ Mã này không dành cho tài khoản của bạn." });
            }

            if (promo.MinOrderValue.HasValue && total < promo.MinOrderValue.Value)
                return Json(new { success = false, message = $"⚠️ Đơn hàng chưa đạt {promo.MinOrderValue.Value:N0}đ để sử dụng mã này." });

            if (promo.MaxUsage.HasValue)
            {
                var used = await _context.OrderPromotions.CountAsync(op => op.PromotionId == promo.Id);
                if (used >= promo.MaxUsage.Value)
                    return Json(new { success = false, message = "❌ Mã đã hết lượt sử dụng." });
            }

            // 🧩 ĐÃ THÊM: Kiểm tra số lần user này đã sử dụng mã
            //var user = await _userManager.GetUserAsync(User);
            if (user != null && promo.MaxUsagePerUser.HasValue)
            {
                int userUsedCount = await _context.OrderPromotions
                    .CountAsync(op => op.PromotionId == promo.Id && op.Order.UserId == user.Id);

                if (userUsedCount >= promo.MaxUsagePerUser.Value)
                {
                    return Json(new { success = false, message = "❌ Bạn đã sử dụng mã này tối đa số lần cho phép." });
                }
            }

            decimal discount = promo.IsPercent ? total * (promo.Discount / 100) : promo.Discount;
            if (discount > total) discount = total;

            var discountLabel = promo.IsPercent ? $"{promo.Discount}%" : $"{promo.Discount:N0}đ";

            // 🟩 Phân biệt cách hiển thị message
            string message = promo.IsPercent
                ? $"✅ Áp dụng thành công! Giảm {discount:N0}đ ({discountLabel})."
                : $"✅ Áp dụng thành công! Giảm {discount:N0}đ.";

            return Json(new
            {
                success = true,
                message,
                discount
            });
        }
        //test
        //[HttpGet]
        //public IActionResult BankTransferPayment(int orderId, decimal amount)
        //{
        //    if (orderId <= 0 || amount <= 0)
        //    {
        //        return RedirectToAction("Index", "ShoppingCart");
        //    }

        //    ViewData["OrderId"] = orderId;
        //    ViewData["Amount"] = amount;

        //    string qrText = $"Thanh toán đơn #{orderId} - Số tiền: {amount}";

        //    ViewBag.QRImageUrl =
        //        $"https://img.vietqr.io/image/MBBank-0123456789-compact.png?amount={amount}&addInfo=ORDER{orderId}";

        //    return View();
        //}

    }
}