using static DoAnCoSo.Controllers.Api.OrderHistoryApiController;

namespace DoAnCoSo.DTO.Order
{
    public class OrderDto
    {
        public int Id { get; set; }
        public DateTime OrderDate { get; set; }
        public string CustomerName { get; set; } = "";
        public string PhoneNumber { get; set; } = "";
        public string ShippingAddress { get; set; }   // ⭐ thêm
        public string PaymentMethod { get; set; }     // ⭐ thêm
        public string Notes { get; set; }
        public string Status { get; set; } = "";
        public decimal TotalPrice { get; set; }
        public decimal Discount { get; set; } // tổng giảm giá
        public string? PromoCode { get; set; }
        public List<OrderItemDto> Items { get; set; } = new();
    }
}