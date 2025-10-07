using DoAnCoSo.Models;
using System.ComponentModel.DataAnnotations;

namespace DoAnCoSo.Models
{
    public class Service
    {
        [Key]
        public int ServiceId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Name { get; set; }  // Tên dịch vụ

        public string? Description { get; set; }  // Mô tả chi tiết

        [Range(0, double.MaxValue)]
        public decimal Price { get; set; } // Giá gốc

        [Range(0, double.MaxValue)]
        public decimal? SalePrice { get; set; } // Giá khuyến mãi

        public string? Image { get; set; } // Ảnh minh họa

        public ServiceCategory Category { get; set; } // Spa, Homestay, Vet

        // Quan hệ
        public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();

        public SpaPricing? SpaPricing { get; set; }

        public ICollection<ServiceDetail> ServiceDetails { get; set; } = new List<ServiceDetail>();

        // Quan hệ với PetServiceRecord
        public ICollection<PetServiceRecord> PetServiceRecords { get; set; } = new List<PetServiceRecord>();
    }
}