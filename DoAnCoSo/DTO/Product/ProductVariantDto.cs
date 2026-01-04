namespace DoAnCoSo.DTO.Product
{
    public class ProductVariantDto
    {
        public int Id { get; set; }
        public int StockQuantity { get; set; }
        public Dictionary<string, string> Options { get; set; }
    }
}
