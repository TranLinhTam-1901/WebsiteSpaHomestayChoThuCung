using DoAnCoSo.Data;
using DoAnCoSo.DTO.Product;
using DoAnCoSo.Models;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Services
{
    public class ProductApiService : IProductApiService
    {
        private readonly ApplicationDbContext _context;

        public ProductApiService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<List<ProductListDto>> GetProductsAsync(int? categoryId)
        {
            var query = _context.Products
                .Where(p => p.IsActive && !p.IsDeleted);

            if (categoryId.HasValue && categoryId.Value > 0)
            {
                query = query.Where(p => p.CategoryId == categoryId.Value);
            }

            return await query
                .Select(p => new ProductListDto
                {
                    Id = p.Id,
                    Name = p.Name,
                    Price = p.Price,
                    PriceReduced = p.PriceReduced,
                    DiscountPercentage = p.DiscountPercentage,
                    ImageUrl = p.ImageUrl ?? p.Images.FirstOrDefault().Url,
                    Trademark = p.Trademark,
                    HasVariants = p.Variants.Any(v => v.IsActive),
                    InStock = p.StockQuantity > 0
                })
                .ToListAsync();
        }


        public async Task<ProductDetailDto?> GetProductDetailAsync(int id)
        {
            var product = await _context.Products
                .Include(p => p.Images)
                .Include(p => p.Category)
                
                .FirstOrDefaultAsync(p =>
                    p.Id == id &&
                    p.IsActive &&
                    !p.IsDeleted
                );

            if (product == null) return null;

            // 2️⃣ Query OptionGroups + Values RIÊNG (KHÔNG phụ thuộc navigation)
            var optionGroups = await _context.ProductOptionGroups
                .Where(g => g.ProductId == product.Id)
                .Include(g => g.Values)
                .Select(g => new ProductOptionGroupDto
                {
                    Id = g.Id,
                    Name = g.Name,
                    Values = g.Values.Select(v => new ProductOptionValueDto
                    {
                        Id = v.Id,
                        Value = v.Value
                    }).ToList()
                })
                .ToListAsync();

            // 3️⃣ Map sang DTO
            var dto = new ProductDetailDto
            {
                Id = product.Id,
                Name = product.Name,
                Description = product.Description,
                Price = product.Price,
                PriceReduced = product.PriceReduced,
                DiscountPercentage = product.DiscountPercentage,
                Trademark = product.Trademark,
                StockQuantity = product.StockQuantity,
                CategoryName = product.Category!.Name!,
                Images = product.Images.Select(i => i.Url).ToList(),
                OptionGroups = optionGroups
            };

            return dto;
        }


    }
}
