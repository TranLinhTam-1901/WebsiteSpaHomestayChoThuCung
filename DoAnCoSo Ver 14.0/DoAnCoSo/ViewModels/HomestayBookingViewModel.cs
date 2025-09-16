﻿using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using DoAnCoSo.Models;

namespace DoAnCoSo.ViewModels
{
    public class HomestayBookingViewModel
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

        [Required(ErrorMessage = "Vui lòng chọn loại phòng.")]
        [Display(Name = "Chọn loại phòng")]
        public int ServiceId { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn ngày nhận.")]
        [Display(Name = "Ngày bắt đầu gửi")]
        [DataType(DataType.Date)]
        public DateTime StartDate { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn ngày trả.")]
        [Display(Name = "Ngày kết thúc gửi")]
        [DataType(DataType.Date)]
        public DateTime EndDate { get; set; }
    }
}
