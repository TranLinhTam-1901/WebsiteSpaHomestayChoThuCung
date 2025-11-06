using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class Product
    {
        public int Id { get; set; }

        [Required, StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [Range(1000, 100000000, ErrorMessage = "Giá phải từ 1,000 VND đến 100,000,000 VND")]
        public decimal Price { get; set; }

        [Range(1000, 100000000, ErrorMessage = "Giá phải từ 1,000 VND đến 100,000,000 VND")]
        public decimal? PriceReduced { get; set; }

        // Thương hiệu
        public string? Trademark { get; set; }
        public string? Description { get; set; }
        public string? ImageUrl { get; set; }

        // Ảnh nhiều
        public List<ProductImage> Images { get; set; } = new();

        // Danh mục
        public int CategoryId { get; set; }
        public Category? Category { get; set; }

        // Hương vị (lưu dạng chuỗi)
        public string Flavors { get; set; } = string.Empty;

        [NotMapped]
        public List<string> FlavorsList
        {
            get => string.IsNullOrEmpty(Flavors)
                ? new List<string>()
                : Flavors.Split(',').ToList();
            set => Flavors = (value != null && value.Count > 0)
                ? string.Join(",", value)
                : string.Empty;
        }


        // kho hàng 
        public int StockQuantity { get; set; } = 0;       
        public int LowStockThreshold { get; set; } = 5;   
        public int SoldQuantity { get; set; } = 0;

        public int ReservedQuantity { get; set; } = 0;


        // Yêu thích
        public ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();


        // Đánh giá (đã thay ProductReview -> Review)
        public List<Review> Reviews { get; set; } = new();


        // % Giảm giá
        [NotMapped]
        public decimal DiscountPercentage
        {
            get
            {
                if (Price > 0 && PriceReduced.HasValue)
                {
                    return Math.Floor(((Price - PriceReduced.Value) / Price) * 100);
                }
                return 0;
            }
        }
    }
}
