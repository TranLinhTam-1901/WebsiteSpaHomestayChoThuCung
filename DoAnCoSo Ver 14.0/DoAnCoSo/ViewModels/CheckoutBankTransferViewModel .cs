using DoAnCoSo.Models;

namespace DoAnCoSo.ViewModels
{
    public class CheckoutBankTransferViewModel
    {
        public int OrderId { get; set; }
        public decimal Amount { get; set; }
        public string QRImageUrl { get; set; }
        public string BankAccount { get; set; }
        public string OwnerName { get; set; }
        public string Content { get; set; }
    }
}
