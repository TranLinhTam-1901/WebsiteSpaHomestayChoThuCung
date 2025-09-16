using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace DoAnCoSo.Models
{
    public class Appointment
    {
        [Key]
        public int AppointmentId { get; set; }

        public string UserId { get; set; }  // Tham chiếu đến AspNetUsers
        [ForeignKey("UserId")]
        public virtual ApplicationUser User { get; set; }

        public int PetId { get; set; }
        [ForeignKey("PetId")]
        public virtual Pet Pet { get; set; }

        public int ServiceId { get; set; }
        [ForeignKey("ServiceId")]
   
        public virtual Service Service { get; set; }

        public DateTime AppointmentDate { get; set; }
        [DataType(DataType.Time)] // Thêm attribute này nếu bạn muốn định dạng hiển thị thời gian
        public TimeSpan AppointmentTime { get; set; } // Thêm thuộc tính này
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public AppointmentStatus Status { get; set; }

        public DateTime CreatedDate { get; set; }

        public string OwnerPhoneNumber { get; set; }

    }
}
