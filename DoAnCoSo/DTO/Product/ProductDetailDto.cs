namespace DoAnCoSo.DTO.Product
{
    public class ProductDetailDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
        public string? Description { get; set; }

        public decimal Price { get; set; }
        public decimal? PriceReduced { get; set; }
        public decimal DiscountPercentage { get; set; }

        public string? Trademark { get; set; }
        public int StockQuantity { get; set; }

        public string CategoryName { get; set; } = "";
        public List<string> Images { get; set; } = new();

        public List<ProductOptionGroupDto> OptionGroups { get; set; } = new();
        public List<ProductVariantDto> Variants { get; set; } = new();

    }
}
