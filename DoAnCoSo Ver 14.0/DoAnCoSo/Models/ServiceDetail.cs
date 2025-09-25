using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class ServiceDetail
    {
        [Key]
        public int ServiceDetailId { get; set; }

        public int ServiceId { get; set; }

        [Required]
        public string Name { get; set; }

        [Required]
        public decimal Price { get; set; }

        public decimal? SalePrice { get; set; }

        [ForeignKey("ServiceId")]
        public Service Service { get; set; }
    }
}
