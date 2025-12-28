using DoAnCoSo.Models;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Controllers.Api
{
    [Route("api/Appointments")]
    [ApiController]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
    public class AppointmentsApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly BlockchainService _blockchainService;

        public AppointmentsApiController(
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager,
            BlockchainService blockchainService)
        {
            _context = context;
            _userManager = userManager;
            _blockchainService = blockchainService;
        }

        private object GetAppointmentBlockchainRecord(Appointment appointment, string performedBy, bool isForView = true)
        {
            var pName = appointment.Pet?.Name ?? appointment.DeletedPet?.Name ?? "Thú cưng đã xoá";
            var pType = appointment.Pet?.Type ?? appointment.DeletedPet?.Type ?? "";
            var pBreed = appointment.Pet?.Breed ?? appointment.DeletedPet?.Breed ?? "";
            bool isHomestay = appointment.Service?.Category == ServiceCategory.Homestay;

            // --- TRƯỜNG HỢP 1: LƯU BLOCKCHAIN (NGẮN GỌN THEO MẪU BẠN CẦN) ---
            if (!isForView)
            {
                if (isHomestay)
                {
                    return new
                    {
                        appointment.AppointmentId,
                        appointment.Status,
                        StartDate = appointment.StartDate.ToString("dd/MM/yyyy"),
                        EndDate = appointment.EndDate.ToString("dd/MM/yyyy"),
                        PetId = appointment.PetId,
                        PetName = pName,
                        PetType = pType,
                        PetBreed = pBreed,
                        ServiceId = appointment.ServiceId,
                        ServiceName = appointment.Service?.Name,
                        UserId = appointment.UserId,
                        UserName = appointment.User?.FullName ?? performedBy
                    };
                }
                else
                {
                    return new
                    {
                        appointment.AppointmentId,
                        appointment.Status,
                        AppointmentDate = appointment.AppointmentDate.ToString("dd/MM/yyyy"),
                        AppointmentTime = appointment.AppointmentTime.ToString(@"hh\:mm"),
                        PetId = appointment.PetId,
                        PetName = pName,
                        PetType = pType,
                        PetBreed = pBreed,
                        ServiceId = appointment.ServiceId,
                        ServiceName = appointment.Service?.Name,
                        UserId = appointment.UserId,
                        UserName = appointment.User?.FullName ?? performedBy
                    };
                }
            }

            // --- TRƯỜNG HỢP 2: VIEW GIAO DIỆN (JSON FULL ĐỂ CHẠY WIDGET) ---
            // Khởi tạo object chi tiết để tránh lỗi Implicit Conversion
            object detailedPet = null;
            if (appointment.Pet != null)
            {
                detailedPet = new
                {
                    Name = pName,
                    Type = pType,
                    Breed = pBreed,
                    Gender = appointment.Pet.Gender,
                    Age = appointment.Pet.Age?.ToString(),
                    Weight = appointment.Pet.Weight,
                    Height = appointment.Pet.Height,
                    Color = appointment.Pet.Color,
                    DistinguishingMarks = appointment.Pet.DistinguishingMarks,
                    VaccinationRecords = appointment.Pet.VaccinationRecords,
                    MedicalHistory = appointment.Pet.MedicalHistory,
                    Allergies = appointment.Pet.Allergies,
                    DietPreferences = appointment.Pet.DietPreferences,
                    HealthNotes = appointment.Pet.HealthNotes,
                    AI_AnalysisResult = appointment.Pet.AI_AnalysisResult,
                    isDeleted = false
                };
            }
            else if (appointment.DeletedPet != null)
            {
                detailedPet = new
                {
                    Name = pName,
                    Type = pType,
                    Breed = pBreed,
                    Gender = appointment.DeletedPet.Gender,
                    Age = appointment.DeletedPet.Age?.ToString(),
                    Weight = (decimal?)appointment.DeletedPet.Weight, // Ép kiểu decimal để đồng nhất
                    Height = (decimal?)null,
                    Color = (string)null,
                    DistinguishingMarks = (string)null,
                    VaccinationRecords = (string)null,
                    MedicalHistory = (string)null,
                    Allergies = (string)null,
                    DietPreferences = (string)null,
                    HealthNotes = (string)null,
                    AI_AnalysisResult = (string)null,
                    isDeleted = true
                };
            }

            return new
            {
                appointment.AppointmentId,
                Status = (int)appointment.Status,
                StatusDisplay = appointment.Status.ToString(),
                PetName = pName,
                PetType = pType,
                PetBreed = pBreed,
                Pet = detailedPet, // Object full cho Flutter
                ServiceName = appointment.Service?.Name,
                ServiceCategory = appointment.Service?.Category.ToString(),
                StartDate = isHomestay ? appointment.StartDate.ToString("dd/MM/yyyy") : null,
                EndDate = isHomestay ? appointment.EndDate.ToString("dd/MM/yyyy") : null,
                AppointmentDate = !isHomestay ? appointment.AppointmentDate.ToString("dd/MM/yyyy") : null,
                AppointmentTime = !isHomestay ? appointment.AppointmentTime.ToString(@"hh\:mm") : null,
                CreatedDate = appointment.CreatedDate.ToString("dd/MM/yyyy HH:mm"),
                appointment.UserId,
                UserName = appointment.User?.FullName ?? performedBy,
                appointment.OwnerPhoneNumber,
                appointment.Note
            };
        }

        [HttpGet("GetUserPets")] // <--- Route đầy đủ: api/Pets/GetUserPets
        public async Task<IActionResult> GetUserPets()
        {
            var userId = _userManager.GetUserId(User);
            var pets = await _context.Pets.Where(p => p.UserId == userId).ToListAsync();
            return Ok(pets);
        }

        // ================= SPA =================
        [HttpGet("MyAppointments")]
        public async Task<IActionResult> MyAppointments()
        {
            var userId = _userManager.GetUserId(User);
            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            var appointments = await _context.Appointments
                .Include(a => a.Pet)
                    .ThenInclude(p => p.ServiceRecords)
                        .ThenInclude(sr => sr.Service)
                .Include(a => a.DeletedPet) // ⭐ BẮT BUỘC
                .Include(a => a.Service)
                .Where(a => a.UserId == userId)
                .OrderByDescending(a => a.CreatedDate)
                .ToListAsync();

            return Ok(appointments.Select(a => GetAppointmentBlockchainRecord(a, performedBy, isForView: true)));
        }

        [HttpGet("SpaServices")]
        public async Task<IActionResult> GetSpaServices()
        {
            var services = await _context.Services
                .Where(s => s.Category == ServiceCategory.Spa)
                .Select(s => new {
                    s.ServiceId,
                    s.Name,
                    s.Description,
                    // Chỉ lấy dữ liệu bảng giá, không lấy ngược lại Service
                    SpaPricing = _context.SpaPricings.FirstOrDefault(p => p.ServiceId == s.ServiceId)
                })
                .ToListAsync();

            return Ok(services);
        }

        [HttpPost("BookSpa")]
        // Đổi tên biến từ 'model' thành 'request'
        public async Task<IActionResult> BookSpa([FromBody] SpaBookingViewModel request)
        {
            var userId = _userManager.GetUserId(User);
            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Khách hàng";

            Pet pet;
            if (request.ExistingPetId.HasValue && request.ExistingPetId.Value > 0)
            {
                pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == request.ExistingPetId.Value && p.UserId == userId);
                if (pet == null) return BadRequest("Thú cưng không tồn tại.");

                // Dùng 'request' thay vì 'model'
                request.PetName ??= pet.Name;
                request.PetType ??= pet.Type;
                request.PetWeight ??= pet.Weight;
                request.PetBreed ??= pet.Breed;
            }
            else
            {
                pet = new Pet
                {
                    Name = request.PetName,
                    Type = request.PetType,
                    Breed = request.PetBreed,
                    Weight = request.PetWeight ?? 0,
                    UserId = userId
                };
                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();
            }

            var appointment = new Appointment
            {
                AppointmentDate = request.AppointmentDate,
                AppointmentTime = request.AppointmentTime,
                Status = AppointmentStatus.Pending,
                ServiceId = request.ServiceId,
                UserId = userId,
                PetId = pet.PetId,
                OwnerPhoneNumber = request.OwnerPhoneNumber ?? currentUser?.PhoneNumber ?? "0000000000",
                CreatedDate = DateTime.UtcNow
            };

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            appointment.Pet = pet;
            appointment.Service = await _context.Services.FindAsync(request.ServiceId);
            appointment.User = currentUser;

            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy, isForView: false);
                await _blockchainService.AddAppointmentBlockAsync(record, "Spa", "ADD", performedBy);
            }

            return Ok(new
            {
                message = "Thành công",
                appointment = GetAppointmentBlockchainRecord(appointment, performedBy, isForView: true)
            });
        }

        [HttpPut("UpdateSpa/{id}")]
        public async Task<IActionResult> UpdateSpa(int id, [FromBody] SpaBookingViewModel request)
        {
            var userId = _userManager.GetUserId(User);
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == id && a.UserId == userId);

            if (appointment == null) return NotFound("Không tìm thấy lịch hẹn.");

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            // Kiểm tra logic thời gian (Sửa trước 1 ngày)
            var today = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time")).Date;
            if (appointment.AppointmentDate.Date <= today)
                return BadRequest("Chỉ được chỉnh sửa lịch hẹn trước ngày diễn ra ít nhất 1 ngày.");

            // Cập nhật thông tin
            appointment.AppointmentDate = request.AppointmentDate;
            appointment.AppointmentTime = request.AppointmentTime;
            appointment.ServiceId = request.ServiceId;

            // Nếu đổi Pet
            if (request.ExistingPetId.HasValue && appointment.PetId != request.ExistingPetId)
            {
                var newPet = await _context.Pets.FindAsync(request.ExistingPetId);
                if (newPet != null && newPet.UserId == userId) appointment.Pet = newPet;
            }

            await _context.SaveChangesAsync();

            // Ghi Blockchain log cập nhật
            if (_blockchainService != null)
            {
                // 1. Lưu vào Blockchain: Truyền false để lấy bản NGẮN GỌN (giống hàm cũ của bạn)
                var blockchainRecord = GetAppointmentBlockchainRecord(appointment, performedBy, isForView: false);
                await _blockchainService.AddAppointmentBlockAsync(blockchainRecord, "Spa", "UPDATE", performedBy);
            }

            // 2. Trả về cho App Flutter/Web: Truyền true để lấy bản ĐẦY ĐỦ (chứa object Pet, StatusDisplay...)
            return Ok(new
            {
                message = "Cập nhật lịch hẹn thành công.",
                appointment = GetAppointmentBlockchainRecord(appointment, performedBy, isForView: true)
            });
        }

        // ================= HOMESTAY =================
        [HttpPost("BookHomestay")]
        public async Task<IActionResult> BookHomestay([FromBody] HomestayBookingViewModel model)
        {
            var userId = _userManager.GetUserId(User);
            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            var selectedService = await _context.Services
                .FirstOrDefaultAsync(s => s.ServiceId == model.ServiceId && s.Category == ServiceCategory.Homestay);

            if (selectedService == null) return BadRequest("Loại phòng không hợp lệ.");

            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId.Value && p.UserId == userId);
                if (pet == null) return BadRequest("Thú cưng không hợp lệ.");
            }
            else
            {
                pet = new Pet
                {
                    Name = model.PetName,
                    Type = model.PetType,
                    Breed = model.PetBreed,
                    Age = model.PetAge,
                    Weight = model.PetWeight,
                    UserId = userId
                };
                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();
            }

            var appointment = new Appointment
            {
                StartDate = model.StartDate,
                EndDate = model.EndDate,
                Status = AppointmentStatus.Pending,
                ServiceId = selectedService.ServiceId,
                UserId = userId,
                CreatedDate = DateTime.UtcNow,
                PetId = pet.PetId
            };

            var user = await _userManager.GetUserAsync(User);
            appointment.OwnerPhoneNumber = user.PhoneNumber;

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            await _context.Entry(appointment).Reference(a => a.Pet).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.Service).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.User).LoadAsync();

            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy);
                await _blockchainService.AddAppointmentBlockAsync(record, "Homestay", "ADD", performedBy);
            }

            return Ok(new { message = "Đặt Homestay thành công.", appointment = GetAppointmentBlockchainRecord(appointment, performedBy) });
        }

        [HttpPut("UpdateHomestay/{id}")]
        public async Task<IActionResult> UpdateHomestay(int id, [FromBody] HomestayBookingViewModel model)
        {
            var userId = _userManager.GetUserId(User);
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == id && a.UserId == userId);

            if (appointment == null) return NotFound();

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            var today = TimeZoneInfo.ConvertTimeFromUtc(
                DateTime.UtcNow,
                TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time")
            ).Date;

            if ((appointment.StartDate.Date - today).TotalDays < 2)
                return BadRequest("Homestay chỉ được sửa trước 2 ngày.");

            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId.Value && p.UserId == userId);
                if (pet == null) return BadRequest("Thú cưng không hợp lệ.");
            }
            else
            {
                pet = new Pet
                {
                    Name = model.PetName,
                    Type = model.PetType,
                    Breed = model.PetBreed,
                    Age = model.PetAge,
                    Weight = model.PetWeight,
                    UserId = userId
                };
                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();
            }

            appointment.PetId = pet.PetId;
            appointment.ServiceId = model.ServiceId;
            appointment.StartDate = model.StartDate;
            appointment.EndDate = model.EndDate;
            appointment.OwnerPhoneNumber = model.OwnerPhoneNumber;

            await _context.SaveChangesAsync();

            await _context.Entry(appointment).Reference(a => a.Pet).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.Service).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.User).LoadAsync();

            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy);
                await _blockchainService.AddAppointmentBlockAsync(record, "Homestay", "UPDATE", performedBy);
            }

            return Ok(new { message = "Cập nhật Homestay thành công.", appointment = GetAppointmentBlockchainRecord(appointment, performedBy) });
        }

        // ================= VET =================
        [HttpPost("BookVet")]
        public async Task<IActionResult> BookVet([FromBody] VetBookingViewModel model)
        {
            var userId = _userManager.GetUserId(User);
            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            var selectedService = await _context.Services
                .FirstOrDefaultAsync(s => s.ServiceId == model.ServiceId && s.Category == ServiceCategory.Vet);

            if (selectedService == null) return BadRequest("Dịch vụ thú y không hợp lệ.");

            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId.Value && p.UserId == userId);
                if (pet == null) return BadRequest("Thú cưng không hợp lệ.");
            }
            else
            {
                pet = new Pet
                {
                    Name = model.PetName,
                    Type = model.PetType,
                    Breed = model.PetBreed,
                    Age = model.PetAge,
                    Weight = model.PetWeight,
                    UserId = userId
                };
                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();
            }

            var appointment = new Appointment
            {
                AppointmentDate = model.AppointmentDate,
                AppointmentTime = model.AppointmentTime,
                Status = AppointmentStatus.Pending,
                ServiceId = selectedService.ServiceId,
                UserId = userId,
                CreatedDate = DateTime.UtcNow,
                PetId = pet.PetId,
                Note = model.Note
            };

            var user = await _userManager.GetUserAsync(User);
            appointment.OwnerPhoneNumber = user.PhoneNumber;

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            await _context.Entry(appointment).Reference(a => a.Pet).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.Service).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.User).LoadAsync();

            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy);
                await _blockchainService.AddAppointmentBlockAsync(record, "Vet", "ADD", performedBy);
            }

            return Ok(new { message = "Đặt Vet thành công.", appointment = GetAppointmentBlockchainRecord(appointment, performedBy) });
        }

        [HttpPut("UpdateVet/{id}")]
        public async Task<IActionResult> UpdateVet(int id, [FromBody] VetBookingViewModel model)
        {
            var userId = _userManager.GetUserId(User);
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == id && a.UserId == userId);

            if (appointment == null) return NotFound();

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            var today = TimeZoneInfo.ConvertTimeFromUtc(
                DateTime.UtcNow,
                TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time")
            ).Date;

            if ((appointment.AppointmentDate.Date - today).TotalDays < 1)
                return BadRequest("Vet chỉ được sửa trước 1 ngày.");

            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId.Value && p.UserId == userId);
                if (pet == null) return BadRequest("Thú cưng không hợp lệ.");
            }
            else
            {
                pet = new Pet
                {
                    Name = model.PetName,
                    Type = model.PetType,
                    Breed = model.PetBreed,
                    Age = model.PetAge,
                    Weight = model.PetWeight,
                    UserId = userId
                };
                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();
            }

            appointment.PetId = pet.PetId;
            appointment.ServiceId = model.ServiceId;
            appointment.AppointmentDate = model.AppointmentDate;
            appointment.AppointmentTime = model.AppointmentTime;
            appointment.Note = model.Note;

            await _context.SaveChangesAsync();

            await _context.Entry(appointment).Reference(a => a.Pet).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.Service).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.User).LoadAsync();

            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy);
                await _blockchainService.AddAppointmentBlockAsync(record, "Vet", "UPDATE", performedBy);
            }

            return Ok(new { message = "Cập nhật Vet thành công.", appointment = GetAppointmentBlockchainRecord(appointment, performedBy) });
        }

        // ================= CANCEL =================
        [HttpDelete("Cancel/{id}")]
        public async Task<IActionResult> CancelAppointment(int id)
        {
            var userId = _userManager.GetUserId(User);
            var appointment = await _context.Appointments
                .Include(a => a.Service)
                .Include(a => a.Pet)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == id && a.UserId == userId);

            if (appointment == null) return NotFound();

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            var today = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time")).Date;

            // Kiểm tra điều kiện hủy
            if (appointment.Service?.Category == ServiceCategory.Homestay && (appointment.StartDate.Date - today).TotalDays < 2)
                return BadRequest("Homestay chỉ có thể hủy trước 2 ngày.");
            if ((appointment.Service?.Category == ServiceCategory.Spa || appointment.Service?.Category == ServiceCategory.Vet)
                && (appointment.AppointmentDate.Date - today).TotalDays < 1)
                return BadRequest($"{appointment.Service?.Category} chỉ có thể hủy trước 1 ngày.");

            appointment.Status = AppointmentStatus.Cancelled;
            await _context.SaveChangesAsync();

            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy);
                await _blockchainService.AddAppointmentBlockAsync(record, appointment.Service.Category.ToString(), "CANCEL", performedBy);
            }

            return Ok(new { message = "Lịch hẹn đã được hủy.", appointment = GetAppointmentBlockchainRecord(appointment, performedBy) });
        }

        // ================= DETAILS =================
        [HttpGet("Details/{id}")]
        public async Task<IActionResult> AppointmentDetailsApi(int id)
        {
            var userId = _userManager.GetUserId(User);
            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                    .ThenInclude(p => p.ServiceRecords)
                        .ThenInclude(sr => sr.Service)
                .Include(a => a.DeletedPet)
                .Include(a => a.Service)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == id && a.UserId == userId);

            if (appointment == null) return NotFound();

            return Ok(GetAppointmentBlockchainRecord(appointment, performedBy, isForView: true));
        }
    }
}
