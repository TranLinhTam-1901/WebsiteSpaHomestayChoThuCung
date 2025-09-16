
using Microsoft.AspNetCore.Mvc;
using DoAnCoSo.Models;
using System.Linq;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;


namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = SD.Role_Admin)]
    public class ServiceController : Controller
    {
        private readonly ApplicationDbContext _context;

        public ServiceController(ApplicationDbContext context)
        {
            _context = context;
        }

        // Hiển thị danh sách dịch vụ Spa
        public IActionResult Spa()
        {
            var spaServices = _context.Services.Where(s => s.Name.Contains("Spa")).ToList();
            return View(spaServices);
        }

        // Hiển thị danh sách dịch vụ Lưu trú
        public IActionResult LuuTru()
        {
            var luuTruServices = _context.Services.Where(s => s.Name.Contains("Lưu trú")).ToList();
            return View(luuTruServices);
        }

        // Hiển thị các đơn đặt lịch chờ xác nhận
        public IActionResult PendingAppointments()
        {
            var pendingAppointments = _context.Appointments
                .Include(a => a.User)
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Where(a => a.Status == AppointmentStatus.Pending)
                .ToList();

            return View(pendingAppointments);
        }

        // Duyệt đơn
        public IActionResult AcceptAppointment(int id)
        {
            var appointment = _context.Appointments.Find(id);
            if (appointment != null)
            {
                appointment.Status = AppointmentStatus.Confirmed;
                _context.SaveChanges();
            }
            return RedirectToAction("PendingAppointments");
        }

        // Hủy đơn
        public IActionResult CancelAppointment(int id)
        {
            var appointment = _context.Appointments.Find(id);
            if (appointment != null)
            {
                appointment.Status = AppointmentStatus.Cancelled;
                _context.SaveChanges();
            }
            return RedirectToAction("PendingAppointments");
        }

        //Xem lịch sử đặt lịch
        public IActionResult AppointmentHistory()
        {
            var history = _context.Appointments
                .Include(a => a.User)
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Where(a => a.Status != AppointmentStatus.Pending)
                .ToList();
            return View(history);
        }

        public async Task<IActionResult> AppointmentDetails(int id) // 'id' nhận giá trị từ asp-route-id="@item.AppointmentId"
        {
            // *** Nên kiểm tra Admin đã đăng nhập và có quyền không ở đây nếu Controller không có [Authorize] chung ***
            if (!User.Identity.IsAuthenticated || !User.IsInRole("Admin")) { return Forbid(); }

            // Tìm lịch đặt theo ID và NẠP các thông tin liên quan
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Service)

                .Include(a => a.User)


                .FirstOrDefaultAsync(a => a.AppointmentId == id);


            if (appointment == null)
            {
                return NotFound(); // Trả về lỗi 404 nếu không tìm thấy
            }

            // Trả về View AppointmentDetails và truyền đối tượng appointment với dữ liệu đã nạp
            return View(appointment);
        }
    }
}
