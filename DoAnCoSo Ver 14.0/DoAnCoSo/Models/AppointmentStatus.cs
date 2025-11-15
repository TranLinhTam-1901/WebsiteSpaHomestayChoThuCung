using System.ComponentModel.DataAnnotations;

namespace DoAnCoSo.Models
{
    public enum AppointmentStatus
    {
        [Display(Name = "Chờ xác nhận")]
        Pending,

        [Display(Name = "Đã xác nhận")]
        Confirmed,

        [Display(Name = "Đã hoàn thành")]
        Completed,

        [Display(Name = "Đã hủy")]
        Cancelled,

        [Display(Name = "Đã xóa")]
        Deleted
    }
}
