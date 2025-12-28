using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class Payment
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public decimal Amount { get; set; }

        [Required]
        public string PaymentMethod { get; set; } // Ví điện tử, thẻ...

        [Required]
        public DateTime PaymentDate { get; set; }

        [Required]
        [ForeignKey("Order")]
        public int OrderId { get; set; }

        // Navigation Property
        public Order Order { get; set; }
    }
}
