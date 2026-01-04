namespace DoAnCoSo.DTO.Product
{
    public class CheckoutRequestDto
    {
        public bool IsBuyNowCheckout { get; set; }

        // Buy now
        public int? BuyNowProductId { get; set; }
        public int? BuyNowQuantity { get; set; }
        public int? BuyNowVariantId { get; set; }
        public string? BuyNowFlavor { get; set; }

        // Cart
        public List<int>? SelectedCartItemIds { get; set; }

        // Promotion
        public string? PromoCode { get; set; }

        // Order info
        public string PaymentMethod { get; set; } = null!;
        public string? Notes { get; set; }
    }
}
