using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class Invoice
    {
        [Key]
        public int InvoiceId { get; set; }

        [Required]
        [ForeignKey("Appointment")]
        public int AppointmentId { get; set; }

        [Required]
        public decimal TotalAmount { get; set; }

        public string? PaymentStatus { get; set; } = "Pending";

        public DateTime? PaymentDate { get; set; }

        [ForeignKey("Order")]
        public int OrderId { get; set; }
        public virtual Order Order { get; set; }
    }
}
