using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class ReviewImage
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Review")]
        [Required]
        public int ReviewId { get; set; }

        public Review Review { get; set; }   // navigation property mới

        [StringLength(500)]
        public string? ImageUrl { get; set; }

        [StringLength(250)]
        public string? Caption { get; set; }
    }
}
