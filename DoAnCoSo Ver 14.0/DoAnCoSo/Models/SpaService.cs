using System.ComponentModel.DataAnnotations;

namespace DoAnCoSo.Models
{
    public class SpaService : Service
    {
        [Display(Name = "Giá (Dưới 5kg)")]
        public decimal? PriceUnder5kg { get; set; }

        [Display(Name = "Giá (5kg - 12kg)")]
        public decimal? Price5To12kg { get; set; }

        [Display(Name = "Giá (12kg - 25kg)")]
        public decimal? Price12To25kg { get; set; }

        [Display(Name = "Giá (Trên 25kg)")]
        public decimal? PriceOver25kg { get; set; }

    }
}
