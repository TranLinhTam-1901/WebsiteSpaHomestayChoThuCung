using System.ComponentModel.DataAnnotations;
using System.Collections.Generic;

namespace DoAnCoSo.Models
{
    public enum ServiceCategory
    {
        Spa,
        Homestay,
        Vet
    }

    public class Service
    {
        [Key]
        public int ServiceId { get; set; }

        [Required]
        public string? Name { get; set; }

        public string? Description { get; set; }

        public decimal Price { get; set; }

        public decimal? SalePrice { get; set; }

        public string? Image { get; set; }

        public ServiceCategory Category { get; set; }

        public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();

        public SpaPricing? SpaPricing { get; set; }

        public ICollection<ServiceDetail> ServiceDetails { get; set; } = new List<ServiceDetail>();
    }

}
