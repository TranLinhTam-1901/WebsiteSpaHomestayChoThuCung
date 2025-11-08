using DoAnCoSo.Models;
using DoAnCoSo.Repositories;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin")]
    public class ProductController : Controller
    {
        private readonly IProductRepository _productRepository;
        private readonly ICategoryRepository _categoryRepository;
        private readonly ILogger<ProductController> _logger;
        private readonly ApplicationDbContext _context;

        public ProductController(
            ILogger<ProductController> logger,
            IProductRepository productRepository,
            ICategoryRepository categoryRepository,
            ApplicationDbContext context)
        {
            _logger = logger;
            _productRepository = productRepository;
            _categoryRepository = categoryRepository;
            _context = context;
        }

        #region CRUD (Admin)

        public async Task<IActionResult> Index()
        {
            var products = await _productRepository.GetAllAsync();
            return View(products);
        }

        public async Task<IActionResult> Add()
        {
            await PopulateCategoriesDropdown();
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Add(Product product, IFormFile? imageUrl, List<IFormFile>? images, List<string>? flavorsList)
        {
            if (!ModelState.IsValid)
            {
                await PopulateCategoriesDropdown();
                return View(product);
            }

            ProcessFlavors(product, flavorsList);
            ProcessPriceReduced(product);

            if (imageUrl != null)
                product.ImageUrl = await SaveImage(imageUrl);

            if (images != null && images.Any())
                await ProcessAdditionalImages(product, images);

            await _productRepository.AddAsync(product);
            return RedirectToAction(nameof(Index));
        }

        public async Task<IActionResult> Update(int id)
        {
            var product = await _productRepository.GetByIdAsync(id);
            if (product == null) return NotFound();

            await PopulateCategoriesDropdown(product.CategoryId);
            return View(product);
        }

        [HttpPost]
        public async Task<IActionResult> Update(int id, Product product, IFormFile? imageUrl, List<string>? flavorsList)
        {
            ModelState.Remove("ImageUrl");
            if (id != product.Id) return NotFound();

            if (!ModelState.IsValid)
            {
                await PopulateCategoriesDropdown(product.CategoryId);
                return View(product);
            }

            var existingProduct = await _productRepository.GetByIdAsync(id);
            if (existingProduct == null) return NotFound();

            if (imageUrl != null)
                existingProduct.ImageUrl = await SaveImage(imageUrl);

            existingProduct.Name = product.Name;
            existingProduct.Price = product.Price;
            existingProduct.PriceReduced = product.PriceReduced;
            existingProduct.Trademark = product.Trademark;
            existingProduct.Description = product.Description;
            existingProduct.CategoryId = product.CategoryId;
            existingProduct.LowStockThreshold = product.LowStockThreshold;


            ProcessFlavors(existingProduct, flavorsList);
            ProcessPriceReduced(existingProduct);

            await _productRepository.UpdateAsync(existingProduct);
            return RedirectToAction(nameof(Index));
        }

        public async Task<IActionResult> Delete(int id)
        {
            var product = await _productRepository.GetByIdAsync(id);
            if (product == null) return NotFound();
            return View(product);
        }

        [HttpPost, ActionName("DeleteConfirmed")]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            await _productRepository.DeleteAsync(id);
            return RedirectToAction(nameof(Index));
        }

        #endregion

        #region Display + Reviews (Customer)

        public async Task<IActionResult> Display(int id, int currentPage = 1)
        {
            var product = await _context.Products
                .Include(p => p.Images)
                .Include(p => p.Category)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (product == null) return NotFound();

            // Lấy review cho sản phẩm này
            var reviews = await _context.Reviews
                .Include(r => r.User) // để lấy UserName
                .Where(r => r.TargetType == ReviewTargetType.Product && r.TargetId == id)
                .OrderByDescending(r => r.CreatedDate)
                .ToListAsync();

            var vm = new ProductDetailViewModel
            {
                Product = product,
                Reviews = reviews,
                TotalReviews = reviews.Count,
                AverageRating = reviews.Any() ? reviews.Average(r => r.Rating) : 0,

                CurrentPage = currentPage
            };

            return View(vm);
        }

        [HttpPost]
        [Authorize] // bắt buộc đăng nhập mới được review
        public async Task<IActionResult> AddReview(Review newReview)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
            {
                TempData["ErrorMessage"] = "Bạn cần đăng nhập để gửi bình luận.";
                return RedirectToAction("Display", new { id = newReview.TargetId });
            }

            newReview.UserId = userId;
            newReview.TargetType = ReviewTargetType.Product;
            newReview.CreatedDate = DateTime.Now;

            try
            {
                await _productRepository.AddReviewAsync(newReview);
                TempData["SuccessMessage"] = "Bình luận đã được gửi!";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi thêm review cho sản phẩm {ProductId}", newReview.TargetId);
                TempData["ErrorMessage"] = "Lỗi khi gửi bình luận.";
            }

            return RedirectToAction("Display", new { id = newReview.TargetId });
        }

        #endregion

        #region Helpers

        private async Task PopulateCategoriesDropdown(int? selectedId = null)
        {
            var categories = await _categoryRepository.GetAllAsync();
            ViewBag.Categories = new SelectList(categories, "Id", "Name", selectedId);
        }

        private void ProcessFlavors(Product product, List<string>? flavorsList)
        {
            product.Flavors = flavorsList != null && flavorsList.Any()
                ? string.Join(", ", flavorsList.Where(f => !string.IsNullOrWhiteSpace(f)))
                : null;
        }

        private void ProcessPriceReduced(Product product)
        {
            if (product.PriceReduced == null || product.PriceReduced <= 0 || product.PriceReduced >= product.Price)
                product.PriceReduced = null;
        }

        private async Task ProcessAdditionalImages(Product product, List<IFormFile> images)
        {
            product.Images = new List<ProductImage>();
            foreach (var img in images)
            {
                var url = await SaveImage(img);
                product.Images.Add(new ProductImage { Url = url });
            }
        }

        private async Task<string> SaveImage(IFormFile image)
        {
            var fileName = $"{Guid.NewGuid()}{Path.GetExtension(image.FileName)}";
            var savePath = Path.Combine("wwwroot/images", fileName);

            using var stream = new FileStream(savePath, FileMode.Create);
            await image.CopyToAsync(stream);

            return "/images/" + fileName;
        }
        #endregion
    }
}
