using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class SpaPricing
    {
        [Key]
        public int SpaPricingId { get; set; }

        public int ServiceId { get; set; }
        [ForeignKey("ServiceId")]
        public Service Service { get; set; }

        public decimal? PriceUnder5kg { get; set; }
        public decimal? Price5To12kg { get; set; }
        public decimal? Price12To25kg { get; set; }
        public decimal? PriceOver25kg { get; set; }
    }

}
