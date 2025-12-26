using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations;
namespace DoAnCoSo.Models
{
    public class ApplicationUser : IdentityUser
    {
        [Required]
        public string FullName { get; set; }
        public string? Address { get; set; }
        public string PhoneNumber { get; set; }
        public virtual ICollection<Pet> Pets { get; set; }
        public virtual ICollection<Appointment> Appointments { get; set; }
        public ICollection<Favorite> Favorites { get; set; }

        // Public key (Base64 of exported public key bytes)
        public string? PublicKey { get; set; }

        // Private key (Base64 of exported private key bytes)
        // **Cảnh báo**: private key lưu ở DB = server có thể giải mã.
        public string? PrivateKey { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        // phân biệt kiểu đăng nhập
        public string LoginProvider { get; set; } = "Local";
        // lưu firebaseUid
        public string? ExternalProviderId { get; set; }
        // phân biệt có dùng password hay không 
        public bool IsExternalLogin { get; set; } = false;

    }
}
