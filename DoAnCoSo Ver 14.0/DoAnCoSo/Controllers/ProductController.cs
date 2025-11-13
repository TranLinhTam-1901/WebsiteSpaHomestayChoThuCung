using DoAnCoSo.DTO;
using DoAnCoSo.Extensions;
using DoAnCoSo.Models;
using DoAnCoSo.Repositories;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Text.Json;

namespace DoAnCoSo.Controllers
{
    public class ProductController : Controller
    {
        private readonly IProductRepository _productRepository;
        private readonly ILogger<ProductController> _logger;
        private readonly ICategoryRepository _categoryRepository;
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _webHostEnvironment;
        private readonly UserManager<ApplicationUser> _userManager;
        public ProductController(ILogger<ProductController> logger, IProductRepository productRepository, ICategoryRepository categoryRepository,
            ApplicationDbContext context, IWebHostEnvironment webHostEnvironment, UserManager<ApplicationUser> userManager)
        {
            _logger = logger;
            _productRepository = productRepository;
            _categoryRepository = categoryRepository;
            _context = context;
            _webHostEnvironment = webHostEnvironment;
            _userManager = userManager;
        }

        public IActionResult AllProducts(string? promoCode)
        {
            var products = _context.Products
             .Where(p => p.IsActive && !p.IsDeleted)   // nếu chưa có IsDeleted thì bỏ điều kiện này
             .AsQueryable();

            products = products.Where(p => !p.IsDeleted && p.IsActive);


            // 🟢 Nếu có promoCode được truyền vào
            if (!string.IsNullOrEmpty(promoCode))
            {
                var promo = _context.Promotions
                    .FirstOrDefault(p => p.Code == promoCode && p.IsActive);

                if (promo != null)
                {
                    // ⚙️ Gợi ý 1: lọc sản phẩm theo giá trị tối thiểu
                    if (promo.MinOrderValue.HasValue)
                        products = products.Where(p => p.Price >= promo.MinOrderValue.Value);

                    // ⚙️ (Tuỳ chọn mở rộng)
                    // Nếu bạn có bảng PromotionCategory → lọc theo CategoryId

                    ViewBag.AppliedPromo = promo;
                }
                else
                {
                    TempData["Error"] = "❌ Mã khuyến mãi không hợp lệ hoặc đã hết hạn.";
                }
            }

            var productList = products.ToList();

            // Giữ phần yêu thích cũ của bạn
            var json = HttpContext.Session.GetString("FavoriteProducts");
            List<int> favoriteIds = string.IsNullOrEmpty(json)
                ? new List<int>()
                : JsonSerializer.Deserialize<List<int>>(json);

            ViewBag.FavoriteIds = favoriteIds;

            return View(productList);
        }

        // Giả sử bạn lưu trữ danh sách yêu thích trong session
        public List<int> GetFavoriteIdsForUser(string userId)
        {
            var favoriteIds = HttpContext.Session.GetObjectFromJson<List<int>>("FavoriteIds");

            if (favoriteIds == null)
            {
                favoriteIds = new List<int>();
            }

            return favoriteIds;
        }

        public void UpdateFavoriteIdsForUser(string userId, List<int> favoriteIds)
        {
            HttpContext.Session.SetObjectAsJson("FavoriteIds", favoriteIds);
        }

        [HttpPost]
        public IActionResult Toggle([FromBody] FavoriteToggleRequest request)
        {
            if (User.Identity.IsAuthenticated)
            {
                var userId = User.Identity.Name; // Hoặc lấy userId từ thông tin người dùng
                var productId = request.Id;

                var favoriteIds = GetFavoriteIdsForUser(userId); // Lấy danh sách yêu thích

                if (favoriteIds.Contains(productId))
                {
                    favoriteIds.Remove(productId); // Nếu đã yêu thích thì bỏ yêu thích
                }
                else
                {
                    favoriteIds.Add(productId); // Nếu chưa yêu thích thì thêm vào
                }

                // Cập nhật danh sách yêu thích trong session
                UpdateFavoriteIdsForUser(userId, favoriteIds);

                return Json(new { success = true });
            }

            return Json(new { success = false, message = "Bạn cần đăng nhập để sử dụng chức năng này." });
        }

        public async Task<IActionResult> Details(int id)
        {
            var product = await _productRepository.GetProductWithReviewsAndImagesAsync(id);
            if (product == null)
            {
                return NotFound();
            }

            // Lấy review kèm User (để hiển thị tên)
            var productReviews = await _context.Reviews
                .Include(r => r.User)
                .Include(r => r.Images)
                .Where(r => r.TargetType == ReviewTargetType.Product && r.TargetId == id)
                .OrderByDescending(r => r.CreatedDate)
                .ToListAsync();

            var viewModel = new ProductDetailViewModel
            {
                Product = product,
                Reviews = productReviews,
                NewReview = new Review
                {
                    TargetType = ReviewTargetType.Product,
                    TargetId = id,
                    UserId = User.Identity.IsAuthenticated
                        ? User.FindFirstValue(ClaimTypes.NameIdentifier)
                        : null
                },
                AverageRating = productReviews.Any() ? productReviews.Average(r => r.Rating) : 0,
                TotalReviews = productReviews.Count
            };

            return View(viewModel);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> AddReview(Review newReview, IEnumerable<IFormFile> reviewImages)
        {
            // 1) Yêu cầu đăng nhập
            var user = await _userManager.GetUserAsync(User);
            if (user == null)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            // 2) Gán thông tin bắt buộc
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
            {
                TempData["ErrorMessage"] = "Không xác định được người dùng.";
                return RedirectToAction("Details", new { id = newReview.TargetId });
            }

            newReview.UserId = userId;
            newReview.TargetType = ReviewTargetType.Product; // bạn đang review sản phẩm
            newReview.CreatedDate = DateTime.Now;

            // 3) Khởi tạo collection ảnh nếu null
            newReview.Images ??= new List<ReviewImage>();

            // 4) Upload ảnh (nếu có)
            if (reviewImages != null)
            {
                var uploadsDir = Path.Combine(_webHostEnvironment.WebRootPath, "images", "reviews");
                if (!Directory.Exists(uploadsDir))
                    Directory.CreateDirectory(uploadsDir);

                foreach (var file in reviewImages.Where(f => f?.Length > 0))
                {
                    // (tuỳ ý) kiểm tra mime/size ở đây
                    var fileName = $"{Guid.NewGuid()}_{Path.GetFileName(file.FileName)}";
                    var filePath = Path.Combine(uploadsDir, fileName);

                    using (var fs = new FileStream(filePath, FileMode.Create))
                        await file.CopyToAsync(fs);

                    // THAY ProductReviewImage -> ReviewImage
                    newReview.Images.Add(new ReviewImage
                    {
                        ImageUrl = $"/images/reviews/{fileName}"
                        // nếu model có các field khác (Caption, SortOrder...) thì set thêm
                    });
                }
            }

            // 5) Lưu DB: THAY _context.ProductReviews -> _context.Reviews
            _context.Reviews.Add(newReview);
            await _context.SaveChangesAsync();

            TempData["SuccessMessage"] = "Bình luận đã được gửi.";
            return RedirectToAction("Details", new { id = newReview.TargetId });
        }


        public IActionResult Search(string searchTerm)
        {
            if (string.IsNullOrEmpty(searchTerm))
            {
                return View("AllProducts", _context.Products.ToList());
            }

            var lowerSearchTerm = searchTerm.ToLower();

            var joinedResultsInMemory = _context.Products
                .Join(
                    _context.Categories, // Bảng Categories
                    product => product.CategoryId, // Khóa ngoại trong bảng Products
                    category => category.Id, // Khóa chính trong bảng Categories
                    (product, category) => new { Product = product, Category = category } // Tạo đối tượng tạm thời
                )
                .AsEnumerable() // <-- Chuyển sang LINQ to Objects (xử lý trên bộ nhớ)
                .ToList(); // <-- Thực thi truy vấn Join và lấy dữ liệu vào List trong bộ nhớ

            // Bước 2: Áp dụng các điều kiện lọc (bao gồm cả điều kiện phức tạp) trên bộ nhớ
            var searchResults = joinedResultsInMemory
                .Where(joinResult =>
                    (joinResult.Product.Name != null && joinResult.Product.Name.ToLower().Contains(lowerSearchTerm)) ||
                    (joinResult.Product.Trademark != null && joinResult.Product.Trademark.ToLower().Contains(lowerSearchTerm)) ||
                    (joinResult.Category != null && joinResult.Category.Name != null && joinResult.Category.Name.ToLower().Contains(lowerSearchTerm)) ||
                    (joinResult.Category != null && joinResult.Category.Name != null &&
                     joinResult.Category.Name.ToLower() // Lấy tên category về chữ thường
                         .Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries) // Tách tên category thành các từ (trong bộ nhớ)
                         .All(categoryWord => lowerSearchTerm.Contains(categoryWord)) // Kiểm tra xem TẤT CẢ các từ của category có nằm trong từ khóa tìm kiếm không (trong bộ nhớ)
                    )
                )

                .Select(joinResult => joinResult.Product)
                .Distinct()
                .ToList(); // Chuyển kết quả cuối cùng thành danh sách

            return View("AllProducts", searchResults);
        }

        public async Task<IActionResult> ProductsByCategory(string categoryName) // Nhận tên danh mục từ URL
        {
            if (string.IsNullOrEmpty(categoryName))
            {
                return RedirectToAction("AllProducts");
            }

            var products = await _productRepository.GetProductsByCategoryAsync(categoryName);

            return View("AllProducts", products);
        }
    }
}
