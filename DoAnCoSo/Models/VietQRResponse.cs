namespace DoAnCoSo.Models
{
    public class VietQRResponse
    {
        public string bankCode { get; set; }
        public string bankName { get; set; }
        public string bankAccount { get; set; }
        public string userBankName { get; set; }
        public string amount { get; set; }
        public string content { get; set; }
        public string qrCode { get; set; }
        public string imgId { get; set; }
        public int existing { get; set; }
        public string transactionId { get; set; }
        public string transactionRefId { get; set; }
        public string qrLink { get; set; }
        public string orderId { get; set; }
    }
}
