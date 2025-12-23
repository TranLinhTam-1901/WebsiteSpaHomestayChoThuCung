namespace DoAnCoSo.DTO.Product
{
    public class ProductListDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
        public decimal Price { get; set; }
        public decimal? PriceReduced { get; set; }
        public decimal DiscountPercentage { get; set; }

        public string? ImageUrl { get; set; }
        public string? Trademark { get; set; }

        public bool HasVariants { get; set; }
        public bool InStock { get; set; }
    }
}
