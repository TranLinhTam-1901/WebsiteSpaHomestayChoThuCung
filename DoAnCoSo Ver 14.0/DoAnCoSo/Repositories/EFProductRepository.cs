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
                .Include(p => p.Category) // ✅ thêm Include Category
                .Include(p => p.Reviews)
                    .ThenInclude(r => r.User)
                .Include(p => p.Reviews)
                    .ThenInclude(r => r.Images)
                .FirstOrDefaultAsync(p => p.Id == id);
        }

        public async Task<IEnumerable<Product>> GetProductsByCategoryAsync(string categoryName)
        {
            // Kiểm tra tên danh mục không rỗng hoặc null
            if (string.IsNullOrEmpty(categoryName))
            {
                // Trả về danh sách rỗng nếu tên danh mục không hợp lệ
                return Enumerable.Empty<Product>();
            }

            // --- BẮT ĐẦU CODE TRUY VẤN DATABASE ---
            // Truy vấn bảng Products
            return await _context.Products
                                 // Tải kèm thông tin Category (cần để lọc theo tên Category)
                                 .Include(p => p.Category)
                                 // Lọc các sản phẩm mà tên Category của chúng khớp với categoryName
                                 .Where(p => p.Category != null && p.Category.Name == categoryName)
                                 // Thực thi truy vấn và tải kết quả vào bộ nhớ dưới dạng danh sách
                                 .ToListAsync();
            // --- KẾT THÚC CODE TRUY VẤN DATABASE ---
        }



    }
}
