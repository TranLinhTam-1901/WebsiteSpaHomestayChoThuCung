using DoAnCoSo.Models;
using DoAnCoSo.Repositories;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Security.Claims;
using Microsoft.Extensions.Primitives;
using DoAnCoSo.ViewModels.VariantPreview;

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
            .AsSplitQuery()
            .Include(p => p.Category)
            .Include(p => p.OptionGroups).ThenInclude(g => g.Values)
            .Include(p => p.Variants).ThenInclude(v => v.OptionValues).ThenInclude(ov => ov.OptionValue)
            .Include(p => p.Images)
            .FirstOrDefaultAsync(p => p.Id == id);

            if (product == null) return NotFound();

            
            product.Variants = product.Variants
                .Where(v => v.IsActive)
                .ToList();

            await PopulateCategoriesDropdown(product.CategoryId);
            return View(product);
        }

        [HttpPost]
        public async Task<IActionResult> Update(
            int id,
            Product product,
            IFormFile? imageUrl,
            [FromForm(Name = "images")] List<IFormFile>? newImages,
            [FromForm] IFormCollection form)
        {
            ModelState.Remove("ImageUrl");

            if (id != product.Id) return NotFound();

            // =============================
            // LOAD PRODUCT
            // =============================
            var existingProduct = await _context.Products
                .Include(p => p.Images)
                .Include(p => p.OptionGroups).ThenInclude(g => g.Values)
                .Include(p => p.Variants).ThenInclude(v => v.OptionValues)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (existingProduct == null)
                return NotFound();

            // =============================
            // UPDATE BASIC FIELDS
            // =============================
            existingProduct.Name = product.Name;
            existingProduct.Price = product.Price;
            existingProduct.PriceReduced = product.PriceReduced;
            existingProduct.Description = product.Description;
            existingProduct.Trademark = product.Trademark;
            existingProduct.CategoryId = product.CategoryId;
            existingProduct.IsActive = product.IsActive;
            existingProduct.LowStockThreshold = product.LowStockThreshold;

            if (imageUrl != null)
                existingProduct.ImageUrl = await SaveImage(imageUrl);

            // DELETE IMAGES
            var deleteImageIds = form["DeleteImageIds"].Select(int.Parse).ToList();
            if (deleteImageIds.Any())
            {
                var imgs = existingProduct.Images.Where(i => deleteImageIds.Contains(i.Id)).ToList();
                _context.ProductImages.RemoveRange(imgs);
            }

            // ADD NEW IMAGES
            if (newImages != null)
            {
                foreach (var f in newImages)
                {
                    if (f.Length > 0)
                    {
                        var url = await SaveImage(f);
                        existingProduct.Images.Add(new ProductImage
                        {
                            ProductId = id,
                            Url = url
                        });
                    }
                }
            }
            // =====================================================================
            // UPDATE HOẶC TẠO MỚI GROUP + VALUE (khớp đúng View hiện tại)
            // =====================================================================
            int g = 0;

            // Lặp cho đến khi không còn tìm thấy khóa OptionGroupIds[g]
             while (form.Keys.Contains($"OptionGroupIds[{g}]"))
            {
                // --- Lấy dữ liệu Group ---
                string groupIdString = form[$"OptionGroupIds[{g}]"].ToString().Trim();
                string gName = form[$"OptionGroupNames[{g}]"].ToString().Trim();

                if (string.IsNullOrWhiteSpace(gName))
                {
                    g++;
                    continue; // Bỏ qua nếu tên Group rỗng
                }

                // --- Xử lý Group (Cũ/Mới) ---
                ProductOptionGroup group;
                int groupId = int.Parse(groupIdString);

                if (groupId > 0)
                {
                    // nhóm cũ
                    group = existingProduct.OptionGroups.First(x => x.Id == groupId);
                    group.Name = gName;
                }
                else
                {
                    // kiểm tra nhóm trùng tên
                    var existed = existingProduct.OptionGroups
                        .FirstOrDefault(x => x.Name.ToLower() == gName.ToLower());

                    if (existed != null)
                    {
                        group = existed;
                    }
                    else
                    {
                        group = new ProductOptionGroup
                        {
                            ProductId = id,
                            Name = gName
                        };
                        _context.ProductOptionGroups.Add(group);
                        await _context.SaveChangesAsync();
                    }
                }


                // --- Xử lý Values bên trong Group ---
                int v = 0;
                // Lặp cho đến khi không còn tìm thấy khóa OptionValueIds[g][v]
                while (form.Keys.Contains($"OptionValueIds[{g}][{v}]"))
                {
                    string valueIdString = form[$"OptionValueIds[{g}][{v}]"].ToString().Trim();
                    string txt = form[$"OptionValueNames[{g}][{v}]"].ToString().Trim();

                    if (!string.IsNullOrWhiteSpace(txt))
                    {
                        int vid = int.Parse(valueIdString);

                        if (vid > 0)
                        {
                            // Value cũ → update
                            var existing = group.Values.First(x => x.Id == vid);
                            existing.Value = txt;
                        }
                        else
                        {
                            // Value mới → tạo và lấy ID
                            var newVal = new ProductOptionValue
                            {
                                ProductOptionGroupId = group.Id,
                                Value = txt
                            };
                            _context.ProductOptionValues.Add(newVal);
                            await _context.SaveChangesAsync(); // Cần SaveChanges để có Value.Id
                        }
                    }
                    v++;
                }           
                g++; 
            }
            await _context.SaveChangesAsync();
            // =====================================================================
            // ĐỌC PREVIEW VARIANT → CHUYỂN TEXT THÀNH ID (LOGIC ĐÃ SỬA)
            // =====================================================================
            List<List<int>> previewCombos = new();

            int row = 0;
            while (true)
            {
                List<int> idList = new();
                int col = 0;
                bool rowHasData = false; // Cờ để kiểm tra xem hàng có dữ liệu hay không

                // Lặp qua CỘT (col) cho HÀNG (row) hiện tại
                while (form.Keys.Contains($"GeneratedVariantValueNames[{row}][{col}]"))
                {
                    // Đọc giá trị tại [row][col]
                    string text = form[$"GeneratedVariantValueNames[{row}][{col}]"].ToString().Trim();

                    if (!string.IsNullOrWhiteSpace(text))
                    {
                        rowHasData = true;

                        // --- LOGIC TÌM KIẾM/TẠO VALUE CŨ CỦA BẠN (vẫn giữ nguyên) ---
                        var exists = await _context.ProductOptionValues
                            .Include(v => v.Group)
                            .FirstOrDefaultAsync(v => v.Group.ProductId == id && v.Value.ToLower() == text.ToLower());

                        int vid;
                        if (exists != null)
                        {
                            vid = exists.Id;
                        }
                        else
                        {
                            // ... (Logic tạo Value mới và SaveChangesAsync) ...
                            var targetGroup = existingProduct.OptionGroups.OrderBy(g => g.Id).ElementAt(col);
                            var newVal = new ProductOptionValue { Value = text, ProductOptionGroupId = targetGroup.Id };
                            _context.ProductOptionValues.Add(newVal);
                            await _context.SaveChangesAsync();
                            vid = newVal.Id;
                        }
                        idList.Add(vid);
                    }
                    col++; // Tăng cột
                }

                if (!rowHasData) break; // Thoát nếu hàng không có dữ liệu

                previewCombos.Add(idList);
                row++;
            }   
            
            //MERGE OPTIONVALUE CU  + MOI 
            // Lấy toàn bộ combos hiện có từ các biến thể cũ
            var oldVariantCombos = existingProduct.Variants
                .Select(v => v.OptionValues
                    .OrderBy(o => o.ProductOptionValueId)
                    .Select(o => o.ProductOptionValueId)
                    .ToList())
                .ToList();

            //Nếu có preview → gộp oldCombos +previewCombos
            if (previewCombos.Count > 0 && oldVariantCombos.Count > 0)
            {
                var merged = new List<List<int>>();

                foreach (var oldCombo in oldVariantCombos)
                {
                    foreach (var newCombo in previewCombos)
                    {
                        var combo = new List<int>();
                        combo.AddRange(oldCombo);
                        combo.AddRange(newCombo);
                        merged.Add(combo);
                    }
                }

                previewCombos = merged;
            }
            
            // =====================================================================
            // XỬ LÝ VARIANT (tạo mới / cập nhật)
            // =====================================================================
            var existingDict = existingProduct.Variants
                .ToDictionary(
                    v => string.Join(",", v.OptionValues.OrderBy(x => x.ProductOptionValueId).Select(x => x.ProductOptionValueId)),
                    v => v
                );

            // HashSet để lưu trữ key (chuỗi ID Value) của tất cả các biến thể hợp lệ (mới tạo HOẶC cũ được cập nhật)
            HashSet<string> validKeys = new();

           
            // XỬ LÝ CÁC BIẾN THỂ TỪ PREVIEW (Tạo mới / Cập nhật)         
            for (int r = 0; r < previewCombos.Count; r++)
            {
                var combo = previewCombos[r].OrderBy(x => x).ToList();
                string key = string.Join(",", combo);

                // Thêm key của các combo được tạo mới hoặc cập nhật vào danh sách hợp lệ
                validKeys.Add(key);

                // Lấy dữ liệu từ bảng Preview mới
                string? stockStr = form[$"GeneratedStocks[{r}]"];
                string? thresholdStr = form[$"GeneratedThresholds[{r}]"];

                int stock = string.IsNullOrWhiteSpace(stockStr) ? 0 : int.Parse(stockStr);
                int threshold = string.IsNullOrWhiteSpace(thresholdStr) ? 0 : int.Parse(thresholdStr);


                if (existingDict.TryGetValue(key, out var variant))
                {
                    // CẬP NHẬT variant CŨ (nếu nó khớp với 1 combo trong Preview)
                    variant.StockQuantity = stock;
                    variant.LowStockThreshold = threshold;
                    variant.IsActive = true;
                    // Note: Không cập nhật PriceOverride ở đây vì Preview không có input PriceOverride
                }
                else
                {
                    // TẠO MỚI VARIANT
                    var newVariant = new ProductVariant
                    {
                        ProductId = id,
                        Sku = $"P{id}-V{Guid.NewGuid().ToString("N")[..5]}",
                        StockQuantity = stock,
                        LowStockThreshold = threshold,
                        PriceOverride = null,
                        CreatedAt = DateTime.UtcNow,
                        IsActive = true
                    };

                    _context.ProductVariants.Add(newVariant);
                    await _context.SaveChangesAsync(); // LƯU để có newVariant.Id

                    // Gắn OptionValues
                    foreach (var vid in combo)
                    {
                        _context.ProductVariantOptionValues.Add(new ProductVariantOptionValue
                        {
                            ProductVariantId = newVariant.Id,
                            ProductOptionValueId = vid
                        });
                    }
                    await _context.SaveChangesAsync();


                    // Build name (Cần Load Options sau khi Save để có dữ liệu Value Text)
                    await _context.Entry(newVariant)
                    .Collection(v => v.OptionValues)
                    .Query()
                    .Include(v => v.OptionValue)   
                    .LoadAsync();

                    newVariant.Name = string.Join(" - ",
                        newVariant.OptionValues
                            .OrderBy(v => v.ProductOptionValueId)
                            .Select(v => v.OptionValue!.Value) // lúc này chắc chắn không null
                    );

                    await _context.SaveChangesAsync();
                }
            }

            // =====================================================================
            // BỔ SUNG LOGIC: CẬP NHẬT VÀ BẢO TỒN BIẾN THỂ CŨ
            // =====================================================================

            //Đọc dữ liệu từ bảng Biến thể hiện có(Existing Variant Body)
            var existingVariantIds = form["VariantIds"].Select(int.Parse).ToList();
            var existingVariantStocks = form["VariantStocks"].Select(int.Parse).ToList();
            var existingVariantThresholds = form["VariantThresholds"].Select(int.Parse).ToList();
            var existingVariantSkus = form["VariantSkus"].ToList();
            var existingVariantPrices = form["VariantPriceOverrides"].ToList();

            for (int i = 0; i < existingVariantIds.Count; i++)
            {
                var variantId = existingVariantIds[i];
                var variantToUpdate = existingProduct.Variants.FirstOrDefault(v => v.Id == variantId);

                if (variantToUpdate != null)
                {
                    // 1. Tạo Key của biến thể cũ (dùng OptionValue ID trong DB)
                    string oldVariantKey = string.Join(",", variantToUpdate.OptionValues
                        .OrderBy(x => x.ProductOptionValueId)
                        .Select(x => x.ProductOptionValueId));

                    // 2. KIỂM TRA: Nếu biến thể cũ này KHÔNG CÓ trong danh sách Preview (validKeys)
                    if (!validKeys.Contains(oldVariantKey))
                    {
                        // Cập nhật các trường có thể chỉnh sửa của biến thể cũ bằng dữ liệu Post từ bảng Existing
                        variantToUpdate.Sku = existingVariantSkus[i];

                        // Xử lý PriceOverride
                        variantToUpdate.PriceOverride = decimal.TryParse(existingVariantPrices[i], out decimal price)
                                                        ? (decimal?)price : null;

                        variantToUpdate.StockQuantity = existingVariantStocks[i];
                        variantToUpdate.LowStockThreshold = existingVariantThresholds[i];


                        bool isActive = form[$"VariantIsActives[{i}]"] == "true";
                        variantToUpdate.IsActive = isActive;

                        // Ngăn biến thể này bị vô hiệu hóa ở bước 4.
                        validKeys.Add(oldVariantKey);
                    }
                }
            }


          

            // =====================================================================
            // UPDATE TỔNG TỒN
            // =====================================================================
            existingProduct.StockQuantity = existingProduct.Variants
                .Where(v => v.IsActive)
                .Sum(v => v.StockQuantity);


            await _context.SaveChangesAsync();

            return RedirectToAction(nameof(Index));
        }
        private List<List<int>> GenerateCartesian(List<List<int>> lists)
        {
            var result = new List<List<int>> { new List<int>() };

            foreach (var list in lists)
            {
                var temp = new List<List<int>>();

                foreach (var r in result)
                    foreach (var item in list)
                        temp.Add(r.Concat(new List<int> { item }).ToList());

                result = temp;
            }

            return result;
        }


        [HttpPost]
        public IActionResult PreviewVariantOptions([FromBody] PreviewOptionRequest req)
        {
            var result = new List<PreviewOptionGroupResult>();

            foreach (var g in req.Groups)
            {
                if (string.IsNullOrWhiteSpace(g.Name)) continue;

                var group = new PreviewOptionGroupResult
                {
                    GroupId = g.GroupId,  // giữ lại ID cũ nếu có
                    Name = g.Name.Trim(),
                    Values = new List<PreviewOptionValueResult>()
                };


                foreach (var v in g.Values)
                {
                    if (string.IsNullOrWhiteSpace(v.Text))
                        continue;

                    group.Values.Add(new PreviewOptionValueResult
                    {
                        Id = v.Id,                 // id cũ nếu có, id = 0 nếu value mới
                        Text = v.Text.Trim()
                    });
                }

                if (group.Values.Any())
                    result.Add(group);
            }

            return Json(result);
        }      


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
