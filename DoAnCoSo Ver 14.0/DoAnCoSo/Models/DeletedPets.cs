using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class DeletedPets
    {
        [Key]
        public int Id { get; set; } // Khóa riêng cho bảng DeletedPet

        public int OriginalPetId { get; set; } // Id của Pet cũ (để liên kết lại lịch sử)

        [Required]
        public string Name { get; set; } // Tên thú cưng

        [Required]
        public string Type { get; set; } // Loại thú cưng (chó, mèo…)

        public string? Breed { get; set; } // Giống
        public string? Gender { get; set; } // Giới tính
        public int? Age { get; set; }
        public decimal? Weight { get; set; }
        public string? ImageUrl { get; set; } // Ảnh nếu cần hiển thị

        public string UserId { get; set; } // Chủ sở hữu
        [ForeignKey("UserId")]
        public virtual ApplicationUser User { get; set; }

        public DateTime DeletedAt { get; set; } // Thời điểm xóa
        public string? DeletedBy { get; set; } // Ai xóa (Admin/User)
    }
}
