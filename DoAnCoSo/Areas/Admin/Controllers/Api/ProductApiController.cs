using DoAnCoSo.Data;
using DoAnCoSo.DTO.Product;
using DoAnCoSo.Models;
using DoAnCoSo.Models.Blockchain;
using DoAnCoSo.Services;
using DoAnCoSo.ViewModels.VariantPreview;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DoAnCoSo.Areas.Admin.Controllers.Api
{
    [Route("api/admin/products")]
    [ApiController]
    [Area("Admin")]
    public class ProductApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _env;

        public ProductApiController(ApplicationDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        // 1. LẤY DANH SÁCH SẢN PHẨM (Có lọc ẩn/hiện)
        [HttpGet]
        public async Task<IActionResult> GetAll(bool showDeleted = false)
        {
            var query = _context.Products
                .Include(p => p.Category)
                .AsQueryable();

            if (!showDeleted)
            {
                query = query.Where(p => !p.IsDeleted);
            }

            var products = await query
                .OrderByDescending(p => p.Id)
                .Select(p => new {
                    p.Id,
                    p.Name,
                    p.Price,
                    p.PriceReduced,
                    p.Description,
                    p.Trademark,
                    p.ImageUrl,
                    p.IsActive,
                    p.IsDeleted,
                    CategoryName = p.Category.Name
                })
                .ToListAsync();

            return Ok(products);
        }

        // 2. LẤY CHI TIẾT SẢN PHẨM
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var p = await _context.Products
                .Include(p => p.Images)
                .Include(p => p.OptionGroups)
                    .ThenInclude(g => g.Values)
                .Include(p => p.Variants)
                    .ThenInclude(v => v.OptionValues)
                        .ThenInclude(ov => ov.OptionValue)
                            .ThenInclude(ov => ov.Group) // BỔ SUNG DÒNG NÀY ĐỂ LẤY TÊN NHÓM (Hương vị, Size...)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (p == null) return NotFound();

            var result = new
            {
                p.Id,
                p.Name,
                p.Price,
                p.PriceReduced,
                p.Description,
                p.ImageUrl,
                Images = p.Images.Select(i => new { i.Id, i.Url }),
                OptionGroups = p.OptionGroups.Select(g => new {
                    g.Id,
                    g.Name,
                    Values = g.Values.Select(v => new { v.Id, v.Value })
                }),
                Variants = p.Variants.Select(v => new {
                    v.Id,
                    Sku = v.Sku,
                    v.PriceOverride,
                    v.IsActive,
                    // Sử dụng kiểm tra null an toàn ?. để tránh crash nếu dữ liệu lỗi
                    Options = v.OptionValues.ToDictionary(
                        ov => ov.OptionValue?.Group?.Name ?? "Unknown",
                        ov => ov.OptionValue?.Value ?? "N/A"
                    )
                })
            };
            return Ok(result);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromForm] Product product,
                                       [FromForm] string? VariantsData,
                                       IFormFile? imageUrl,
                                       List<IFormFile>? images)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // 1. Lưu Product cơ bản
                if (imageUrl != null) product.ImageUrl = await SaveImage(imageUrl);
                product.IsDeleted = false;
                product.IsActive = true;
                _context.Products.Add(product);
                await _context.SaveChangesAsync();

                // 2. Xử lý Thuộc tính & Biến thể
                if (!string.IsNullOrEmpty(VariantsData))
                {
                    var optionsDto = JsonConvert.DeserializeObject<List<ProductOptionGroupDto>>(VariantsData);
                    if (optionsDto != null && optionsDto.Any())
                    {
                        // Danh sách chứa các nhóm giá trị để thực hiện Cross Join
                        var allGroupValues = new List<List<ProductOptionValue>>();

                        foreach (var optDto in optionsDto)
                        {
                            var group = new ProductOptionGroup { ProductId = product.Id, Name = optDto.Name };
                            _context.ProductOptionGroups.Add(group);
                            await _context.SaveChangesAsync();

                            var currentValues = new List<ProductOptionValue>();
                            foreach (var valDto in optDto.Values)
                            {
                                var newValue = new ProductOptionValue
                                {
                                    ProductOptionGroupId = group.Id,
                                    Value = valDto.Value
                                };
                                _context.ProductOptionValues.Add(newValue);
                                currentValues.Add(newValue);
                            }
                            await _context.SaveChangesAsync(); // Lưu để có ID cho từng Value
                            allGroupValues.Add(currentValues);
                        }

                        // 3. TẠO BIẾN THỂ (CROSS JOIN)
                        var combinations = GenerateCombinations(allGroupValues);

                        foreach (var combo in combinations)
                        {
                            // Tạo bản ghi Variant
                            var variant = new ProductVariant
                            {
                                ProductId = product.Id,
                                Sku = Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
                                StockQuantity = 5, // Ví dụ đặt mặc định là 5 như mẫu của bạn
                                IsActive = true,
                                CreatedAt = DateTime.UtcNow
                            };
                            _context.ProductVariants.Add(variant);
                            await _context.SaveChangesAsync(); // Lưu để có VariantId

                            // 4. LƯU LIÊN KẾT TRUNG GIAN (QUAN TRỌNG NHẤT)
                            foreach (var val in combo)
                            {
                                var link = new ProductVariantOptionValue
                                {
                                    ProductVariantId = variant.Id,
                                    ProductOptionValueId = val.Id,
                                    IsVariantGroup = true
                                };
                                _context.ProductVariantOptionValues.Add(link);
                            }
                        }
                        await _context.SaveChangesAsync();
                    }
                }

                // 5. Lưu ảnh phụ
                if (images != null && images.Any())
                {
                    foreach (var file in images)
                    {
                        var url = await SaveImage(file);
                        _context.ProductImages.Add(new ProductImage { ProductId = product.Id, Url = url });
                    }
                    await _context.SaveChangesAsync();
                }

                await transaction.CommitAsync();
                return Ok(new { success = true, productId = product.Id });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return BadRequest(new { message = ex.InnerException?.Message ?? ex.Message });
            }
        }

        // Hàm thuật toán tạo tổ hợp
        private List<List<ProductOptionValue>> GenerateCombinations(List<List<ProductOptionValue>> lists)
        {
            var combinations = new List<List<ProductOptionValue>> { new List<ProductOptionValue>() };
            foreach (var list in lists)
            {
                var newCombinations = new List<List<ProductOptionValue>>();
                foreach (var combination in combinations)
                {
                    foreach (var item in list)
                    {
                        var newCombination = new List<ProductOptionValue>(combination) { item };
                        newCombinations.Add(newCombination);
                    }
                }
                combinations = newCombinations;
            }
            return combinations;
        }

        // 4. CẬP NHẬT SẢN PHẨM (Dựa trên logic Update phức tạp bạn đã gửi)
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromForm] Product product, IFormFile? imageUrl)
        {
            var existingProduct = await _context.Products
                .Include(p => p.Images)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (existingProduct == null) return NotFound();

            // Cập nhật thông tin cơ bản
            existingProduct.Name = product.Name;
            existingProduct.Price = product.Price;
            existingProduct.PriceReduced = product.PriceReduced;
            existingProduct.Description = product.Description;
            existingProduct.CategoryId = product.CategoryId;
            existingProduct.Trademark = product.Trademark;
            existingProduct.IsActive = product.IsActive;
            existingProduct.IsDeleted = !product.IsActive;

            if (imageUrl != null)
                existingProduct.ImageUrl = await SaveImage(imageUrl);

            await _context.SaveChangesAsync();
            return Ok(new { success = true });
        }

        // 5. ẨN/HIỆN NHANH (Patch)
        [HttpPatch("{id}/toggle-status")]
        public async Task<IActionResult> ToggleStatus(int id)
        {
            var p = await _context.Products.FindAsync(id);
            if (p == null) return NotFound();

            p.IsDeleted = !p.IsDeleted;
            p.IsActive = !p.IsDeleted;

            await _context.SaveChangesAsync();
            return Ok(new { success = true, isDeleted = p.IsDeleted });
        }

        // 6. PHỤC HỒI (Restore)
        [HttpPost("{id}/restore")]
        public async Task<IActionResult> Restore(int id)
        {
            var p = await _context.Products.Include(x => x.Variants).FirstOrDefaultAsync(x => x.Id == id);
            if (p == null) return NotFound();

            p.IsDeleted = false;
            p.IsActive = true;
            if (p.Variants != null)
            {
                foreach (var v in p.Variants) v.IsActive = true;
            }

            await _context.SaveChangesAsync();
            return Ok(new { success = true });
        }

        // HÀM HELPER LƯU ẢNH
        private async Task<string> SaveImage(IFormFile image)
        {
            var fileName = $"{Guid.NewGuid()}{Path.GetExtension(image.FileName)}";
            var path = Path.Combine(_env.WebRootPath, "images", fileName);

            using var stream = new FileStream(path, FileMode.Create);
            await image.CopyToAsync(stream);

            return "/images/" + fileName;
        }
    }

}
