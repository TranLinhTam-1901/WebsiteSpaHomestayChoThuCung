namespace DoAnCoSo.DTO.Product
{
    public class ProductOptionGroupDto
    {

        public int Id { get; set; }
        public string Name { get; set; } = "";
        public List<ProductOptionValueDto> Values { get; set; } = new();
    }

}
