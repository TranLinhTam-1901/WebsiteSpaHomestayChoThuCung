namespace DoAnCoSo.ViewModels
{
    public class InventoryVariantListViewModel
    {
        public int ProductId { get; set; }
        public string ProductName { get; set; } = "";
        public List<InventoryVariantRowViewModel> Variants { get; set; } = new();
    }
}
