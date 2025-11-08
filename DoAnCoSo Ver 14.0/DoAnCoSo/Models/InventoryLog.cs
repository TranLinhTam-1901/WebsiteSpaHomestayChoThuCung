using System.ComponentModel.DataAnnotations;

namespace DoAnCoSo.Models
{
    public class InventoryLog
    {
        public int Id { get; set; }

        public int ProductId { get; set; }
        public Product Product { get; set; } = default!;

        public int QuantityChange { get; set; } 

        [MaxLength(40)]
        public string Reason { get; set; } = "Manual"; 

        [MaxLength(50)]
        public string? ReferenceId { get; set; } 

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public string? PerformedByUserId { get; set; }

        [MaxLength(200)]
        public string? Note { get; set; }
    }
}
