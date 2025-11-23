using System;
using System.ComponentModel.DataAnnotations;

namespace DoAnCoSo.Models.Blockchain
{
    public class BlockchainRecord
    {
        [Key]
        public int Id { get; set; } // ✅ Primary Key

        public int BlockNumber { get; set; } // ✅ Thứ tự block

        [Required]
        public string RecordType { get; set; } // Pet / Appointment

        [Required]
        public string Operation { get; set; } // Create / Update / Delete

        [Required]
        public string ReferenceId { get; set; } // PetId hoặc AppointmentId

        [Required]
        public string DataJson { get; set; } // ✅ Dữ liệu JSON

        [Required]
        public string Hash { get; set; }

        public string PreviousHash { get; set; }

        public DateTime Timestamp { get; set; } = DateTime.Now;

        public string PerformedBy { get; set; }

        public string? TransactionHash { get; set; } // optional
    }
}
