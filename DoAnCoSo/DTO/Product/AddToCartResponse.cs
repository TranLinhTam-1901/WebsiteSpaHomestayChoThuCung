namespace DoAnCoSo.DTO.Product
{
    public class AddToCartResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = "";
        public int CartItemCount { get; set; }
    }
}
