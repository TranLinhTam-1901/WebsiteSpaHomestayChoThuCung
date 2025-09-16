using System.Diagnostics;
using DoAnCoSo.Models;
using DoAnCoSo.Repositories;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using System.Linq;
using DoAnCoSo.ViewModels;
using System.Security.Claims;

namespace DoAnCoSo.Controllers
{
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

        public IActionResult Index()
        {
            // Nếu chưa có dữ liệu trong session thì random, ngược lại thì lấy ra
            var catJson = HttpContext.Session.GetString("CatProducts");
            var dogJson = HttpContext.Session.GetString("DogProducts");

            List<Product> catProducts;
            List<Product> dogProducts;

            if (catJson == null || dogJson == null)
            {
                // Random 1 lần duy nhất
                int catpateCategoryId = 1; // Pate Mèo
                int dogpateCategoryId = 2; // Pate Chó
                int catCategoryId = 4; // Hạt Mèo
                int dogCategoryId = 5; // Hạt Chó

                // Lấy 5 sản phẩm ngẫu nhiên theo category
                catProducts = _context.Products
                    .Where(p => p.CategoryId == catpateCategoryId || p.CategoryId == catCategoryId)
                    .OrderBy(p => Guid.NewGuid())
                    .Take(5)
                    .ToList();

                dogProducts = _context.Products
                    .Where(p => p.CategoryId == dogpateCategoryId || p.CategoryId == dogCategoryId)
                    .OrderBy(p => Guid.NewGuid())
                    .Take(5)
                    .ToList();

                // Lưu vào session dưới dạng JSON
                HttpContext.Session.SetString("CatProducts", JsonConvert.SerializeObject(catProducts));
                HttpContext.Session.SetString("DogProducts", JsonConvert.SerializeObject(dogProducts));
            }
            else
            {
                // Lấy từ session
                catProducts = JsonConvert.DeserializeObject<List<Product>>(catJson);
                dogProducts = JsonConvert.DeserializeObject<List<Product>>(dogJson);
            }

            var discountedProducts = _context.Products
                .Where(p => p.PriceReduced.HasValue && p.PriceReduced < p.Price)
                .ToList();

            var viewModel = new HomeViewModel
            {
                DiscountedProducts = discountedProducts,
                CatProducts = catProducts,
                DogProducts = dogProducts
            };

            return View(viewModel);
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
    }
}