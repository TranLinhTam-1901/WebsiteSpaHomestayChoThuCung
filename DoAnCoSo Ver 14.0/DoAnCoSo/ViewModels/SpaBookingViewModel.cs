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

        // Chọn thú cưng có sẵn
        [Display(Name = "Chọn thú cưng có sẵn")]
        public int? ExistingPetId { get; set; }  // Nullable, không bắt buộc

        [Required(ErrorMessage = "Vui lòng nhập tên thú cưng.")]
        [Display(Name = "Tên thú cưng")]
        public string PetName { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập loại thú cưng.")]
        [Display(Name = "Loại thú cưng")]
        public string PetType { get; set; }

        [Display(Name = "Giống thú cưng")]
        public string? PetBreed { get; set; }

        [Display(Name = "Tuổi thú cưng")]
        public int? PetAge { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn cân nặng của thú cưng.")]
        [Display(Name = "Chọn cân nặng của thú cưng")]
        public decimal? PetWeight { get; set; }

        // Dịch vụ Spa
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

        // Danh sách thú cưng của user để dropdown
        public List<Pet> UserPets { get; set; } = new List<Pet>();

        public decimal? CalculatedPrice { get; set; }
    }
}
