using Microsoft.AspNetCore.Mvc;
using DoAnCoSo.Models;
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

        // Hiển thị các đơn đặt lịch chờ xác nhận
        public async Task<IActionResult> PendingAppointments()
        {
            var pendingAppointments = await _context.Appointments
                .Include(a => a.User)
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Where(a => a.Status == AppointmentStatus.Pending)
                .OrderBy(a => a.AppointmentDate) // có thể sắp xếp theo ngày đặt
                .AsNoTracking()
                .ToListAsync();

            return View(pendingAppointments);
        }

        // Duyệt đơn
        [HttpPost]
        public async Task<IActionResult> AcceptAppointment(int id)
        {
            var appointment = await _context.Appointments.FindAsync(id);
            if (appointment != null)
            {
                appointment.Status = AppointmentStatus.Confirmed; // hoặc Cancelled
                await _context.SaveChangesAsync();
            }

            return RedirectToAction(nameof(PendingAppointments));
        }

        // Hủy đơn
        [HttpPost]
        public async Task<IActionResult> CancelAppointment(int id)
        {
            var appointment = await _context.Appointments.FindAsync(id);
            if (appointment != null)
            {
                appointment.Status = AppointmentStatus.Cancelled; // hoặc Confirmed
                await _context.SaveChangesAsync();
            }

            return RedirectToAction(nameof(PendingAppointments));
        }

        // Xem lịch sử đặt lịch (không còn Pending)
        public async Task<IActionResult> AppointmentHistory()
        {
            var history = await _context.Appointments
                .Include(a => a.User)
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Where(a => a.Status != AppointmentStatus.Pending)
                .OrderByDescending(a => a.AppointmentDate)
                .AsNoTracking()
                .ToListAsync();

            return View(history);
        }

        // Xem chi tiết một lịch đặt
        public async Task<IActionResult> AppointmentDetails(int id)
        {
            var appointment = await _context.Appointments
                .Include(a => a.User)
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .FirstOrDefaultAsync(a => a.AppointmentId == id);

            if (appointment == null)
                return NotFound();

            return View(appointment);
        }
    }
}
