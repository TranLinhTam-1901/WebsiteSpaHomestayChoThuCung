using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class SpaPricing
    {
        [Key]
        public int SpaPricingId { get; set; }

        [ForeignKey("Service")]
        public int ServiceId { get; set; }
        public Service Service { get; set; }

        [Range(0, double.MaxValue)]
        public decimal? PriceUnder5kg { get; set; }

        [Range(0, double.MaxValue)]
        public decimal? Price5To12kg { get; set; }

        [Range(0, double.MaxValue)]
        public decimal? Price12To25kg { get; set; }

        [Range(0, double.MaxValue)]
        public decimal? PriceOver25kg { get; set; }
    }
}