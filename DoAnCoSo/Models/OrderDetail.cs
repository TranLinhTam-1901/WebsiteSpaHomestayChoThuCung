namespace DoAnCoSo.Models
{
    public class OrderDetail
    {
        public int Id { get; set; }
        public int OrderId { get; set; }
        public int ProductId { get; set; }
        public int Quantity { get; set; }
        public decimal Price { get; set; }
        public Order Order { get; set; }
        public Product Product { get; set; }

        public decimal OriginalPrice { get; set; }    
        public decimal DiscountedPrice { get; set; }

        public string? SelectedFlavor { get; set; }
        public int? VariantId { get; set; }     // FK tùy chọn tới ProductVariant
        public string? VariantName { get; set; } // Snapshot tên biến thể tại thời điểm đặt

    }
}
