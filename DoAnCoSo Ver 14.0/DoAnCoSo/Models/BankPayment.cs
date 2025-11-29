using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class BankPayment
    {
        [Key]
        public Guid PaymentId { get; set; }

        [Required]
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "VND";
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime ExpiresAt { get; set; }
        public string Description { get; set; }
        
        [Required]
        [ForeignKey("Order")]
        public int OrderId { get; set; }

        // Navigation Property
        public Order Order { get; set; }
    }
}
