using DoAnCoSo.Models;
using System.ComponentModel.DataAnnotations;

namespace DoAnCoSo.ViewModels
{
    public class VetBookingViewModel
    {
        public int? AppointmentId { get; set; } // để biết đang sửa lịch nào

        [Required(ErrorMessage = "Vui lòng nhập số điện thoại.")]
        [Display(Name = "Số điện thoại")]
        [Phone(ErrorMessage = "Số điện thoại không hợp lệ.")]
        public string OwnerPhoneNumber { get; set; }

        [Display(Name = "Chọn thú cưng có sẵn")]
        public int? ExistingPetId { get; set; }

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

        [Required(ErrorMessage = "Vui lòng chọn dịch vụ thú y.")]
        [Display(Name = "Chọn dịch vụ thú y")]
        public int ServiceId { get; set; }

        [Display(Name = "Ghi chú (triệu chứng hoặc yêu cầu đặc biệt)")]
        public string? Note { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn ngày hẹn.")]
        [Display(Name = "Ngày hẹn")]
        [DataType(DataType.Date)]
        public DateTime AppointmentDate { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn giờ hẹn.")]
        [Display(Name = "Giờ hẹn")]
        [DataType(DataType.Time)]
        public TimeSpan AppointmentTime { get; set; }

        [Display(Name = "Giá dịch vụ")]
        public decimal? SelectedServicePrice { get; set; } = 0;

        public List<Pet> UserPets { get; set; } = new List<Pet>();
        public List<Service> VetServices { get; set; } = new List<Service>();

        public bool IsUpdate { get; set; } = false;

        [Required]
        public string UserId { get; set; }
    }
}
