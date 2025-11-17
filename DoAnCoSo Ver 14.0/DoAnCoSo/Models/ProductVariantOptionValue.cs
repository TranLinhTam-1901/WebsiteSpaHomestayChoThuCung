namespace DoAnCoSo.Models
{
    public class ProductVariantOptionValue
    {
        public int ProductVariantId { get; set; }
        public int ProductOptionValueId { get; set; }

        public ProductVariant Variant { get; set; } = default!;
        public ProductOptionValue OptionValue { get; set; } = default!;
    }
}
