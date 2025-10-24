using DoAnCoSo.Models;
using DoAnCoSo.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = SD.Role_Admin)]
    public class HomeController : Controller
    {

        private readonly IProductRepository _productRepository;
        private readonly ILogger<HomeController> _logger;
        private readonly ICategoryRepository _categoryRepository;
        private readonly ApplicationDbContext _context;


        public HomeController(ILogger<HomeController> logger, IProductRepository productRepository, ICategoryRepository categoryRepository, ApplicationDbContext context)
        {
            _logger = logger;
            _productRepository = productRepository;
            _categoryRepository = categoryRepository;
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            var products = await _productRepository.GetAllAsync();
            return View(products);
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }


        public async Task<IActionResult> Details(int id)
        {
            var product = await _productRepository.GetByIdAsync(id);
            if (product == null)
            {
                return NotFound();
            }
            return View(product);
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
    }
}
