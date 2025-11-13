namespace DoAnCoSo.ViewModels
{
    public class InventoryVariantRowViewModel
    {
        public int VariantId { get; set; }
        public string VariantName { get; set; } = "";
        public int StockQuantity { get; set; }
        public int ReservedQuantity { get; set; }
        public int SoldQuantity { get; set; }
        public int LowStockThreshold { get; set; }
    }
}
