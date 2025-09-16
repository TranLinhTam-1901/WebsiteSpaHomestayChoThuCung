using System.ComponentModel.DataAnnotations;
using System.Collections.Generic;

namespace DoAnCoSo.Models
{
    public class Service
    {
        [Key]
        public int ServiceId { get; set; }

        [Required]
        public string? Name { get; set; }

        public string? Description { get; set; }
        public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    }
}