using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using DoAnCoSo.Models;

namespace DoAnCoSo.ViewModels
{
    public class SpaBookingViewModel
    {
        [Required(ErrorMessage = "Vui lòng nhập số điện thoại.")]
        [Display(Name = "Số điện thoại")]
        [Phone(ErrorMessage = "Số điện thoại không hợp lệ.")]
        public string OwnerPhoneNumber { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập tên thú cưng.")]
        [Display(Name = "Tên thú cưng")]
        public string PetName { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập loại thú cưng.")]
        [Display(Name = "Loại thú cưng")]
        public string PetType { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn cân nặng của thú cưng.")]
        [Display(Name = "Chọn cân nặng của thú cưng")]
        public string PetWeight { get; set; }

        // Dịch vụ chính

        [Required(ErrorMessage = "Vui lòng chọn dịch vụ Spa.")]
        [Display(Name = "Chọn dịch vụ Spa")]
        public int ServiceId { get; set; }

        // Thời gian hẹn

        [Required(ErrorMessage = "Vui lòng chọn ngày hẹn.")]
        [Display(Name = "Ngày hẹn")]
        [DataType(DataType.Date)]
        public DateTime AppointmentDate { get; set; }


        [Required(ErrorMessage = "Vui lòng chọn giờ hẹn.")]
        [Display(Name = "Giờ hẹn")]
        [DataType(DataType.Time)]
        public TimeSpan AppointmentTime { get; set; }

        // Danh sách các dịch vụ Spa để hiển thị trong dropdown list
        //public List<Service> SpaServices { get; set; }


    }
}