using System.ComponentModel.DataAnnotations.Schema;
namespace DoAnCoSo.Models
{
    public class OrderPromotion
    {
        public int Id { get; set; }


        // Khóa ngoại tới Promotion
        public int PromotionId { get; set; }
        [ForeignKey("PromotionId")]
        public Promotion Promotion { get; set; }


        // Khóa ngoại tới Order
        public int OrderId { get; set; }
        [ForeignKey("OrderId")]
        public Order Order { get; set; }


        // Dữ liệu sử dụng mã khuyến mãi
        public string? CodeUsed { get; set; }
        public decimal DiscountApplied { get; set; }

        // (Tuỳ chọn thêm)
        public DateTime UsedAt { get; set; } = DateTime.Now;

    }
}
