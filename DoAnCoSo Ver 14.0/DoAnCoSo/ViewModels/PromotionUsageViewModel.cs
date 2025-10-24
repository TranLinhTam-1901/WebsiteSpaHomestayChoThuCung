namespace DoAnCoSo.ViewModels
{
    public class PromotionUsageViewModel
    {
        public string UserName { get; set; }
        public string Email { get; set; }
        public int OrderId { get; set; }
        public decimal DiscountApplied { get; set; }
        public DateTime UsedAt { get; set; }
    }
}
