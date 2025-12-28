namespace DoAnCoSo.Models
{
    public class ProductOptionValue
    {
        public int Id { get; set; }
        public int ProductOptionGroupId { get; set; }   // FK → Group
        public string Value { get; set; } = "";         // "Bò", "Gà", "S", "M", "500g"

        public ProductOptionGroup Group { get; set; } = default!;

        public ICollection<ProductVariantOptionValue> Variants { get; set; } = new List<ProductVariantOptionValue>();

    }
}
