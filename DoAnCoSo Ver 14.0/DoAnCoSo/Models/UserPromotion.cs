using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
namespace DoAnCoSo.Models
{
    public class UserPromotion
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string UserId { get; set; }

        [Required]
        public int PromotionId { get; set; }

        public bool IsUsed { get; set; } = false;
        public DateTime DateSaved { get; set; } = DateTime.Now;
        public DateTime? UsedAt { get; set; }

        [ForeignKey("UserId")]
        public ApplicationUser User { get; set; }

        [ForeignKey("PromotionId")]
        public Promotion Promotion { get; set; }
    }

}
