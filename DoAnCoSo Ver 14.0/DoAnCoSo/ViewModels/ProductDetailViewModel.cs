using DoAnCoSo.Models;

namespace DoAnCoSo.ViewModels
{
    public class ProductDetailViewModel
    {
        public Product? Product { get; set; } // Thông tin sản phẩm
        public List<ProductReview>? Reviews { get; set; } // Danh sách các bình luận hiện có
        public ProductReview NewReview { get; set; } = new ProductReview(); // Đối tượng cho form thêm bình luận mới
        public double AverageRating { get; set; }
        public int TotalReviews { get; set; }
    }
}
