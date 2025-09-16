using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using DoAnCoSo.Models;
using Humanizer;

namespace DoAnCoSo.Models
{
    public class Pet
    {
        [Key]
        public int PetId { get; set; }

        [ForeignKey("UserId")]
        public string? UserId { get; set; }

      
        public string? Name { get; set; }

        public string? Type { get; set; }
        public int? Age { get; set; }

        // Navigation Property
        public virtual ApplicationUser User { get; set; }
        public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    }       
}
