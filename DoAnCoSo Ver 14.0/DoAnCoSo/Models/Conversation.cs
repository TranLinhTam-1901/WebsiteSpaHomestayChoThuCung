using System.ComponentModel.DataAnnotations;

namespace DoAnCoSo.Models
{
    public class Conversation
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string CustomerId { get; set; } = string.Empty;
        public ApplicationUser? Customer { get; set; }

        // Cho phép null — admin có thể gán sau này
        public string? AdminId { get; set; }
        public ApplicationUser? Admin { get; set; }

        public DateTime LastUpdated { get; set; } = DateTime.UtcNow;

        // ✅ Khởi tạo list rỗng để tránh lỗi null khi truy cập Messages
        public ICollection<ChatMessage> Messages { get; set; } = new List<ChatMessage>();
    }
}
