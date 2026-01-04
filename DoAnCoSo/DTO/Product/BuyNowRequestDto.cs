namespace DoAnCoSo.DTO.Product
{
    public class BuyNowRequestDto
    {
        public int ProductId { get; set; }
        public int Quantity { get; set; } = 1;
        public int? VariantId { get; set; }
        public string? BuyNowFlavor { get; set; }
    }
}
