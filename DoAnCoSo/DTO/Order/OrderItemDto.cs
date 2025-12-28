namespace DoAnCoSo.DTO.Order
{
    public class OrderItemDto
    {
        public string Name { get; set; } = "";
        public string Option { get; set; } = "";
        public int Quantity { get; set; }
        public decimal Price { get; set; }
        public decimal DiscountedPrice { get; set; }
    }
}
