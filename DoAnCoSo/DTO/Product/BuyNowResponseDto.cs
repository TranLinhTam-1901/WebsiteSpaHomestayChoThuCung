namespace DoAnCoSo.DTO.Product
{
    public class BuyNowResponseDto
    {
        public bool Success { get; set; }
        public string? Message { get; set; }

        // dữ liệu cần cho checkout
        public int ProductId { get; set; }
        public int Quantity { get; set; }
        public int? VariantId { get; set; }
        public string? BuyNowFlavor { get; set; }

    }
}
