using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class Pet
    {
        [Key]
        public int PetId { get; set; }

        [Required]
        public string Name { get; set; }

        [Required]
        public string Type { get; set; }

        public string? Breed { get; set; }
        public string? Gender { get; set; }
        public int? Age { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? ImageUrl { get; set; }

        public decimal? Weight { get; set; }
        public decimal? Height { get; set; }
        public string? Color { get; set; }
        public string? DistinguishingMarks { get; set; }

        public string? VaccinationRecords { get; set; }
        public string? MedicalHistory { get; set; }
        public string? Allergies { get; set; }
        public string? DietPreferences { get; set; }
        public string? HealthNotes { get; set; }
        public string? AI_AnalysisResult { get; set; }

        public string UserId { get; set; }
        [ForeignKey("UserId")]
        public virtual ApplicationUser User { get; set; }

        public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
        public ICollection<PetServiceRecord> ServiceRecords { get; set; } = new List<PetServiceRecord>();
    }
}
