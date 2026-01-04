namespace DoAnCoSo.DTO.Product
{
    public class AddToCartRequest
    {
        public int ProductId { get; set; }
        public int Quantity { get; set; } = 1;
        public int? VariantId { get; set; }
    }
}
