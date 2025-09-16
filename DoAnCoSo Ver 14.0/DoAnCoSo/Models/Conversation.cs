using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class Conversation
    {
        public int Id { get; set; }

        [Required]
        public string CustomerId { get; set; }
        public ApplicationUser Customer { get; set; }

        // Cho phép null, admin có thể nhận sau này
        public string? AdminId { get; set; }
        public ApplicationUser Admin { get; set; }

        public DateTime LastUpdated { get; set; } = DateTime.UtcNow;

        public ICollection<ChatMessage> Messages { get; set; }
    }
}
