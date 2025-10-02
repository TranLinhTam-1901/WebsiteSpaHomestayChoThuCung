using DoAnCoSo.Models;

namespace DoAnCoSo.ViewModels
{
    public class ProductDetailViewModel
    {
        public Product? Product { get; set; }

        // Ảnh chính
        public string? MainImage => Product?.ImageUrl;

        // Ảnh phụ (map sang Url thay vì ImageUrl)
        public List<string> AdditionalImageUrls =>
            Product?.Images?.Select(i => i.Url).ToList() ?? new List<string>();

        // Giá
        public decimal Price => Product?.Price ?? 0;
        public decimal? PriceReduced => Product?.PriceReduced;
        public decimal DiscountPercentage => Product?.DiscountPercentage ?? 0;

        // Thông tin khác
        public string? Trademark => Product?.Trademark;
        public string? Description => Product?.Description;
        public string? CategoryName => Product?.Category?.Name;
        public List<string> Flavors => Product?.FlavorsList ?? new List<string>();

        // Đánh giá
        public List<Review> Reviews { get; set; } = new();
        public Review NewReview { get; set; } = new();

        // Thống kê
        public double AverageRating { get; set; }
        public int TotalReviews { get; set; }

        // Yêu thích
        public bool IsFavorite { get; set; } = false;

        // Thêm property để View dùng thay vì gọi Content trực tiếp
        public List<string> ReviewComments =>
            Reviews.Select(r => r.Comment).ToList(); // giả sử property trong Review là Comment
    }
}