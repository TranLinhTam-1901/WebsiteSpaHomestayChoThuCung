using DoAnCoSo.Models;
using System.ComponentModel.DataAnnotations;

public class ChatMessage
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int ConversationId { get; set; }
    public Conversation Conversation { get; set; }

    [Required]
    public string SenderId { get; set; }
    public ApplicationUser Sender { get; set; }

    [Required]
    public string SenderName { get; set; }

    [Required]
    public string ReceiverId { get; set; }
    public ApplicationUser Receiver { get; set; }

    [Required]
    public string Message { get; set; } // ciphertext AES cho người nhận

    [Required]
    public string EncryptedAesKey { get; set; } // AES key đã mã hóa bằng RSA (public key người nhận)

    public string SenderCopy { get; set; } // ciphertext AES riêng cho người gửi
    public string SenderAesKey { get; set; } // AES key của bản sao người gửi (mã hóa RSA bằng public key người gửi)

    public DateTime SentAt { get; set; } = DateTime.UtcNow;

    public bool IsRead { get; set; } = false;
}
