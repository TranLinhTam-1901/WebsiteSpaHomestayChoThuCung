using System.ComponentModel.DataAnnotations;

namespace DoAnCoSo.Models
{
    public class ChatMessage
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int ConversationId { get; set; }
        public Conversation Conversation { get; set; }

        [Required]
        public string SenderId { get; set; }
        public ApplicationUser? Sender { get; set; }

        [Required]
        public string SenderName { get; set; }

        [Required]
        public string ReceiverId { get; set; }
        public ApplicationUser? Receiver { get; set; }

        public string? Message { get; set; } // ciphertext AES cho người nhận

        [Required]
        public string EncryptedAesKey { get; set; }

        public string? SenderCopy { get; set; }
        public string? SenderAesKey { get; set; }

        // ✅ Lưu danh sách link ảnh (đã mã hóa token) dưới dạng JSON
        public string? ImageUrlsJson { get; set; }

        // ✅ Lưu danh sách token (nếu cần kiểm soát riêng)
        public string? ImageKeysJson { get; set; }

        // ✅ Dự phòng — nếu 1 tin nhắn chỉ có 1 ảnh
        public string? SingleImageToken { get; set; }

        public DateTime SentAt { get; set; } = DateTime.UtcNow;

        public bool IsRead { get; set; } = false;
    }
}