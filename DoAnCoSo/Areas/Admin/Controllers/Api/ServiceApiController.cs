using DoAnCoSo.Models;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Areas.Admin.Controllers.Api
{
    [Area("Admin")]
    [Route("api/admin/Appointment")] // Route: api/admin/ServiceApi
    [ApiController]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Roles = "Admin")]
    public class ServiceApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly BlockchainService _blockchainService;

        public ServiceApiController(ApplicationDbContext context, BlockchainService blockchainService, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _blockchainService = blockchainService;
            _userManager = userManager;
        }

        // Helper để format dữ liệu Blockchain
        private object GetAppointmentBlockchainRecord(Appointment appointment, string performedBy)
        {
            var isHomestay = appointment.Service?.Category == ServiceCategory.Homestay;

            return new
            {
                appointment.AppointmentId,
                Status = appointment.Status.ToString(),
                DateInfo = isHomestay
                    ? $"{appointment.StartDate:dd/MM/yyyy} - {appointment.EndDate:dd/MM/yyyy}"
                    : $"{appointment.AppointmentDate:dd/MM/yyyy} {appointment.AppointmentTime:hh\\:mm}",
                PetId = appointment.PetId,
                PetName = appointment.Pet?.Name ?? appointment.DeletedPet?.Name,
                ServiceId = appointment.ServiceId,
                ServiceName = appointment.Service?.Name,
                UserId = appointment.UserId,
                UserName = appointment.User?.FullName ?? performedBy
            };
        }

        // 1. Lấy danh sách lịch hẹn chờ duyệt
        [HttpGet("pending")]
        public async Task<IActionResult> GetPendingAppointments()
        {
            var pendingAppointments = await _context.Appointments
                .Include(a => a.User)
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Where(a => a.Status == AppointmentStatus.Pending)
                .OrderByDescending(a => a.AppointmentId)
                .AsNoTracking()
                .ToListAsync();

            return Ok(pendingAppointments);
        }

        // 2. Lấy toàn bộ lịch sử lịch hẹn
        [HttpGet("history")]
        public async Task<IActionResult> GetHistory()
        {
            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Admin";

            var appointments = await _context.Appointments
                .Include(a => a.User)
                .Include(a => a.Pet)
                    .ThenInclude(p => p.ServiceRecords)
                        .ThenInclude(sr => sr.Service)
                .Include(a => a.DeletedPet)
                .Include(a => a.Service)
                .OrderByDescending(a => a.AppointmentId)
                .AsNoTracking()
                .ToListAsync();

            var result = appointments.Select(a => {
                // 1. Phân loại Category
                var category = a.Service?.Category;

                // 2. Trả về object hiển thị (Không đụng vào hàm GetAppointmentBlockchainRecord)
                return new
                {
                    a.AppointmentId,
                    // Logic thời gian: Homestay hiện khoảng ngày, Spa/Vet hiện Ngày + Giờ
                    TimeDisplay = category == ServiceCategory.Homestay
                        ? $"{a.StartDate:dd/MM/yyyy} - {a.EndDate:dd/MM/yyyy}"
                        : $"{a.AppointmentDate:dd/MM/yyyy} {a.AppointmentTime:hh\\:mm}",

                    CreatedDate = a.CreatedDate,
                    Status = a.Status.ToString(),

                    // Khách hàng
                    CustomerName = a.User?.FullName ?? "N/A",
                    CustomerPhone = a.User?.PhoneNumber ?? "N/A",

                    // Thú cưng (Check Pet hiện tại hoặc Pet đã xóa)
                    PetName = a.Pet?.Name ?? a.DeletedPet?.Name ?? "Thú cưng đã bị xóa",
                    PetType = a.Pet?.Type ?? a.DeletedPet?.Type ?? "N/A",

                    // Dịch vụ
                    ServiceName = a.Service?.Name ?? "N/A",
                    ServiceType = category.ToString(),
                    Price = a.Service?.Price ?? 0,

                    PerformedBy = performedBy
                };
            });

            return Ok(result);
        }

        // 3. Lấy chi tiết một lịch hẹn
        [HttpGet("{id}")]
        public async Task<IActionResult> GetAppointmentDetails(int id)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.DeletedPet) // Đã include
                .Include(a => a.Service)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == id);

            if (appointment == null)
                return NotFound(new { message = "Không tìm thấy lịch hẹn" });

            // Ưu tiên lấy Pet hiện tại, nếu null thì lấy DeletedPet
            var petInfo = appointment.Pet != null ? new
            {
                petId = appointment.Pet.PetId,
                name = appointment.Pet.Name,
                type = appointment.Pet.Type,
                breed = appointment.Pet.Breed
            } : appointment.DeletedPet != null ? new
            {
                petId = 0, // ID 0 hoặc null để đánh dấu đã xóa
                name = appointment.DeletedPet.Name,
                type = appointment.DeletedPet.Type,
                breed = appointment.DeletedPet.Breed
            } : null;

            return Ok(new
            {
                appointmentId = appointment.AppointmentId,
                status = appointment.Status,
                createdDate = appointment.CreatedDate,
                appointmentDate = appointment.AppointmentDate,
                appointmentTime = appointment.AppointmentTime,
                startDate = appointment.StartDate,
                endDate = appointment.EndDate,
                serviceName = appointment.Service?.Name,
                serviceCategory = appointment.Service?.Category.ToString(),
                note = appointment.Note,
                ownerPhoneNumber = appointment.OwnerPhoneNumber,
                user = appointment.User == null ? null : new
                {
                    userId = appointment.User.Id,
                    fullName = appointment.User.FullName,
                    phoneNumber = appointment.User.PhoneNumber
                },
                // ĐÃ SỬA: Trả về thông tin petInfo đã xử lý logic DeletedPet ở trên
                pet = petInfo
            });
        }

        // 4. Duyệt lịch hẹn
        [HttpPost("accept/{id}")]
        public async Task<IActionResult> AcceptedAppointment(int id)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Service)
                .Include(a => a.Pet)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == id);

            if (appointment == null) return NotFound(new { message = "Không tìm thấy lịch hẹn" });
            if (appointment.Status != AppointmentStatus.Pending)
                return BadRequest(new { message = "Chỉ có thể duyệt lịch hẹn đang chờ" });

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống Admin";

            appointment.Status = AppointmentStatus.Confirmed;
            await _context.SaveChangesAsync();

            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy);
                await _blockchainService.AddAppointmentBlockAsync(
                    record,
                    appointment.Service.Category.ToString(),
                    "ADMIN_CONFIRM",
                    performedBy
                );
            }

            return Ok(new { message = "Đã duyệt lịch hẹn thành công", id = appointment.AppointmentId });
        }

        // 5. Hủy lịch hẹn
        [HttpPost("cancel/{id}")]
        public async Task<IActionResult> CanceledAppointment(int id)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Service)
                .Include(a => a.Pet)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == id);

            if (appointment == null) return NotFound(new { message = "Không tìm thấy lịch hẹn" });

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống Admin";

            appointment.Status = AppointmentStatus.Cancelled;
            await _context.SaveChangesAsync();

            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy);
                await _blockchainService.AddAppointmentBlockAsync(
                    record,
                    appointment.Service.Category.ToString(),
                    "ADMIN_CANCEL",
                    performedBy
                );
            }

            return Ok(new { message = "Đã hủy lịch hẹn thành công", id = appointment.AppointmentId });
        }
    }
}