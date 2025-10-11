using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class PetServiceRecord
    {
        [Key]
        public int RecordId { get; set; }

        public int PetId { get; set; }
        public Pet Pet { get; set; }  // Restrict delete

        public int ServiceId { get; set; }
        public Service Service { get; set; }

        public DateTime DateUsed { get; set; }

        public string? Notes { get; set; }  // nullable
        public decimal? PriceAtThatTime { get; set; }
        public string? AI_Feedback { get; set; } // nullable
    }
}
