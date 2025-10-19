namespace DoAnCoSo.Models
{
    public class Promotion
    {
        public int Id { get; set; }
        public string Title { get; set; } = "";
        public string ShortDescription { get; set; } = "";
        public string Description { get; set; } = "";
        public string? Image { get; set; } = "";
        public bool IsCampaign { get; set; } = false; // Nếu true thì hiển thị kèm ảnh
        public decimal Discount { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }

        // Mã code
        public string? Code { get; set; }

        // Hình thức giảm
        public bool IsPercent { get; set; } = true; // true = %, false = số tiền
        //public decimal DiscountValue { get; set; }  // Ví dụ: 10% hoặc 50000đ

        // Điều kiện áp dụng
        public decimal? MinOrderValue { get; set; } // Điều kiện đơn tối thiểu
        public int? MaxUsage { get; set; }          // Tổng số lượt được sử dụng
        public int? MaxUsagePerUser { get; set; }   // Mỗi user được dùng mấy lần

        // Trạng thái
        public bool IsActive { get; set; } = true;
        public ICollection<OrderPromotion> OrderPromotions { get; set; } = new List<OrderPromotion>();
        
    }

}
