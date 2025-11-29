namespace DoAnCoSo.Models
{
    public class ProductOptionGroup
    {
        public int Id { get; set; }
        public int ProductId { get; set; }   // FK → Product
        public string Name { get; set; } = "";   // "Hương vị", "Size", "Khối lượng"

        public Product Product { get; set; } = default!;
        public ICollection<ProductOptionValue> Values { get; set; } = new List<ProductOptionValue>();
    }
}
