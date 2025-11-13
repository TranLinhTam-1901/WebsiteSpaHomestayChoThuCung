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
        private readonly IInventoryService _inventory;


        public ShoppingCartController(IProductRepository productRepository,
                                      UserManager<ApplicationUser> userManager,
                                      ApplicationDbContext context,
                                      EmailService emailService,
                                      IInventoryService inventory)
        {
            _productRepository = productRepository;
            _context = context;
            _userManager = userManager;
            _emailService = emailService;
            _inventory = inventory;
        }

        // Helper method để lấy sản phẩm từ database (giữ nguyên)
        private async Task<Product> GetProductFromDatabase(int productId)
        {
            var product = await _productRepository.GetByIdAsync(productId);
            return product;
        }
        
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
       
            var viewModel = new ShoppingCartViewModel
            {
                CartItemsFromDb = cartItems, // Gán danh sách CartItem vào thuộc tính này
                CartTotal = cartTotal        // Gán tổng tiền của toàn bộ giỏ hàng vào thuộc tính này
            };
           
            return View(viewModel);
        }


        [HttpPost]
        [ValidateAntiForgeryToken] // bảo vệ CSRF
        public async Task<IActionResult> AddToCart(
    int productId,
    int quantity = 1,
    string? SelectedFlavor = null,   // ✅ đổi tên tham số để map đúng form
    int? variantId = null)
        {
            // 0) Auth
            if (!User.Identity.IsAuthenticated)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            var userId = _userManager.GetUserId(User);
            if (string.IsNullOrEmpty(userId))
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            // 1) Sản phẩm
            var product = await GetProductFromDatabase(productId);
            if (product == null)
                return NotFound("Product not found");

            if (product.IsDeleted || !product.IsActive)
            {
                TempData["ErrorMessage"] = "Sản phẩm đã ngừng kinh doanh.";
                return RedirectToAction("Details", "Product", new { id = productId });
            }

            // 2) Lấy tồn khả dụng + tên biến thể (nếu có)
            int available;
            string? variantName = null;

            bool hasVariant = variantId.HasValue && variantId.Value > 0; // chỉ coi là có biến thể khi > 0

            if (hasVariant)
            {
                int vid = variantId!.Value;
                var variant = await _context.ProductVariants
                    .Where(v => v.Id == vid && v.ProductId == productId)
                    .Select(v => new
                    {
                        v.Id,
                        v.ProductId,
                        v.Name,
                        v.IsActive,
                        Available = v.StockQuantity - v.ReservedQuantity
                    })
                    .FirstOrDefaultAsync();

                if (variant == null) return NotFound("Variant not found");
                if (!variant.IsActive)
                {
                    TempData["ErrorMessage"] = "Biến thể này đã ngừng kinh doanh.";
                    return RedirectToAction("Details", "Product", new { id = productId });
                }

                variantName = variant.Name;
                available = Math.Max(0, variant.Available);
            }
            else
            {
                available = await _inventory.GetAvailableAsync(product.Id);
            }

            available = Math.Max(0, available);

            // 3) Chuẩn hoá input
            int addQty = quantity <= 0 ? 1 : quantity;

            if (hasVariant && available == 0)
            {
                TempData["ErrorMessage"] = $"Biến thể '{variantName}' của '{product.Name}' hiện đã hết hàng.";
                return RedirectToAction("Details", "Product", new { id = productId });
            }

            // 4) Lượng đã có trong giỏ (tách 2 case để không trộn khoá)
            int existingQtySameKey;
            if (hasVariant)
            {
                existingQtySameKey = await _context.CartItems
                    .Where(ci => ci.UserId == userId && ci.ProductId == productId && ci.VariantId == variantId)
                    .Select(ci => ci.Quantity).FirstOrDefaultAsync();
            }
            else
            {
                var flavorKey = SelectedFlavor ?? string.Empty;   // ✅ dùng SelectedFlavor
                existingQtySameKey = await _context.CartItems
                    .Where(ci => ci.UserId == userId && ci.ProductId == productId && ci.VariantId == null && ci.SelectedFlavor == flavorKey)
                    .Select(ci => ci.Quantity).FirstOrDefaultAsync();
            }

            // 5) Check tồn (đã có + sắp thêm)
            if (addQty + existingQtySameKey > available)
            {
                var nameForMsg = hasVariant ? $"{product.Name} - {variantName}" : product.Name;
                TempData["ErrorMessage"] = $"Sản phẩm '{nameForMsg}' chỉ còn {available} cái trong kho.";
                return RedirectToAction("Details", "Product", new { id = productId });
            }

            // 6) Thêm/cộng trong giỏ
            CartItem? existingCartItem;
            if (hasVariant)
            {
                existingCartItem = await _context.CartItems.FirstOrDefaultAsync(ci =>
                    ci.UserId == userId && ci.ProductId == productId && ci.VariantId == variantId);
            }
            else
            {
                var flavorKey = SelectedFlavor ?? string.Empty;   // ✅ dùng SelectedFlavor
                existingCartItem = await _context.CartItems.FirstOrDefaultAsync(ci =>
                    ci.UserId == userId && ci.ProductId == productId && ci.VariantId == null && ci.SelectedFlavor == flavorKey);
            }

            if (existingCartItem != null)
            {
                existingCartItem.Quantity += addQty;
            }
            else
            {
                _context.CartItems.Add(new CartItem
                {
                    UserId = userId,
                    ProductId = productId,
                    VariantId = hasVariant ? variantId : null,
                    SelectedVariantName = hasVariant ? variantName : null,
                    Quantity = addQty,
                    SelectedFlavor = hasVariant ? null : (SelectedFlavor ?? string.Empty), // ✅ lưu đúng cột
                    DateCreated = DateTime.UtcNow
                });
            }

            await _context.SaveChangesAsync();
            return RedirectToAction("Index");
        }


        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> BuyNow(int productId, int quantity = 1, int? variantId = null, string? buyNowFlavor = null)
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            if (quantity <= 0) quantity = 1;

            // Lấy product + variants để kiểm tra hợp lệ
            var product = await _context.Products
                .Include(p => p.Variants)
                .FirstOrDefaultAsync(p => p.Id == productId);

            if (product == null)
                return NotFound("Product not found");


            if (product.IsDeleted || !product.IsActive)
            {
                TempData["ErrorMessage"] = "Sản phẩm đã ngừng kinh doanh.";
                return RedirectToAction("Details", "Product", new { id = productId });
            }

            if (variantId != null)
            {
                // ✅ Kiểm tồn theo biến thể
                var v = product.Variants?.FirstOrDefault(x => x.Id == variantId.Value);
                if (v == null)
                {
                    TempData["ErrorMessage"] = "Biến thể không hợp lệ.";
                    return RedirectToAction("Details", "Product", new { id = productId });
                }

                var availableVar = Math.Max(0, v.StockQuantity - v.ReservedQuantity);
                if (quantity > availableVar)
                {
                    TempData["ErrorMessage"] = $"Biến thể '{v.Name}' chỉ còn {availableVar} cái.";
                    return RedirectToAction("Details", "Product", new { id = productId });
                }
            }
            else
            {
                // ✅ Không có biến thể → kiểm tồn cấp sản phẩm
                var available = await _inventory.GetAvailableAsync(productId);
                if (quantity > available)
                {
                    TempData["ErrorMessage"] = $"Sản phẩm chỉ còn {available} cái trong kho.";
                    return RedirectToAction("Details", "Product", new { id = productId });
                }
            }

            // ✅ Chuyển qua Checkout, mang theo đầy đủ tham số
            return RedirectToAction(
                "Checkout", "ShoppingCart",
                new { isBuyNow = true, buyNowProductId = productId, buyNowQuantity = quantity, variantId = variantId, buyNowFlavor = buyNowFlavor }
            );
        }



        [HttpPost]
        public async Task<IActionResult> RemoveFromCart([FromBody] RemoveFromCartRequest request)
        {
            if (request == null || request.CartItemId <= 0)
                return Json(new { success = false, message = "Dữ liệu xóa không hợp lệ." });

            var userId = _userManager.GetUserId(User);
            if (string.IsNullOrEmpty(userId))
                return StatusCode(401, new { success = false, message = "Bạn cần đăng nhập." });

            var item = await _context.CartItems
                .FirstOrDefaultAsync(ci => ci.Id == request.CartItemId && ci.UserId == userId);

            if (item == null)
                return Json(new { success = false, message = "Không tìm thấy sản phẩm trong giỏ." });

            _context.CartItems.Remove(item);
            await _context.SaveChangesAsync();

            var updated = await _context.CartItems
                .Where(ci => ci.UserId == userId)
                .Include(ci => ci.Product)
                .ToListAsync();

            decimal newTotal = updated.Sum(ci =>
                (ci.Product.PriceReduced.HasValue && ci.Product.PriceReduced > 0
                    ? ci.Product.PriceReduced.Value
                    : ci.Product.Price) * ci.Quantity);

            return Json(new
            {
                success = true,
                message = "Đã xóa sản phẩm khỏi giỏ.",
                cartOverallTotal = newTotal.ToString("N0") + "đ",
                isEmpty = updated.Count == 0
            });
        }

        // Trong ShoppingCartController.cs
        [HttpGet]
        public async Task<IActionResult> Checkout(
        [FromQuery] List<int> selectedCartItemIds,
        [FromQuery] bool isBuyNow = false,
        [FromQuery] int? buyNowProductId = null,
        [FromQuery] int? buyNowQuantity = null,
        [FromQuery] string buyNowFlavor = null,
        [FromQuery] int? variantId = null)
        {

            if (isBuyNow && buyNowProductId.HasValue && buyNowQuantity.HasValue)
            {
                if (variantId.HasValue)
                {
                    var v = await _context.ProductVariants.AsNoTracking()
                                .FirstOrDefaultAsync(x => x.Id == variantId.Value);
                    if (v == null)
                    {
                        TempData["ErrorMessage"] = "Biến thể không tồn tại.";
                        return RedirectToAction("Details", "Product", new { id = buyNowProductId.Value });
                    }
                    var availableVar = Math.Max(0, v.StockQuantity - v.ReservedQuantity);
                    if (buyNowQuantity.Value > availableVar)
                    {
                        TempData["ErrorMessage"] = $"Biến thể '{v.Name}' chỉ còn {availableVar} cái.";
                        return RedirectToAction("Details", "Product", new { id = buyNowProductId.Value });
                    }
                }
                else
                {
                    var product = await _context.Products.FindAsync(buyNowProductId.Value);
                    if (product == null)
                    {
                        TempData["ErrorMessage"] = "Sản phẩm không tồn tại.";
                        return RedirectToAction("AllProducts", "Product");
                    }
                    var available = await _inventory.GetAvailableAsync(product.Id);
                    if (buyNowQuantity.Value > available)
                    {
                        TempData["ErrorMessage"] = $"Sản phẩm '{product.Name}' chỉ còn {available} cái trong kho.";
                        return RedirectToAction("Details", "Product", new { id = product.Id });
                    }
                }
            }


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

                if (product == null || product.IsDeleted || !product.IsActive)
                {
                    TempData["ErrorMessage"] = "Sản phẩm 'Mua ngay' đã ngừng kinh doanh.";
                    return RedirectToAction("AllProducts", "Product");
                }
                if (product != null)
                {
                    string? buyNowVariantName = null;
                    if (variantId.HasValue)
                    {
                        var v = await _context.ProductVariants.AsNoTracking()
                                    .FirstOrDefaultAsync(x => x.Id == variantId.Value);
                        buyNowVariantName = v?.Name;
                    }

                    var buyNowItem = new CartItem
                    {
                        ProductId = buyNowProductId.Value,
                        Quantity = buyNowQuantity.Value,
                        Product = product,
                        SelectedFlavor = buyNowFlavor ?? "",
                        VariantId = variantId,                  // 👈 THÊM
                        SelectedVariantName = buyNowVariantName // 👈 THÊM (nếu CartItem có)
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
                BuyNowVariantId = isBuyNowFlow ? variantId : null,  



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
                return RedirectToPage("/Account/Login", new { area = "Identity" });

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
                        // 🔹 NEW: đọc variantId từ query và tra tên biến thể
                        int? buyNowVariantId = model.BuyNowVariantId;   // 👈 LẤY TỪ MODEL
                        string? buyNowVariantName = null;
                        if (buyNowVariantId.HasValue)
                        {
                            var v = await _context.ProductVariants.AsNoTracking()
                                        .FirstOrDefaultAsync(x => x.Id == buyNowVariantId.Value);
                            buyNowVariantName = v?.Name;
                        }


                        itemsForOrder.Add(new CartItem
                        {
                            ProductId = model.BuyNowProductId.Value,
                            Quantity = model.BuyNowQuantity.Value,
                            Product = product,
                            SelectedFlavor = model.BuyNowFlavor ?? string.Empty,
                            VariantId = buyNowVariantId,                 // 🔹 NEW
                            SelectedVariantName = buyNowVariantName      // 🔹 NEW
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

            // NEW: chặn sản phẩm ẩn trong giỏ/BuyNow
            foreach (var item in itemsForOrder)
            {
                if (item.Product == null)
                    item.Product = await _context.Products.FindAsync(item.ProductId);

                if (item.Product == null || item.Product.IsDeleted || !item.Product.IsActive)
                {
                    TempData["ErrorMessage"] =
                        $"Sản phẩm '{item.Product?.Name ?? ("#" + item.ProductId)}' đã ngừng kinh doanh.";
                    await LoadCheckoutViewModelForError(model, userId);
                    return View("Checkout", model);
                }
            }

            // --- Kiểm tồn (giữ nguyên) ---
            foreach (var item in itemsForOrder)
            {
                int availableCheckout;
                if (item.VariantId.HasValue)
                {
                    var v = await _context.ProductVariants.AsNoTracking()
                                .FirstOrDefaultAsync(x => x.Id == item.VariantId.Value);
                    availableCheckout = v == null ? 0 : Math.Max(0, v.StockQuantity - v.ReservedQuantity);
                }
                else
                {
                    availableCheckout = await _inventory.GetAvailableAsync(item.ProductId);
                }

                if (item.Quantity > availableCheckout)
                {
                    TempData["ErrorMessage"] = $"Sản phẩm '{item.Product?.Name}' chỉ còn {availableCheckout} cái trong kho.";
                    await LoadCheckoutViewModelForError(model, userId); // giữ nguyên
                    return View("Checkout", model);
                }
            }

            // --- Tạo Order (giữ nguyên các trường khác) ---
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
                    var basePrice = item.Product.PriceReduced.HasValue && item.Product.PriceReduced > 0
                        ? (decimal)item.Product.PriceReduced.Value
                        : item.Product.Price;

                    // 🔹 NEW: map đủ Variant/Flavor vào OrderDetail
                    var orderDetail = new OrderDetail
                    {
                        ProductId = item.ProductId,
                        Quantity = item.Quantity,

                        VariantId = item.VariantId,                         // 🔹 NEW
                        VariantName = item.SelectedVariantName,              // 🔹 NEW
                        SelectedFlavor = item.SelectedFlavor ?? string.Empty,

                        OriginalPrice = basePrice,
                        DiscountedPrice = basePrice,
                        Price = basePrice
                    };

                    order.OrderDetails.Add(orderDetail);
                    total += basePrice * item.Quantity;
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

                            order.TotalPrice = total - discountAmount;
                            Console.WriteLine($"✅ Tổng sau giảm: {order.TotalPrice} (Giảm {discountAmount})");

                            // 🟩 THÊM MỚI: Phân bổ giảm giá đều cho từng sản phẩm
                            if (discountAmount > 0 && order.OrderDetails.Any())
                            {
                                decimal totalBeforeDiscount = total;

                                foreach (var detail in order.OrderDetails)
                                {
                                    decimal proportion = (detail.OriginalPrice * detail.Quantity) / totalBeforeDiscount;
                                    decimal lineDiscount = discountAmount * proportion;
                                    decimal discountPerUnit = lineDiscount / detail.Quantity;

                                    // 🟩 Cập nhật giá giảm cho từng dòng sản phẩm
                                    detail.DiscountedPrice = Math.Round(detail.OriginalPrice - discountPerUnit, 2);
                                    detail.Price = detail.DiscountedPrice; // đồng bộ giá hiển thị cũ
                                }
                            } 

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
                            // Đánh dấu mã đã dùng trong UserPromotion (nếu tồn tại)
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
                //Lưu đơn hàng              
                await _context.SaveChangesAsync();

                //Giữ hàng tạm sau khi đơn đã được lưu thành công
                try
                {
                    await _inventory.ReserveForOrderAsync(order.Id, userId);
                }
                catch (Exception exReserve)
                {
                    Console.WriteLine($"⚠️ Lỗi giữ hàng: {exReserve.Message}");

                    _context.Orders.Remove(order);
                    await _context.SaveChangesAsync();

                    TempData["ErrorMessage"] = "Sản phẩm đã hết hàng trong lúc bạn đặt. Đơn hàng không thể hoàn tất.";
                    await LoadCheckoutViewModelForError(model, userId);
                    return View("Checkout", model);
                }


                //CHỈNH SỬA: Cập nhật email hiển thị thêm giá gốc & giá sau giảm
                try
                {
                    var customerEmail = user.Email;
                    var vnTimeZone = TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time");
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
                    <th>Giá gốc</th>           <!-- 🟩 THÊM MỚI -->
                    <th>Giá sau giảm</th>      <!-- 🟩 THÊM MỚI -->
                    <th>Thành tiền</th>
                </tr>";

                    foreach (var detail in order.OrderDetails)
                    {
                        var product = await _context.Products.FindAsync(detail.ProductId);
                        body += $@"
                <tr>
                    <td>{product?.Name}</td>
                    <td>{detail.Quantity}</td>
                    <td>{detail.OriginalPrice:N0}đ</td>   <!-- 🟩 THÊM MỚI -->
                    <td>{detail.DiscountedPrice:N0}đ</td> <!-- 🟩 THÊM MỚI -->
                    <td>{(detail.DiscountedPrice * detail.Quantity):N0}đ</td>
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
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateQuantity([FromBody] UpdateQuantityRequest request)
        {
            // 0) Validate payload
            if (request == null)
                return BadRequest(new { success = false, message = "Dữ liệu yêu cầu không hợp lệ." });

            var cartItemId = request.CartItemId;
            var quantity = request.Quantity;

            // 1) Auth
            if (!User.Identity.IsAuthenticated)
                return Unauthorized(new { success = false, message = "Người dùng chưa đăng nhập." });

            var userId = _userManager.GetUserId(User);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { success = false, message = "Người dùng chưa đăng nhập." });

            // 2) Chuẩn hoá input
            if (quantity < 0) quantity = 1;

            // 3) Lấy cart item (kèm Product để có tên/giá)
            var cartItem = await _context.CartItems
                .Include(ci => ci.Product)
                .FirstOrDefaultAsync(ci => ci.Id == cartItemId && ci.UserId == userId);

            if (cartItem == null)
                return NotFound(new { success = false, message = "Không tìm thấy sản phẩm trong giỏ hàng." });

            // 4) Nếu yêu cầu về 0 => xoá item
            if (quantity == 0)
            {
                _context.CartItems.Remove(cartItem);
                await _context.SaveChangesAsync();

                var allCartItemsAfterRemove = await _context.CartItems
                    .Where(ci => ci.UserId == userId)
                    .Include(ci => ci.Product)
                    .ToListAsync();

                decimal cartOverallTotalAfterRemove = allCartItemsAfterRemove.Sum(ci =>
                    (ci.Product?.PriceReduced.HasValue == true && ci.Product.PriceReduced > 0
                        ? ci.Product.PriceReduced.Value
                        : ci.Product!.Price) * ci.Quantity);

                return Json(new
                {
                    success = true,
                    action = "removed",
                    itemId = cartItem.Id,
                    cartOverallTotal = cartOverallTotalAfterRemove.ToString("N0") + "đ"
                });
            }

            // 5) Tính tồn khả dụng đúng ngữ cảnh (biến thể hoặc sản phẩm)
            int available;
            if (cartItem.VariantId.HasValue)
                available = await _inventory.GetAvailableVariantAsync(cartItem.VariantId.Value);
            else
                available = await _inventory.GetAvailableAsync(cartItem.ProductId);

            available = Math.Max(0, available);

            if (quantity > available)
            {
                var nameForMsg = !string.IsNullOrEmpty(cartItem.SelectedVariantName)
                    ? $"{cartItem.Product?.Name} - {cartItem.SelectedVariantName}"
                    : (cartItem.Product?.Name ?? "Sản phẩm");

                return Json(new
                {
                    success = false,
                    message = $"Sản phẩm '{nameForMsg}' chỉ còn {available} cái trong kho."
                });
            }

            // 6) Cập nhật số lượng
            cartItem.Quantity = quantity;

            try
            {
                await _context.SaveChangesAsync();

                // 7) Tính lại giá dòng và tổng giỏ
                var unitPrice = (cartItem.Product!.PriceReduced.HasValue && cartItem.Product.PriceReduced > 0)
                    ? cartItem.Product.PriceReduced.Value
                    : cartItem.Product.Price;

                var itemTotalPrice = unitPrice * cartItem.Quantity;

                var allCartItems = await _context.CartItems
                    .Where(ci => ci.UserId == userId)
                    .Include(ci => ci.Product)
                    .ToListAsync();

                decimal cartOverallTotal = allCartItems.Sum(ci =>
                    (ci.Product?.PriceReduced.HasValue == true && ci.Product.PriceReduced > 0
                        ? ci.Product.PriceReduced.Value
                        : ci.Product!.Price) * ci.Quantity);

                return Json(new
                {
                    success = true,
                    message = "Cập nhật số lượng thành công.",
                    itemId = cartItem.Id,
                    newQuantity = cartItem.Quantity,
                    itemTotalPrice = itemTotalPrice.ToString("N0") + "đ",
                    cartOverallTotal = cartOverallTotal.ToString("N0") + "đ"
                });
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