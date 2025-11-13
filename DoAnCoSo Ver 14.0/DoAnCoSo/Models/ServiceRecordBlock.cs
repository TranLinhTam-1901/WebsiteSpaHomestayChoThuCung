using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnCoSo.Models
{
    public class ServiceRecordBlock
    {
        [Key]
        public int BlockId { get; set; }

        public int RecordId { get; set; }
        [ForeignKey("RecordId")]
        public PetServiceRecord PetServiceRecord { get; set; }

        [Required]
        public string CurrentHash { get; set; }

        public string? PreviousHash { get; set; }

        public DateTime Timestamp { get; set; }
    }
}
