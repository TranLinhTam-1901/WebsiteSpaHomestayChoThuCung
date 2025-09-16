using DoAnCoSo.Models;

namespace DoAnCoSo.Repositories
{
    public interface IProductRepository
    {
        Task<IEnumerable<Product>> GetAllAsync();
        Task<Product> GetByIdAsync(int id);
        Task AddAsync(Product product);
        Task UpdateAsync(Product product);
        Task DeleteAsync(int id);
        Task<Product?> GetProductWithReviewsAndImagesAsync(int id);

        Task<IEnumerable<Product>> GetProductsByCategoryAsync(string categoryName);
    }
}
