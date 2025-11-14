namespace DoAnCoSo.Models
{
    public class ProductVariant
    {
        public int Id { get; set; }
        public int ProductId { get; set; }      // FK → Product
        public string Sku { get; set; }         // tùy chọn
        public string Name { get; set; }        // ví dụ: "Vani", "Socola", "Size M"

        public decimal? PriceOverride { get; set; } // null = dùng giá Product
        public int StockQuantity { get; set; }
        public int ReservedQuantity { get; set; }
        public int SoldQuantity { get; set; }
        public int LowStockThreshold { get; set; } = 0;
        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public Product Product { get; set; }
    }
}
