
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models 
{
    public class ProductReviewImage
    {
        [Key]
        public int Id { get; set; }

        // Khóa ngoại liên kết đến bảng ProductReviews
        [ForeignKey("Review")] // Tên Navigation Property trong ProductReview
        [Required]
        public int ReviewId { get; set; }

   
        [StringLength(500)] // Giới hạn độ dài URL
        public string? ImageUrl { get; set; }

        [StringLength(250)] // Giới hạn độ dài chú thích
        public string? Caption { get; set; } // Dùng string? nếu cho phép Null

       
    }
}