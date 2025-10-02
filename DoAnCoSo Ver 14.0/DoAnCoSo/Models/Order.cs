using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Mvc.ModelBinding.Validation;

namespace DoAnCoSo.Models
{
    public class Order
    {
        public int Id { get; set; }
        public string? UserId { get; set; }
        public DateTime OrderDate { get; set; }
        public decimal TotalPrice { get; set; }

        // --- THÊM CÁC THUỘC TÍNH NÀY ---
        // (Bạn có thể bỏ [Required] nếu không muốn validation ở model level, nhưng nên có)
        [Required(ErrorMessage = "Tên người nhận không được để trống.")]
        public string? CustomerName { get; set; }

        [Required(ErrorMessage = "Số điện thoại không được để trống.")]
        [Phone(ErrorMessage = "Số điện thoại không hợp lệ.")]
        public string? PhoneNumber { get; set; }

        public OrderStatusEnum Status { get; set; }

        // --- THÊM THUỘC TÍNH NÀY ---
        public string? PaymentMethod { get; set; }
        public string?  ShippingAddress { get; set; }
        public string? Notes { get; set; }

        [ForeignKey("UserId")]
        [ValidateNever]
        public ApplicationUser User { get; set; }
        public List<OrderDetail> OrderDetails { get; set; } = new List<OrderDetail>();

        public ICollection<Payment> Payments { get; set; } = new List<Payment>();
        public ICollection<Invoice> Invoices { get; set; } = new List<Invoice>();
     
    }
}
