using DoAnCoSo.Models;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Repositories
{
    public class EFProductRepository : IProductRepository
    {
        private readonly ApplicationDbContext _context;
        public EFProductRepository(ApplicationDbContext context)
        {
            _context = context;
        }
        public async Task<IEnumerable<Product>> GetAllAsync()
        {
            return await _context.Products.Include(p => p.Category).ToListAsync();
        }

        public async Task AddReviewAsync(Review review)
        {
            _context.Reviews.Add(review);
            await _context.SaveChangesAsync();
        }

        public async Task<Product?> GetByIdAsync(int id)
        {
            return await _context.Products
        .Include(p => p.Category) // Include thông tin Category
        .Include(p => p.Images)   // <-- Thêm dòng này để include danh sách ProductImage
        .FirstOrDefaultAsync(p => p.Id == id);
        }

        public async Task AddAsync(Product product)
        {
            _context.Products.Add(product);
            await _context.SaveChangesAsync();
        }

        public async Task UpdateAsync(Product product)
        {
            _context.Products.Update(product);
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(int id)
        {
            var product = await _context.Products.FindAsync(id);
            _context.Products.Remove(product);
            await _context.SaveChangesAsync();

        }

        public async Task<Product?> GetProductWithReviewsAndImagesAsync(int id)
        {
            return await _context.Products
                .Include(p => p.Images)
                .Include(p => p.Category)
                .Include(p => p.Variants) 
                .Include(p => p.Reviews)
                    .ThenInclude(r => r.User)
                .Include(p => p.Reviews)
                    .ThenInclude(r => r.Images)
                .FirstOrDefaultAsync(p => p.Id == id);
        }

        public async Task<IEnumerable<Product>> GetProductsByCategoryAsync(string categoryName)
        {
            if (string.IsNullOrEmpty(categoryName))
            {
                return Enumerable.Empty<Product>();
            }

            return await _context.Products
                .Include(p => p.Category)
                .Where(p => p.Category != null && p.Category.Name == categoryName)
                .Where(p => p.IsActive && !p.IsDeleted)  
                .ToListAsync();
        }



    }
}
