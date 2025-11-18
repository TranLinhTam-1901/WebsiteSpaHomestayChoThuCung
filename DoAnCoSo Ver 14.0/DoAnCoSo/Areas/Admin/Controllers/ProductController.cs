using DoAnCoSo.Models;
using DoAnCoSo.Repositories;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
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
        private readonly UserManager<ApplicationUser> _userManager;

        public ProductController(
            ILogger<ProductController> logger,
            IProductRepository productRepository,
            ICategoryRepository categoryRepository,
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager)
        {
            _logger = logger;
            _productRepository = productRepository;
            _categoryRepository = categoryRepository;
            _context = context;
            _userManager = userManager;
        }

        #region CRUD (Admin)

        public async Task<IActionResult> Index(bool showDeleted = false)
        {
            var products = await _productRepository.GetAllAsync();
            products = showDeleted
                ? products.OrderByDescending(p => p.Id).ToList()
                : products.Where(p => !p.IsDeleted).OrderByDescending(p => p.Id).ToList();

            ViewBag.ShowDeleted = showDeleted;
            return View(products);
        }
        public async Task<IActionResult> Add()
        {
            await PopulateCategoriesDropdown();
            // ✅ Mặc định không dùng biến thể khi mở trang
            ViewBag.HasVariants = false;
            ViewBag.VariantNames = new List<string>();
            ViewBag.VariantStocks = new List<int>();
            ViewBag.VariantThresholds = new List<int>();
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Add(
        Product product,
        IFormFile? imageUrl,
        List<IFormFile>? images,
        List<string>? flavorsList,
        [FromForm] bool? HasVariants,
        [FromForm] List<string>? OptionGroupNames,
        [FromForm] List<List<string>>? OptionGroupValues,
        [FromForm] List<string>? VariantGeneratedNames,
        [FromForm] List<int>? VariantGeneratedStocks,
        [FromForm] List<int>? VariantGeneratedThresholds)        
        {
            var useVariants = HasVariants == true;

            // NEW (optional): mặc định active nếu form không gửi IsActive
            if (!Request.Form.ContainsKey("IsActive"))
                product.IsActive = true;

            // Nếu dùng biến thể: bỏ validate tồn tổng, set về 0 (sẽ tính lại từ variants)
            if (useVariants)
            {
                ModelState.Remove(nameof(Product.StockQuantity));
                product.StockQuantity = 0;
            }

            // Chuẩn bị ViewBag để khi trả về View vẫn giữ trạng thái đã nhập
            async Task PrepViewBags()
            {
                await PopulateCategoriesDropdown();
                ViewBag.HasVariants = useVariants;
                ViewBag.VariantGeneratedNames = VariantGeneratedNames ?? new List<string>();
                ViewBag.VariantGeneratedStocks = VariantGeneratedStocks ?? new List<int>();
                ViewBag.VariantGeneratedThresholds = VariantGeneratedThresholds ?? new List<int>();

            }

            if (!ModelState.IsValid)
            {
                await PrepViewBags();
                return View(product);
            }

            // Xử lý giá giảm như luồng hiện tại của bạn
            ProcessPriceReduced(product);

            // ============= NHÁNH KHÔNG CÓ BIẾN THỂ (workflow cũ) =============
            if (!useVariants)
            {
                // Hương vị dạng chuỗi như cũ (nếu bạn đang dùng)
                ProcessFlavors(product, flavorsList);

                // Ảnh đại diện & ảnh phụ
                if (imageUrl != null) product.ImageUrl = await SaveImage(imageUrl);
                if (images != null && images.Any()) await ProcessAdditionalImages(product, images);

                await _productRepository.AddAsync(product);

                // (Tuỳ chọn) ghi log khởi tạo tồn tổng
                if (product.StockQuantity > 0)
                {
                    _context.InventoryLogs.Add(new InventoryLog
                    {
                        ProductId = product.Id,
                        VariantId = null,
                        QuantityChange = product.StockQuantity,
                        Reason = "InitialImport",
                        ReferenceId = $"Product:{product.Id}",
                        PerformedByUserId = _userManager.GetUserId(User),
                        Note = "Khởi tạo tồn kho (không biến thể)",
                        CreatedAt = DateTime.UtcNow
                    });
                    await _context.SaveChangesAsync();
                }

                TempData["SuccessMessage"] = "Đã thêm sản phẩm.";
                return RedirectToAction(nameof(Index));
            }

            // ============= NHÁNH CÓ BIẾN THỂ =============

            if (VariantGeneratedNames == null || VariantGeneratedNames.Count == 0)
                 {
                ModelState.AddModelError("", "Bạn chưa tạo biến thể!");
                 }
             if (OptionGroupNames == null || OptionGroupNames.Count == 0)
                 {
                ModelState.AddModelError("", "Bạn chưa nhập nhóm biến thể!");
                 }
            if (!ModelState.IsValid)
            {
                await PrepViewBags();
                return View(product);
            }

            // Ảnh
            if (imageUrl != null) product.ImageUrl = await SaveImage(imageUrl);
            if (images != null && images.Any()) await ProcessAdditionalImages(product, images);

            // Nếu cột Flavors đang NOT NULL thì tránh lỗi (vì nhánh biến thể không dùng cột này)
            product.Flavors ??= string.Empty;

            await using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                // tạo Product trước để lấy Id
                product.StockQuantity = 0;
                product.ReservedQuantity = 0;
                product.SoldQuantity = 0;

                _context.Products.Add(product);
                await _context.SaveChangesAsync(); // cần Id

                // Lưu Option Groups + Option Values
                var groups = new List<ProductOptionGroup>();
                for (int g = 0; g < OptionGroupNames.Count; g++)
                {
                    var group = new ProductOptionGroup
                    {
                        ProductId = product.Id,
                        Name = OptionGroupNames[g]
                    };

                    _context.ProductOptionGroups.Add(group);
                    await _context.SaveChangesAsync();

                    foreach (var val in OptionGroupValues[g].Where(v => !string.IsNullOrWhiteSpace(v)))
                    {
                        _context.ProductOptionValues.Add(new ProductOptionValue
                        {
                            ProductOptionGroupId = group.Id,
                            Value = val.Trim()
                        });
                    }
                }
                await _context.SaveChangesAsync();

                //  Lưu Variants sinh từ UI
                var variants = new List<ProductVariant>();
                int total = 0;

                for (int i = 0; i < VariantGeneratedNames.Count; i++)
                {
                    int stock = Math.Max(0, VariantGeneratedStocks[i]);
                    int threshold = Math.Max(0, VariantGeneratedThresholds[i]);

                    variants.Add(new ProductVariant
                    {
                        ProductId = product.Id,
                        Name = VariantGeneratedNames[i],
                        Sku = $"P{product.Id}-V{i + 1}-{Guid.NewGuid().ToString("N")[..4]}",
                        StockQuantity = stock,
                        LowStockThreshold = threshold,
                        ReservedQuantity = 0,
                        SoldQuantity = 0,
                        IsActive = true,
                        CreatedAt = DateTime.UtcNow
                    });

                    total += stock;
                }

                _context.ProductVariants.AddRange(variants);
                await _context.SaveChangesAsync();

                // ================= Mapping Variant <-> OptionValues ==================
                var optionValues = await _context.ProductOptionValues
                    .Where(v => v.Group.ProductId == product.Id)
                    .Include(v => v.Group)
                    .ToListAsync();

                foreach (var variant in variants)
                {
                    string[] parts = variant.Name.Split(" - ", StringSplitOptions.TrimEntries);

                    for (int i = 0; i < parts.Length; i++)
                    {
                        string groupName = OptionGroupNames[i].Trim();
                        string valueName = parts[i].Trim();

                        var match = optionValues.FirstOrDefault(v =>
                            v.Group.Name.Equals(groupName, StringComparison.OrdinalIgnoreCase) &&
                            v.Value.Equals(valueName, StringComparison.OrdinalIgnoreCase)
                        );

                        if (match != null)
                        {
                            _context.ProductVariantOptionValues.Add(new ProductVariantOptionValue
                            {
                                ProductVariantId = variant.Id,
                                ProductOptionValueId = match.Id
                            });
                        }
                    }
                }
                await _context.SaveChangesAsync();


                // log nhập kho ban đầu cho các biến thể có tồn
                var logs = variants
                    .Where(v => v.StockQuantity > 0)
                    .Select(v => new InventoryLog
                    {
                        ProductId = product.Id,
                        VariantId = v.Id,
                        QuantityChange = v.StockQuantity,
                        Reason = "InitialImport",
                        ReferenceId = $"Product:{product.Id}",
                        PerformedByUserId = _userManager.GetUserId(User),
                        Note = $"Khởi tạo tồn kho biến thể '{v.Name}'",
                        CreatedAt = DateTime.UtcNow
                    })
                    .ToList();

                if (logs.Count > 0)
                {
                    _context.InventoryLogs.AddRange(logs);
                    await _context.SaveChangesAsync();
                }

                // D) cập nhật tồn tổng cho Product để UI cũ không bị phá
                product.StockQuantity = total;
                _context.Products.Update(product);
                await _context.SaveChangesAsync();

                await tx.CommitAsync();

                TempData["SuccessMessage"] = "Đã thêm sản phẩm (có biến thể).";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                await tx.RollbackAsync();
                var root = ex.GetBaseException()?.Message ?? ex.Message;   // 👈 lấy inner
                ModelState.AddModelError("", "Không thể lưu sản phẩm (biến thể): " + root);
                await PrepViewBags();
                return View(product);
            }
        }

        public async Task<IActionResult> Details(int id)
        {
            var product = await _context.Products
                .Include(p => p.Category)
                .Include(p => p.Images)
                .Include(p => p.Variants)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (product == null) return NotFound();

            ViewBag.TotalVariantStock = product.Variants?.Sum(v => v.StockQuantity) ?? 0;
            ViewBag.TotalVariantReserved = product.Variants?.Sum(v => v.ReservedQuantity) ?? 0;
            ViewBag.TotalVariantSold = product.Variants?.Sum(v => v.SoldQuantity) ?? 0;

            var reviews = await _context.Reviews
                .Include(r => r.User)
                .Where(r => r.TargetType == ReviewTargetType.Product && r.TargetId == id)
                .OrderByDescending(r => r.CreatedDate)
                .ToListAsync();

            ViewBag.Reviews = reviews;
            ViewBag.TotalReviews = reviews.Count;
            ViewBag.AverageRating = reviews.Any() ? reviews.Average(r => r.Rating) : 0d;

            return View(product);
        }
        public async Task<IActionResult> Update(int id)
        {
            var product = await _context.Products
            .Include(p => p.Category)

            // 1) Load OptionGroups (Hương vị, Khối lượng...)
            .Include(p => p.OptionGroups)
            .ThenInclude(g => g.Values)

            // 2) Load Variants
            .Include(p => p.Variants)
            .ThenInclude(v => v.OptionValues)
                .ThenInclude(ov => ov.OptionValue)

            // 3) Load hình ảnh
            .Include(p => p.Images)
            .FirstOrDefaultAsync(p => p.Id == id);
            if (product == null) return NotFound();

            await PopulateCategoriesDropdown(product.CategoryId);
            return View(product);
        }

        [HttpPost]     
        public async Task<IActionResult> Update(
        int id,
        Product product,
        IFormFile? imageUrl,
        [FromForm(Name = "images")] List<IFormFile>? newImages,
        List<string>? flavorsList,
        [FromForm] List<int>? VariantIds,
        [FromForm] List<string>? VariantNames,
        [FromForm] List<string>? VariantSkus,
        [FromForm] List<decimal?>? VariantPriceOverrides,
        [FromForm] List<int>? VariantStocks,
        [FromForm] List<int>? DeleteImageIds,
        [FromForm] List<int>? VariantThresholds,
        [FromForm] IFormCollection form)
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

            await _context.Entry(existingProduct)
                  .Collection(p => p.Images)
                  .LoadAsync();

            // === cập nhật fields cơ bản ===
            if (imageUrl != null)
                existingProduct.ImageUrl = await SaveImage(imageUrl);


            if (DeleteImageIds != null && DeleteImageIds.Any())
            {
                var toDelete = existingProduct.Images
                    .Where(img => DeleteImageIds.Contains(img.Id))
                    .ToList();

                foreach (var img in toDelete)
                {
                   
                    _context.Set<ProductImage>().Remove(img);
                }

            }
            if (newImages != null && newImages.Any())
            {
                foreach (var file in newImages)
                {
                    if (file == null || file.Length == 0) continue;

                    var url = await SaveImage(file);

                    existingProduct.Images.Add(new ProductImage
                    {
                        ProductId = existingProduct.Id,
                        Url = url
                    });
                }
            }

            existingProduct.Name = product.Name;
            existingProduct.Price = product.Price;
            existingProduct.PriceReduced = product.PriceReduced;
            existingProduct.Trademark = product.Trademark;
            existingProduct.Description = product.Description;
            existingProduct.CategoryId = product.CategoryId;
            existingProduct.LowStockThreshold = product.LowStockThreshold;
            // NEW: cập nhật trạng thái bán/tạm dừng
            existingProduct.IsActive = product.IsActive;


            // Nếu đã có biến thể thì bỏ hương vị dạng chuỗi cho nhất quán UI
            await _context.Entry(existingProduct).Collection(p => p.Variants).LoadAsync();
            if (existingProduct.Variants != null && existingProduct.Variants.Any())
            {
                existingProduct.Flavors = null;
            }
            else
            {
                ProcessFlavors(existingProduct, flavorsList);
            }
            ProcessPriceReduced(existingProduct);


            // === đồng bộ biến thể ===
            VariantIds ??= new(); VariantNames ??= new(); VariantSkus ??= new();
            VariantPriceOverrides ??= new(); VariantStocks ??= new(); VariantThresholds ??= new();

            // KHÔNG tính theo checkbox để tránh rớt index
            int n = new[]
            {
            VariantIds.Count, VariantNames.Count, VariantSkus.Count,
            VariantPriceOverrides.Count, VariantStocks.Count, VariantThresholds.Count
            }.Min();

            await _context.Entry(existingProduct).Collection(p => p.Variants).LoadAsync();
            var byId = existingProduct.Variants.ToDictionary(v => v.Id);
            var seen = new HashSet<int>();

            await using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                for (int i = 0; i < n; i++)
                {
                    int vid = VariantIds[i];
                    string name = (VariantNames[i] ?? "").Trim();
                    string sku = (VariantSkus[i] ?? "").Trim();
                    int stock = Math.Max(0, VariantStocks[i]);
                    int threshold = Math.Max(0, VariantThresholds[i]);
                    decimal? priceOverride = VariantPriceOverrides[i];

                    // ⬇️ lấy giá trị cuối cùng của checkbox (hidden "false" + checkbox "true" nếu được tích)
                    var raw = form[$"VariantIsActives[{i}]"]; // ["false"] hoặc ["false","true"]
                    bool isActive = raw.Count > 0 &&
                                    string.Equals(raw[raw.Count - 1], "true", StringComparison.OrdinalIgnoreCase);

                    if (string.IsNullOrWhiteSpace(name)) continue;

                    if (vid > 0 && byId.TryGetValue(vid, out var v))
                    {
                        seen.Add(vid);

                        int delta = stock - v.StockQuantity;

                        v.Name = name;
                        v.Sku = string.IsNullOrWhiteSpace(sku)
                            ? (string.IsNullOrWhiteSpace(v.Sku)
                                ? $"P{existingProduct.Id}-V{vid}-{Guid.NewGuid().ToString("N")[..4]}"
                                : v.Sku)
                            : sku; // đảm bảo không null

                        v.PriceOverride = priceOverride;
                        v.LowStockThreshold = threshold;
                        v.IsActive = isActive;

                        if (delta != 0)
                        {
                            v.StockQuantity += delta;

                            _context.InventoryLogs.Add(new InventoryLog
                            {
                                ProductId = existingProduct.Id,
                                VariantId = v.Id,
                                QuantityChange = delta,
                                Reason = delta > 0 ? "ManualImport" : "ManualExport",
                                ReferenceId = $"Product:{existingProduct.Id}",
                                PerformedByUserId = _userManager.GetUserId(User),
                                Note = "Điều chỉnh tồn ở màn Update sản phẩm",
                                CreatedAt = DateTime.UtcNow
                            });
                        }
                    }
                    else
                    {
                        var nv = new ProductVariant
                        {
                            ProductId = existingProduct.Id,
                            Name = name,
                            Sku = string.IsNullOrWhiteSpace(sku)
                                ? $"P{existingProduct.Id}-V{existingProduct.Variants.Count + 1}-{Guid.NewGuid().ToString("N")[..4]}"
                                : sku,
                            PriceOverride = priceOverride,
                            StockQuantity = stock,
                            ReservedQuantity = 0,
                            SoldQuantity = 0,
                            LowStockThreshold = threshold,
                            IsActive = isActive,
                            CreatedAt = DateTime.UtcNow
                        };
                        _context.ProductVariants.Add(nv);
                        await _context.SaveChangesAsync(); // cần Id để log

                        if (stock > 0)
                        {
                            _context.InventoryLogs.Add(new InventoryLog
                            {
                                ProductId = existingProduct.Id,
                                VariantId = nv.Id,
                                QuantityChange = stock,
                                Reason = "InitialImport",
                                ReferenceId = $"Product:{existingProduct.Id}",
                                PerformedByUserId = _userManager.GetUserId(User),
                                Note = "Khởi tạo tồn kho biến thể (thêm mới ở Update)",
                                CreatedAt = DateTime.UtcNow
                            });
                        }
                    }
                }

                // Biến thể không xuất hiện trong form → ngừng hoạt động (không xoá)
                foreach (var v in existingProduct.Variants)
                    if (!seen.Contains(v.Id))
                        v.IsActive = false;

                // ✅ CHỈ khi có biến thể thì mới ghi đè tồn kho
                if (existingProduct.Variants != null && existingProduct.Variants.Any())
                {
                    existingProduct.StockQuantity = existingProduct.Variants
                        .Where(v => v.IsActive)
                        .Sum(v => v.StockQuantity);
                }

                await _context.SaveChangesAsync();
                await tx.CommitAsync();
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }

            return RedirectToAction(nameof(Index));
        }



        //public async Task<IActionResult> Delete(int id)
        //{
        //    var product = await _productRepository.GetByIdAsync(id);
        //    if (product == null) return NotFound();
        //    return View(product);
        //}

        //[HttpPost, ActionName("DeleteConfirmed")]
        //public async Task<IActionResult> DeleteConfirmed(int id)
        //{
        //    var product = await _context.Products
        //       .Include(p => p.Variants)
        //       .FirstOrDefaultAsync(p => p.Id == id);

        //    if (product == null) return NotFound();

        //    // chuyển sang ẩn mềm
        //    product.IsDeleted = true;
        //    product.IsActive = false;
        //    product.DeletedAt = DateTime.UtcNow;
        //    product.DeletedBy = _userManager.GetUserId(User);
        //    product.DeletedReason = string.IsNullOrWhiteSpace(product.DeletedReason)
        //        ? "Ẩn bởi Admin"
        //        : product.DeletedReason;

        //    // tắt toàn bộ biến thể để ngăn AddToCart/BuyNow
        //    if (product.Variants != null)
        //    {
        //        foreach (var v in product.Variants)
        //            v.IsActive = false;
        //    }

        //    await _context.SaveChangesAsync();
        //    TempData["SuccessMessage"] = $"Đã ẩn sản phẩm #{product.Id} - {product.Name}.";
        //    return RedirectToAction(nameof(Index));
        //}

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Hide(int id)
        {
            var p = await _context.Products.FirstOrDefaultAsync(x => x.Id == id);
            if (p == null) return Json(new { success = false, message = "Không tìm thấy sản phẩm." });

            // Soft-hide
            p.IsDeleted = true;
            p.IsActive = false;
            await _context.SaveChangesAsync();

            return Json(new { success = true });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Unhide(int id)
        {
            var p = await _context.Products.FirstOrDefaultAsync(x => x.Id == id);
            if (p == null) return Json(new { success = false, message = "Không tìm thấy sản phẩm." });

            p.IsDeleted = false;
            p.IsActive = true;
            await _context.SaveChangesAsync();

            return Json(new { success = true });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Restore(int id)
        {
            var p = await _context.Products
         .Include(x => x.Variants)
         .FirstOrDefaultAsync(x => x.Id == id);

            if (p == null) return Json(new { success = false, message = "Không tìm thấy sản phẩm." });

            p.IsDeleted = false;
            p.IsActive = true;       // ← ĐANG BÁN
            p.DeletedAt = null;
            p.DeletedBy = null;

            if (p.Variants != null)
                foreach (var v in p.Variants) v.IsActive = true;

            await _context.SaveChangesAsync();
            return Json(new { success = true });
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
