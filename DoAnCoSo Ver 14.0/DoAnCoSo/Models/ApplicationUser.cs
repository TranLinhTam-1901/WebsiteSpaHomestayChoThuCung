using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Identity;
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
    }
}
