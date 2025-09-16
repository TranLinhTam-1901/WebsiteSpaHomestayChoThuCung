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
            // Lấy danh sách các dịch vụ Spa từ database
            var spaServices = _context.SpaServices.ToList();

            // Tạo ViewModel
            var viewModel = new SpaBookingViewModel
            {
                AppointmentDate = DateTime.Now ,// Gán ngày hiện tại làm giá trị mặc định
                AppointmentTime = new TimeSpan(9, 0, 0)
            };

            // Truyền danh sách dịch vụ qua ViewBag
            ViewBag.SpaServices = spaServices;

            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> BookAppointmentSpa(SpaBookingViewModel model)
        {
            // Kiểm tra xem người dùng đã đăng nhập chưa
            if (!User.Identity.IsAuthenticated)
            {
                return RedirectToPage("/Account/Login", new { area = "Identity" });
            }

            if (ModelState.IsValid)
            {
                try
                {
                    // Lấy thông tin dịch vụ từ database dựa trên model.ServiceId
                    var selectedService = await _context.SpaServices.FindAsync(model.ServiceId);

                    if (selectedService == null)
                    {
                        ModelState.AddModelError("", "Dịch vụ bạn chọn không tồn tại.");
                        // Load lại dữ liệu cần thiết cho view (nếu cần hiển thị lại dropdown)
                        ViewBag.SpaServices = _context.SpaServices.ToList();
                        return View(model);
                    }

                    

                    // Tạo đối tượng Appointment mới
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

                    // Chuyển hướng đến trang xác nhận
                    return RedirectToAction("AppointmentConfirmation");
                }
                catch (DbUpdateException ex)
                {
                    // Ghi log lỗi hoặc xử lý lỗi liên quan đến database
                    ModelState.AddModelError("", "Đã có lỗi xảy ra khi lưu thông tin đặt lịch vào database. Vui lòng thử lại sau.");
                    // Bạn có thể ghi log exception ex ở đây để xem chi tiết lỗi
                }
                catch (Exception ex)
                {
                    // Ghi log lỗi hoặc xử lý các lỗi khác
                    ModelState.AddModelError("", "Đã có lỗi không mong muốn xảy ra. Vui lòng thử lại sau.");
                    // Bạn có thể ghi log exception ex ở đây để xem chi tiết lỗi
                }
            }

            // Nếu ModelState không hợp lệ hoặc có lỗi xảy ra trong try-catch, load lại danh sách dịch vụ
            ViewBag.SpaServices = _context.SpaServices.ToList();
            return View(model);
        }

        public IActionResult BookAppointmentHomestay()
        {
            var homestayServices = _context.HomestayServices.ToList();

            // Tạo ViewModel
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
            // Kiểm tra xem người dùng đã đăng nhập chưa
            if (!User.Identity.IsAuthenticated)
            {
                return RedirectToPage("/Account/Login", new { area = "Identity" });
            }

            if (ModelState.IsValid)
            {
                try
                {
                    // Lấy thông tin dịch vụ từ database dựa trên model.ServiceId
                    var selectedService = await _context.HomestayServices.FindAsync(model.ServiceId);

                    if (selectedService == null)
                    {
                        ViewBag.HomestayServices = _context.HomestayServices.ToList();
                        return View(model);
                    }

                    // Tạo đối tượng Appointment mới
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
                catch (DbUpdateException)
                {
                    ModelState.AddModelError("", "Đã có lỗi xảy ra khi lưu thông tin đặt lịch vào database. Vui lòng thử lại sau.");
                }
                catch (Exception)
                {
                    ModelState.AddModelError("", "Đã có lỗi không mong muốn xảy ra. Vui lòng thử lại sau.");
                }
            }
            ViewBag.HomestayServices = _context.HomestayServices.ToList();
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