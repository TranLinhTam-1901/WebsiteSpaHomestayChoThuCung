using System;
using System.ComponentModel.DataAnnotations;

namespace DoAnCoSo.Models
{
    public class ChatImage
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(255)]
        public string FileName { get; set; } = string.Empty; // Tên file trong wwwroot/uploads/chat

        [Required]
        [StringLength(500)]
        public string FilePath { get; set; } = string.Empty; // Ví dụ: /uploads/chat/abc.jpg

        [Required]
        [StringLength(200)]
        public string Token { get; set; } = string.Empty; // Token duy nhất để truy cập ảnh

        public DateTime ExpireAt { get; set; } // Ngày hết hạn token

        public string? UploaderId { get; set; } // Ai đã gửi ảnh này
        public ApplicationUser? Uploader { get; set; }
    }
}
