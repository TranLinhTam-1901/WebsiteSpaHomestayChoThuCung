namespace DoAnCoSo.Models
{
    public class VietQRRequest
    {
        public string bankCode { get; set; }
        public string bankAccount { get; set; }
        public string userBankName { get; set; }
        public string content { get; set; }
        public int qrType { get; set; } = 0; // QR động
        public long amount { get; set; }
        public string orderId { get; set; }
        public string transType { get; set; } = "C";
    }
}
