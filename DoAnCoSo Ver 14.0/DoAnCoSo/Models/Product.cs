using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Identity.Client;
using Microsoft.IdentityModel.Tokens;

namespace DoAnCoSo.Models
{
    public class Product
    {
        public int Id { get; set; }
        [Required, StringLength(100)]
        public string Name { get; set; }
        [Range(1000, 100000000, ErrorMessage = "Giá phải từ 1,000 VND đến 100,000,000 VND")]
        public decimal Price { get; set; }
        [Range(1000, 100000000, ErrorMessage = "Giá phải từ 1,000 VND đến 100,000,000 VND")]
        [BindProperty]
        public decimal? PriceReduced { get; set; }

        //Thương hiệu 
        public string? Trademark { get; set; }
        public string? Description { get; set; } 
        public string? ImageUrl {  get; set; }  
        public List<ProductImage>? Images { get; set; } 
        public int CategoryId { get; set; } 
        public Category? Category { get; set; }
        public string? Flavors { get; set; } = "";
        public ICollection<Favorite> Favorites { get; set; }

        [NotMapped]
        public List<string> FlavorsList
        {
        get => string.IsNullOrEmpty(Flavors) 
                ? new List<string>() 
                : Flavors.Split(',').ToList();

        set => Flavors = value != null 
                ? string.Join(",", value) 
                : "";
         }

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
        public List<ProductReview> Reviews { get; set; }  = new List<ProductReview>();
    }
}
