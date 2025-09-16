using DoAnCoSo.Controllers;
using DoAnCoSo.Models;
using DoAnCoSo.Repositories;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Microsoft.VisualStudio.Web.CodeGenerators.Mvc.Templates.Blazor;
using Newtonsoft.Json;
using System.Security.Claims;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = SD.Role_Admin)]
    public class ProductController : Controller
    {
        private readonly IProductRepository _productRepository;
        private readonly ICategoryRepository _categoryRepository;
        private readonly ILogger<HomeController> _logger;
        //private readonly ApplicationDbContext _context;
        public ProductController(ILogger<HomeController> logger, IProductRepository productRepository, ICategoryRepository categoryRepository)
        {
            _productRepository = productRepository;
            _categoryRepository = categoryRepository;
            _logger = logger;
        }

        // Hiển thị danh sách sản phẩm
        public async Task<IActionResult> Index()
        {
            var products = await _productRepository.GetAllAsync();
            return View(products);
        }

        // Hiển thị form thêm sản phẩm mới
        public async Task<IActionResult> Add()
        {
            var categories = await _categoryRepository.GetAllAsync();
            ViewBag.Categories = new SelectList(categories, "Id", "Name");
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Add(Product product, IFormFile imageUrl, List<IFormFile> images, List<string> flavorsList)
        {
            if (ModelState.IsValid)
            {
                // ✅ Xử lý hương vị (Flavors)
                product.Flavors = flavorsList != null && flavorsList.Count > 0
                                  ? string.Join(", ", flavorsList.Where(f => !string.IsNullOrWhiteSpace(f)))
                                  : null;

                // ✅ Xử lý giá giảm (PriceReduced)
                if (product.PriceReduced == null || product.PriceReduced <= 0 || product.PriceReduced >= product.Price)
                {
                    product.PriceReduced = null; // Không hiển thị giá giảm nếu không hợp lệ
                }

                // ✅ Xử lý ảnh chính (Product Image)
                if (imageUrl != null)
                {
                    product.ImageUrl = await SaveImage(imageUrl);
                }

                // ✅ Xử lý danh sách ảnh bổ sung (Additional Images)
                if (images != null && images.Count > 0)
                {
                    product.Images = new List<ProductImage>();
                    foreach (var image in images)
                    {
                        var imageUrlPath = await SaveImage(image);
                        product.Images.Add(new ProductImage { Url = imageUrlPath });
                    }
                }

                await _productRepository.AddAsync(product);
                return RedirectToAction(nameof(Index));
            }

            var categories = await _categoryRepository.GetAllAsync();
            ViewBag.Categories = new SelectList(categories, "Id", "Name");
            return View(product);
        }


        private async Task<string> SaveImage(IFormFile image)
        {
            //Thay đổi đường dẫn theo cấu hình của bạn
            var savePath = Path.Combine("wwwroot/images", image.FileName);
            using (var fileStream = new FileStream(savePath, FileMode.Create))
            {
                await image.CopyToAsync(fileStream);
            }
            return "/images/" + image.FileName; // Trả về đường dẫn tương đối
        }

        // Hiển thị thông tin chi tiết sản phẩm
        public async Task<IActionResult> Display(int id)
        {
            var product = await _productRepository.GetByIdAsync(id);
            if (product == null)
            {
                return NotFound();
            }
            return View(product);
        }

        // Hiển thị form cập nhật sản phẩm
        public async Task<IActionResult> Update(int id)
        {
            var product = await _productRepository.GetByIdAsync(id);
            if (product == null)
            {
                return NotFound();
            }
            var categories = await _categoryRepository.GetAllAsync();
            ViewBag.Categories = new SelectList(categories, "Id", "Name",
           product.CategoryId);
            return View(product);
        }

        [HttpPost]
        public async Task<IActionResult> Update(int id, Product product, IFormFile imageUrl, List<string>? flavorsList)
        {
            // Ghi log để kiểm tra giá trị nhận được từ form
            Console.WriteLine("Received Flavors List:");
            if (flavorsList != null && flavorsList.Any())
            {
                foreach (var flavor in flavorsList)
                {
                    Console.WriteLine($"Flavor: {flavor}");
                }
            }
            else
            {
                Console.WriteLine("Flavors List is EMPTY or NULL");
            }

            ModelState.Remove("ImageUrl"); // Loại bỏ xác thực ModelState cho ImageUrl

            if (id != product.Id)
            {
                return NotFound();
            }

            if (ModelState.IsValid)
            {
                var existingProduct = await _productRepository.GetByIdAsync(id);
                if (existingProduct == null)
                {
                    return NotFound();
                }

                // ✅ Cập nhật ảnh nếu có
                if (imageUrl != null && imageUrl.Length > 0)
                {
                    var savedImageUrl = await SaveImage(imageUrl);
                    if (!string.IsNullOrEmpty(savedImageUrl))
                    {
                        existingProduct.ImageUrl = savedImageUrl;
                    }
                    else
                    {
                        ModelState.AddModelError("ImageUrl", "Lỗi khi lưu ảnh.");
                        return View(product);
                    }
                }

                // ✅ Cập nhật thông tin sản phẩm
                existingProduct.Name = product.Name;
                existingProduct.Price = product.Price;
                existingProduct.PriceReduced = product.PriceReduced;
                existingProduct.Trademark = product.Trademark;
                existingProduct.Description = product.Description;
                existingProduct.CategoryId = product.CategoryId;

                // ✅ Cập nhật Flavors (Hương vị)
                existingProduct.Flavors = flavorsList != null && flavorsList.Any()
                    ? string.Join(", ", flavorsList.Where(f => !string.IsNullOrWhiteSpace(f)))
                    : ""; // Xóa nếu không có hương vị mới

                // ✅ Ghi log để kiểm tra dữ liệu trước khi lưu
                Console.WriteLine($"Updating Product ID: {existingProduct.Id}");
                Console.WriteLine($"Updated Flavors: {existingProduct.Flavors}");

                // ✅ Lưu thay đổi vào database
                await _productRepository.UpdateAsync(existingProduct);

                return RedirectToAction(nameof(Index));
            }

            // ✅ Nếu có lỗi, hiển thị danh sách danh mục
            var categories = await _categoryRepository.GetAllAsync();
            ViewBag.Categories = new SelectList(categories, "Id", "Name");

            return View(product);
        }


        // Hiển thị form xác nhận xóa sản phẩm
        public async Task<IActionResult> Delete(int id)
        {
            var product = await _productRepository.GetByIdAsync(id);
            if (product == null)
            {
                return NotFound();
            }
            return View(product);
        }

        // Xử lý xóa sản phẩm
        [HttpPost, ActionName("DeleteConfirmed")]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            await _productRepository.DeleteAsync(id);
            return RedirectToAction(nameof(Index));
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
    }
}