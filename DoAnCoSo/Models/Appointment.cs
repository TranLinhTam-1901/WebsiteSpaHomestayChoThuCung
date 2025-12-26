using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class Appointment
    {
        [Key]
        public int AppointmentId { get; set; }

        public string UserId { get; set; }
        [ForeignKey("UserId")]
        public virtual ApplicationUser User { get; set; }

        public int? PetId { get; set; }
        [ForeignKey("PetId")]
        public virtual Pet Pet { get; set; }

        public int ServiceId { get; set; }
        [ForeignKey("ServiceId")]
        public virtual Service Service { get; set; }

        public DateTime AppointmentDate { get; set; }
        [DataType(DataType.Time)]
        public TimeSpan AppointmentTime { get; set; }

        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }

        public AppointmentStatus Status { get; set; }

        public DateTime CreatedDate { get; set; }

        public string OwnerPhoneNumber { get; set; }

        public int? DeletedPetId { get; set; }
        [ForeignKey("DeletedPetId")]
        public virtual DeletedPets DeletedPet { get; set; }

        [MaxLength(500)]
        public string? Note { get; set; }
    }
}
