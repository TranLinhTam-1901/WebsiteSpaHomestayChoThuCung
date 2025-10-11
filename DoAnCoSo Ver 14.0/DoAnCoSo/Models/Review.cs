using DoAnCoSo.Models;
using System.ComponentModel.DataAnnotations;

namespace DoAnCoSo.Models
{
    public enum ReviewTargetType
    {
        Product,
        Service
    }

    public class Review
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string UserId { get; set; }
        public ApplicationUser User { get; set; }

        public ReviewTargetType TargetType { get; set; }

        public int TargetId { get; set; } // ProductId hoặc ServiceId

        [Range(1, 5)]
        public int Rating { get; set; }

        [MaxLength(1000)]
        public string? Comment { get; set; }

        public DateTime CreatedDate { get; set; } = DateTime.Now;

        // Nếu là Product thì có thể có ảnh
        public List<ReviewImage> Images { get; set; } = new();
    }
}