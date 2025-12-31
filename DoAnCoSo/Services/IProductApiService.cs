using DoAnCoSo.DTO.Product;

namespace DoAnCoSo.Services
{
    public interface IProductApiService
    {
        Task<List<ProductListDto>> GetProductsAsync(int? categoryId);
        Task<ProductDetailDto?> GetProductDetailAsync(int id);
    }
}
