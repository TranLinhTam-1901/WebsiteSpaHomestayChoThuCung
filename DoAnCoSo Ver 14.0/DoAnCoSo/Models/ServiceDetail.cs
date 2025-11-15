using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class ServiceDetail
    {
        [Key]
        public int ServiceDetailId { get; set; }

        [ForeignKey("Service")]
        public int ServiceId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } // Ví dụ: "Tắm gội cơ bản", "Cạo lông"

        [Required]
        [Range(0, double.MaxValue)]
        public decimal Price { get; set; }

        [Range(0, double.MaxValue)]
        public decimal? SalePrice { get; set; }

        // Quan hệ
        public Service Service { get; set; }
    }
}
