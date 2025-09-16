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
    public string SenderName { get; set; }  // Tên người gửi để hiển thị trực tiếp

    [Required]
    public string ReceiverId { get; set; }
    public ApplicationUser Receiver { get; set; }

    [Required]
    public string Message { get; set; }

    public DateTime SentAt { get; set; } = DateTime.UtcNow;

    public bool IsRead { get; set; } = false;
}
