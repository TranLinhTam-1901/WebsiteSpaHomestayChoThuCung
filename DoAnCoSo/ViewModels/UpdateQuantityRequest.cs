namespace DoAnCoSo.ViewModels
{
    public class UpdateQuantityRequest
    {
        public int CartItemId { get; set; }
        public int ProductId { get; set; }
        public int Quantity { get; set; }
    }
}
