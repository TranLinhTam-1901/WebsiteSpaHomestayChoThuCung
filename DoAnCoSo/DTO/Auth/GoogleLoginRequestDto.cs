using System.ComponentModel.DataAnnotations;

namespace DoAnCoSo.DTO.Auth
{
    public class GoogleLoginRequestDto
    {
        [Required]
        public string Email { get; set; }

        [Required]
        public string FullName { get; set; }

        [Required]
        public string FirebaseUid { get; set; }

        public string? AvatarUrl { get; set; }
    }
}
