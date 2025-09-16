using System.Security.Claims;
using DoAnCoSo.Models;
using DoAnCoSo.Repositories;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using System.Text.Json;
using DoAnCoSo.Extensions;
using Microsoft.VisualStudio.Web.CodeGenerators.Mvc.Templates.Blazor;

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

        public IActionResult AllProducts()
        {
            var products = _context.Products.ToList();

            var json = HttpContext.Session.GetString("FavoriteProducts");
            List<int> favoriteIds = string.IsNullOrEmpty(json)
                ? new List<int>()
                : JsonSerializer.Deserialize<List<int>>(json);

            ViewBag.FavoriteIds = favoriteIds;

            return View(products);
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

            double averageRating = 0;
            int totalReviews = 0;

            if (product.Reviews != null && product.Reviews.Any())
            {
                averageRating = product.Reviews.Average(r => r.Rating); // Tính điểm trung bình
                totalReviews = product.Reviews.Count(); // Đếm tổng số review
            }

            var viewModel = new ProductDetailViewModel
            {
                Product = product,
                Reviews = product.Reviews != null ? product.Reviews.OrderByDescending(r => r.CreatedDate).ToList() : new List<ProductReview>(),
                NewReview = new ProductReview { ProductId = id },
                AverageRating = averageRating,
                TotalReviews = totalReviews
            };

            // --- LOGIC GÁN USER ID ĐÃ SỬA ---
            if (User.Identity.IsAuthenticated)
            {
                var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);

                if (!string.IsNullOrEmpty(userIdString))
                {

                    viewModel.NewReview.UserId = userIdString;
                }
            }

            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> AddReview(ProductReview NewReview, IEnumerable<IFormFile> reviewImages)
        {
            var user = await _userManager.GetUserAsync(User);
            if (user == null)
            {
                return RedirectToPage("/Account/Login", new { area = "Identity" });
                // Chuyển hướng đến trang đăng nhập
            }
       

            // Lấy User ID an toàn từ Claims của người dùng đã xác thực
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            // Kiểm tra User ID an toàn (nên luôn có nếu [Authorize] hoạt động đúng)
            if (string.IsNullOrEmpty(userIdString))
            {
                // Đây là trường hợp lỗi, nên log lại và báo lỗi chung
                TempData["ErrorMessage"] = "Lỗi xác định người dùng sau đăng nhập.";
                // Log lỗi: User xác thực nhưng không có ClaimTypes.NameIdentifier
                // _logger.LogError("Authenticated user {UserName} does not have NameIdentifier claim.", User.Identity.Name);
                return RedirectToAction("Details", new { id = NewReview.ProductId });
            }
            // Gán User ID an toàn từ claims
            NewReview.UserId = userIdString;


            // Validation
            if (!ModelState.IsValid || NewReview.Rating == 0)
            {
                TempData["ErrorMessage"] = "Dữ liệu bình luận không hợp lệ.";
                // Log lỗi validation
                return RedirectToAction("Details", new { id = NewReview.ProductId });
            }

            NewReview.CreatedDate = DateTime.Now; // Set ngày tạo

            // --- Xử lý Upload File Hình ảnh ---
            if (reviewImages != null && reviewImages.Any())
            {
                var uploadsFolder = Path.Combine(_webHostEnvironment.WebRootPath, "images", "reviews");
                if (!Directory.Exists(uploadsFolder))
                {
                    Directory.CreateDirectory(uploadsFolder);
                }

                foreach (var file in reviewImages)
                {
                    if (file.Length > 0)
                    {
                        // Nên kiểm tra loại file và kích thước ở đây!
                        var uniqueFileName = Guid.NewGuid().ToString() + "_" + Path.GetFileName(file.FileName);
                        var filePath = Path.Combine(uploadsFolder, uniqueFileName);

                        try
                        {
                            using (var fileStream = new FileStream(filePath, FileMode.Create))
                            {
                                await file.CopyToAsync(fileStream);
                            }

                            var reviewImage = new ProductReviewImage { ImageUrl = "/images/reviews/" + uniqueFileName };
                            NewReview.Images.Add(reviewImage);
                        }
                        catch (Exception ex)
                        {
                            // Log lỗi lưu file
                            _logger.LogError(ex, "Lỗi lưu file ảnh bình luận: {FileName}", file.FileName);
                            // Tùy chọn: Bỏ qua file lỗi hoặc báo lỗi toàn bộ submission
                            // TempData["ErrorMessage"] = "Lỗi khi lưu một hoặc nhiều file ảnh.";
                            // return RedirectToAction("Details", new { id = review.ProductId });
                        }
                    }
                }
            }
            // --- Kết thúc Xử lý Upload File Hình ảnh ---


            // --- Lưu vào Database ---
            try
            {
                _context.ProductReviews.Add(NewReview);
                await _context.SaveChangesAsync();

                TempData["SuccessMessage"] = "Bình luận của bạn đã được gửi thành công!";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lưu bình luận sản phẩm ID: {ProductId}", NewReview.ProductId);
                TempData["ErrorMessage"] = "Có lỗi xảy ra khi gửi bình luận. Vui lòng thử lại.";
                // Cần thêm logic xóa file ảnh nếu lưu DB thất bại
            }

            // Chuyển hướng về trang chi tiết sản phẩm
            return RedirectToAction("Details", new { id = NewReview.ProductId });
        }

        public IActionResult Search(string searchTerm)
        {
            if (string.IsNullOrEmpty(searchTerm))
            {
                return View("AllProducts", _context.Products.ToList());
            }

            var lowerSearchTerm = searchTerm.ToLower();

            // Bước 1: Thực hiện Join và lấy dữ liệu vào bộ nhớ (chuyển sang LINQ to Objects)
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
                    // Kiểm tra xem tên sản phẩm CÓ CHỨA từ khóa tìm kiếm không (trong bộ nhớ)
                    (joinResult.Product.Name != null && joinResult.Product.Name.ToLower().Contains(lowerSearchTerm)) ||
                    // HOẶC kiểm tra xem thương hiệu CÓ CHỨA từ khóa tìm kiếm không (trong bộ nhớ)
                    (joinResult.Product.Trademark != null && joinResult.Product.Trademark.ToLower().Contains(lowerSearchTerm)) ||
                    // HOẶC kiểm tra xem tên category CÓ CHỨA từ khóa tìm kiếm không (logic ban đầu, trong bộ nhớ)
                    (joinResult.Category != null && joinResult.Category.Name != null && joinResult.Category.Name.ToLower().Contains(lowerSearchTerm)) ||
                    // HOẶC kiểm tra xem TỪ KHÓA TÌM KIẾM CÓ CHỨA TẤT CẢ các từ của tên category không (logic mới, trong bộ nhớ)
                    (joinResult.Category != null && joinResult.Category.Name != null &&
                     joinResult.Category.Name.ToLower() // Lấy tên category về chữ thường
                         .Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries) // Tách tên category thành các từ (trong bộ nhớ)
                         .All(categoryWord => lowerSearchTerm.Contains(categoryWord)) // Kiểm tra xem TẤT CẢ các từ của category có nằm trong từ khóa tìm kiếm không (trong bộ nhớ)
                    )
                )
                // Chọn lại chỉ đối tượng Product từ kết quả lọc (trong bộ nhớ)
                .Select(joinResult => joinResult.Product)
                // Đảm bảo chỉ lấy các sản phẩm độc nhất (trong bộ nhớ)
                .Distinct()
                .ToList(); // Chuyển kết quả cuối cùng thành danh sách

            // Trả về view AllProducts với danh sách sản phẩm tìm được
            return View("AllProducts", searchResults);
        }

        public async Task<IActionResult> ProductsByCategory(string categoryName) // Nhận tên danh mục từ URL
        {
            // Kiểm tra xem tên danh mục có được truyền vào không
            if (string.IsNullOrEmpty(categoryName))
            {
                // Nếu không có tên danh mục (ví dụ: truy cập /Product/ProductsByCategory mà không có query string),
                // có thể coi đây là lỗi hoặc chuyển hướng về trang tất cả sản phẩm.
                // Chúng ta sẽ chuyển hướng về Action AllProducts.
                return RedirectToAction("AllProducts");
            }

            // Gọi Repository để lấy danh sách sản phẩm theo tên danh mục
            // Đảm bảo phương thức GetProductsByCategoryAsync đã tồn tại và hoạt động đúng trong Repository
            var products = await _productRepository.GetProductsByCategoryAsync(categoryName);

            // --- Trả về View để hiển thị danh sách sản phẩm ---
            // Chúng ta sử dụng lại View "AllProducts.cshtml".
            // Truyền danh sách sản phẩm đã lọc ('products') làm Model cho View đó.
            return View("AllProducts", products);
            // ----------------------------------------------------
        }
    }
}
