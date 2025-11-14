namespace DoAnCoSo.ViewModels
{
    public class InventoryDashboardViewModel
    {
        public int ProductId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public int StockQuantity { get; set; }
        public int SoldQuantity { get; set; }
        public int ReservedQuantity { get; set; }
        public int LowStockThreshold { get; set; }
        public bool IsLowStock => (StockQuantity - ReservedQuantity) <= LowStockThreshold;
        public int VariantCount { get; set; }
    }
}
