using DoAnCoSo.Models;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Controllers
{
    public class AppointmentsController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public AppointmentsController(ApplicationDbContext context, UserManager<ApplicationUser> userManager = null)
        {
            _context = context;
            _userManager = userManager;
        }

        public IActionResult BookAppointmentSpa()
        {
            // Lấy danh sách các dịch vụ Spa từ bảng Services
            var spaServices = _context.Services
                .Where(s => s.Category == ServiceCategory.Spa)
                .ToList();

            var viewModel = new SpaBookingViewModel
            {
                AppointmentDate = DateTime.Now,
                AppointmentTime = new TimeSpan(9, 0, 0)
            };

            ViewBag.SpaServices = spaServices;

            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> BookAppointmentSpa(SpaBookingViewModel model)
        {
            if (!User.Identity.IsAuthenticated)
            {
                return RedirectToPage("/Account/Login", new { area = "Identity" });
            }

            if (ModelState.IsValid)
            {
                try
                {
                    var selectedService = await _context.Services
                        .FirstOrDefaultAsync(s => s.ServiceId == model.ServiceId && s.Category == ServiceCategory.Spa);

                    if (selectedService == null)
                    {
                        ViewBag.SpaServices = _context.Services.Where(s => s.Category == ServiceCategory.Spa).ToList();
                        return View(model);
                    }

                    var appointment = new Appointment
                    {
                        AppointmentDate = model.AppointmentDate,
                        AppointmentTime = model.AppointmentTime,
                        Status = AppointmentStatus.Pending,
                        ServiceId = model.ServiceId,
                        Pet = new Pet { Name = model.PetName, Type = model.PetType },
                        UserId = _userManager.GetUserId(User),
                        CreatedDate = DateTime.UtcNow,
                        OwnerPhoneNumber = model.OwnerPhoneNumber
                    };

                    _context.Appointments.Add(appointment);
                    await _context.SaveChangesAsync();

                    return RedirectToAction("AppointmentConfirmation");
                }
                catch (Exception)
                {
                    ModelState.AddModelError("", "Đã có lỗi xảy ra khi lưu thông tin đặt lịch.");
                }
            }

            ViewBag.SpaServices = _context.Services.Where(s => s.Category == ServiceCategory.Spa).ToList();
            return View(model);
        }

        public IActionResult BookAppointmentHomestay()
        {
            var homestayServices = _context.Services
                .Where(s => s.Category == ServiceCategory.Homestay)
                .ToList();

            var viewModel = new HomestayBookingViewModel
            {
                StartDate = DateTime.Now,
                EndDate = DateTime.Now
            };

            ViewBag.HomestayServices = homestayServices;
            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> BookAppointmentHomestay(HomestayBookingViewModel model)
        {
            if (!User.Identity.IsAuthenticated)
            {
                return RedirectToPage("/Account/Login", new { area = "Identity" });
            }

            if (ModelState.IsValid)
            {
                try
                {
                    var selectedService = await _context.Services
                        .FirstOrDefaultAsync(s => s.ServiceId == model.ServiceId && s.Category == ServiceCategory.Homestay);

                    if (selectedService == null)
                    {
                        ViewBag.HomestayServices = _context.Services.Where(s => s.Category == ServiceCategory.Homestay).ToList();
                        return View(model);
                    }

                    var appointment = new Appointment
                    {
                        StartDate = model.StartDate,
                        EndDate = model.EndDate,
                        Status = AppointmentStatus.Pending,
                        ServiceId = model.ServiceId,
                        Pet = new Pet { Name = model.PetName, Type = model.PetType },
                        UserId = _userManager.GetUserId(User),
                        CreatedDate = DateTime.UtcNow,
                        OwnerPhoneNumber = model.OwnerPhoneNumber
                    };

                    _context.Appointments.Add(appointment);
                    await _context.SaveChangesAsync();

                    return RedirectToAction("AppointmentConfirmation");
                }
                catch (Exception)
                {
                    ModelState.AddModelError("", "Đã có lỗi xảy ra khi lưu thông tin đặt lịch.");
                }
            }

            ViewBag.HomestayServices = _context.Services.Where(s => s.Category == ServiceCategory.Homestay).ToList();
            return View(model);
        }

        public IActionResult AppointmentConfirmation()
        {
            return View();
        }

        public IActionResult AppointmentSuccess()
        {
            return View();
        }
        public IActionResult CustomerAppointmentHistory()
        {
            var userId = _userManager.GetUserId(User);

            var customerHistory = _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Where(a => a.UserId == userId)
                .ToList();

            return View(customerHistory);
        }

        public async Task<IActionResult> AppointmentDetails(int id) // 'id' sẽ nhận giá trị từ asp-route-id="@item.AppointmentId"
        {
            // Kiểm tra xem người dùng đã đăng nhập chưa (Chỉ cho phép xem lịch sử của họ)
            if (!User.Identity.IsAuthenticated)
            {
                return RedirectToPage("/Account/Login", new { area = "Identity" });
            }

            var userId = _userManager.GetUserId(User);

            // Tìm lịch đặt theo ID VÀ đảm bảo nó thuộc về người dùng hiện tại
            var appointment = await _context.Appointments
                .Include(a => a.Pet)     // Nạp thông tin Pet
                .Include(a => a.Service) // Nạp thông tin Service
                                         // .Include(a => a.ApplicationUser) // Nạp thông tin người dùng (để lấy SDT)
                .FirstOrDefaultAsync(a => a.AppointmentId == id && a.UserId == userId); // Hoặc a.ApplicationUserId == userId

            // Xử lý nếu không tìm thấy lịch đặt hoặc lịch đặt không thuộc về người dùng
            if (appointment == null)
            {
                return NotFound(); // Hoặc chuyển hướng về trang lịch sử với thông báo lỗi
            }

            // Trả về View AppointmentDetails và truyền đối tượng appointment
            return View(appointment);
        }
    }
}