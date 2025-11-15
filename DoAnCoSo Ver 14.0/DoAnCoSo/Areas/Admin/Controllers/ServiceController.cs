using DoAnCoSo.Models;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin")]
    public class ServiceController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly BlockchainService _blockchainService;

        public ServiceController(ApplicationDbContext context, BlockchainService blockchainService, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _blockchainService = blockchainService;
            _userManager = userManager;
        }

        // =================== APPOINTMENT ===================

        public async Task<IActionResult> PendingAppointments()
        {
            var pendingAppointments = await _context.Appointments
                .Include(a => a.User)
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Where(a => a.Status == AppointmentStatus.Pending)
                .OrderBy(a => a.AppointmentId)
                .AsNoTracking()
                .ToListAsync();

            return View(pendingAppointments);
        }

        public async Task<IActionResult> AppointmentHistory()
        {
            var history = await _context.Appointments
                .Include(a => a.User)
                .Include(a => a.Pet)
                .Include(a => a.DeletedPet)
                .Include(a => a.Service)
                .OrderByDescending(a => a.AppointmentId)
                .AsNoTracking()
                .ToListAsync();

            return View(history); // View sẽ nhận List<Appointment>
        }

        public async Task<IActionResult> AppointmentDetails(int id)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.DeletedPet)  // bắt buộc
                .Include(a => a.Service)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == id);

            if (appointment == null)
                return NotFound();

            return View(appointment);
        }

        // =================== ACCEPT / CANCEL ===================
        [HttpPost]
        public async Task<IActionResult> AcceptAppointment(int id)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Service)
                .Include(a => a.Pet)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == id);

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            if (appointment != null)
            {
                appointment.Status = AppointmentStatus.Confirmed;
                await _context.SaveChangesAsync();

                if (_blockchainService != null)
                {
                    string recordType = appointment.Service.Category.ToString(); // Spa / Homestay / Vet

                    string jsonData;

                    if (appointment.Service.Category == ServiceCategory.Spa || appointment.Service.Category == ServiceCategory.Vet)
                    {
                        jsonData = System.Text.Json.JsonSerializer.Serialize(new
                        {
                            appointment.AppointmentId,
                            appointment.Status,
                            AppointmentDate = appointment.AppointmentDate.ToString("dd/MM/yyyy"),
                            AppointmentTime = appointment.AppointmentTime.ToString(@"hh\:mm"),
                            PetName = appointment.Pet.Name,
                            PetType = appointment.Pet.Type,
                            ServiceName = appointment.Service.Name,
                            UserName = appointment.User.FullName
                        });
                    }
                    else
                    {
                        jsonData = System.Text.Json.JsonSerializer.Serialize(new
                        {
                            appointment.AppointmentId,
                            appointment.Status,
                            StartDate = appointment.StartDate.ToString("dd/MM/yyyy"),
                            EndDate = appointment.EndDate.ToString("dd/MM/yyyy"),
                            PetName = appointment.Pet.Name,
                            PetType = appointment.Pet.Type,
                            ServiceName = appointment.Service.Name,
                            UserName = appointment.User.FullName
                        });
                    }

                    await _blockchainService.AddAppointmentBlockAsync(
                        appointment.PetId.GetValueOrDefault(), 
                        appointment.AppointmentId,
                        recordType,
                        "ADMIN_CONFIRM",
                        jsonData,
                        performedBy
                    );
                }
            }

            return RedirectToAction(nameof(PendingAppointments));
        }

        [HttpPost]
        public async Task<IActionResult> CancelAppointment(int id)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Service)
                .Include(a => a.Pet)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == id);

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            if (appointment != null)
            {
                appointment.Status = AppointmentStatus.Cancelled;
                await _context.SaveChangesAsync();

                if (_blockchainService != null)
                {
                    string recordType = appointment.Service.Category.ToString(); // Spa / Homestay / Vet

                    string jsonData;

                    if (appointment.Service.Category == ServiceCategory.Spa || appointment.Service.Category == ServiceCategory.Vet)
                    {
                        jsonData = System.Text.Json.JsonSerializer.Serialize(new
                        {
                            appointment.AppointmentId,
                            appointment.Status,
                            AppointmentDate = appointment.AppointmentDate.ToString("dd/MM/yyyy"),
                            AppointmentTime = appointment.AppointmentTime.ToString(@"hh\:mm"),
                            PetName = appointment.Pet.Name,
                            PetType = appointment.Pet.Type,
                            ServiceName = appointment.Service.Name,
                            UserName = appointment.User.FullName
                        });
                    }
                    else
                    {
                        jsonData = System.Text.Json.JsonSerializer.Serialize(new
                        {
                            appointment.AppointmentId,
                            appointment.Status,
                            StartDate = appointment.StartDate.ToString("dd/MM/yyyy"),
                            EndDate = appointment.EndDate.ToString("dd/MM/yyyy"),
                            PetName = appointment.Pet.Name,
                            PetType = appointment.Pet.Type,
                            ServiceName = appointment.Service.Name,
                            UserName = appointment.User.FullName
                        });
                    }

                    await _blockchainService.AddAppointmentBlockAsync(
                        appointment.PetId.GetValueOrDefault(), 
                        appointment.AppointmentId,
                        recordType,
                        "ADMIN_CANCEL",
                        jsonData,
                        performedBy
                    );
                }
            }

            return RedirectToAction(nameof(PendingAppointments));
        }

        // =================== SPA APPOINTMENT ===================
        [HttpGet]
        public async Task<IActionResult> AppointmentSpa()
        {
            // Lấy user trừ Admin
            var users = await _context.Users.ToListAsync();
            var userList = new List<ApplicationUser>();
            foreach (var u in users)
            {
                if (!await _userManager.IsInRoleAsync(u, "Admin"))
                    userList.Add(u);
            }
            ViewBag.Users = userList;

            // Chọn user đầu tiên làm mặc định
            var selectedUser = userList.FirstOrDefault();
            var userPets = selectedUser != null
                ? await _context.Pets.Where(p => p.UserId == selectedUser.Id).ToListAsync()
                : new List<Pet>();

            ViewBag.Pets = userPets;

            // Dịch vụ Spa
            var spaServices = await _context.Services
                .Where(s => s.Category == ServiceCategory.Spa)
                .ToListAsync();
            ViewBag.SpaServices = spaServices;

            var spaPricings = await _context.SpaPricings.ToListAsync();
            ViewBag.SpaPricings = spaPricings;

            var model = new SpaBookingViewModel
            {
                UserId = selectedUser?.Id,
                OwnerPhoneNumber = selectedUser?.PhoneNumber,
                AppointmentDate = DateTime.Now,
                AppointmentTime = new TimeSpan(9, 0, 0),
                UserPets = userPets
            };

            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> AppointmentSpa(SpaBookingViewModel model)
        {
            if (!ModelState.IsValid)
            {
                ViewBag.Users = await _context.Users
                    .Where(u => !_userManager.IsInRoleAsync(u, "Admin").Result)
                    .ToListAsync();

                ViewBag.Pets = await _context.Pets
                    .Where(p => p.UserId == model.UserId)
                    .ToListAsync();

                ViewBag.SpaServices = await _context.Services
                    .Where(s => s.Category == ServiceCategory.Spa)
                    .ToListAsync();

                ViewBag.SpaPricings = await _context.SpaPricings.ToListAsync();

                return View(model);
            }

            // ✅ Lấy thông tin user khách
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == model.UserId);
            if (user == null) return NotFound();
            model.OwnerPhoneNumber = user.PhoneNumber;

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            // ✅ Lấy dịch vụ
            var selectedService = await _context.Services
                .FirstOrDefaultAsync(s => s.ServiceId == model.ServiceId && s.Category == ServiceCategory.Spa);
            if (selectedService == null) return NotFound();

            // ✅ Xử lý Pet
            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId.Value && p.UserId == user.Id);
                if (pet == null) return NotFound();
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
                    UserId = user.Id
                };
                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();
            }

            // ✅ Tạo lịch
            var appointment = new Appointment
            {
                AppointmentDate = model.AppointmentDate,
                AppointmentTime = model.AppointmentTime,
                Status = AppointmentStatus.Confirmed, // Admin tạo = xác nhận luôn
                ServiceId = model.ServiceId,
                UserId = user.Id,
                CreatedDate = DateTime.UtcNow,
                OwnerPhoneNumber = model.OwnerPhoneNumber,
                PetId = pet.PetId
            };

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            // ✅ Lưu Blockchain
            if (_blockchainService != null)
            {
                var jsonData = System.Text.Json.JsonSerializer.Serialize(new
                {
                    appointment.AppointmentId,
                    appointment.Status,
                    AppointmentDate = appointment.AppointmentDate.ToString("dd/MM/yyyy"),
                    AppointmentTime = appointment.AppointmentTime.ToString(@"hh\:mm"),
                    PetName = appointment.Pet.Name,
                    PetType = appointment.Pet.Type,
                    ServiceName = appointment.Service.Name,
                    UserName = appointment.User.FullName
                });

                await _blockchainService.AddAppointmentBlockAsync(
                    appointment.PetId.GetValueOrDefault(), 
                    appointment.AppointmentId, // ✅ sửa đúng theo Spa/Homestay
                    "Spa",
                    "ADMIN_ADD",
                    jsonData,
                    performedBy
                );
            }

            TempData["SuccessMessage"] = "✅ Admin đặt lịch Spa thành công!";
            return RedirectToAction("AppointmentHistory");
        }

        [HttpGet]
        public async Task<IActionResult> UpdateAppointmentSpa(int id)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.User)
                .Include(a => a.Service)
                .FirstOrDefaultAsync(a => a.AppointmentId == id);

            if (appointment == null) return NotFound();

            // Lấy danh sách user trừ Admin
            var users = await _context.Users.ToListAsync();
            var userList = new List<ApplicationUser>();
            foreach (var u in users)
                if (!await _userManager.IsInRoleAsync(u, "Admin"))
                    userList.Add(u);
            ViewBag.Users = userList;

            // Lấy danh sách pets của user hiện tại
            var userPets = await _context.Pets
                .Where(p => p.UserId == appointment.UserId)
                .ToListAsync();
            ViewBag.Pets = userPets;

            // Dịch vụ Spa & Pricing
            ViewBag.SpaServices = await _context.Services
                .Where(s => s.Category == ServiceCategory.Spa)
                .ToListAsync();
            ViewBag.SpaPricings = await _context.SpaPricings.ToListAsync();

            var model = new SpaBookingViewModel
            {
                AppointmentId = appointment.AppointmentId,
                UserId = appointment.UserId,
                ExistingPetId = appointment.PetId,
                PetName = appointment.Pet?.Name,
                PetType = appointment.Pet?.Type,
                PetBreed = appointment.Pet?.Breed,
                PetAge = appointment.Pet?.Age,
                PetWeight = appointment.Pet?.Weight,
                AppointmentDate = appointment.AppointmentDate,
                AppointmentTime = appointment.AppointmentTime,
                ServiceId = appointment.ServiceId,
                OwnerPhoneNumber = appointment.OwnerPhoneNumber,
                UserPets = userPets,
                IsUpdate = true
            };

            return View("AppointmentSpa", model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateAppointmentSpa(SpaBookingViewModel model)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.User)
                .Include(a => a.Service)
                .FirstOrDefaultAsync(a => a.AppointmentId == model.AppointmentId);

            if (appointment == null) return NotFound();

            if ((appointment.AppointmentDate.Date - DateTime.Today).TotalDays < 1)
            {
                TempData["ErrorMessage"] = "❌ Chỉ được sửa trước 1 ngày.";
                return RedirectToAction("PendingAppointments");
            }

            if (!ModelState.IsValid)
            {
                ViewBag.Users = await _context.Users.Where(u => !_userManager.IsInRoleAsync(u, "Admin").Result).ToListAsync();
                ViewBag.Pets = await _context.Pets.Where(p => p.UserId == model.UserId).ToListAsync();
                ViewBag.SpaServices = await _context.Services.Where(s => s.Category == ServiceCategory.Spa).ToListAsync();
                ViewBag.SpaPricings = await _context.SpaPricings.ToListAsync();
                return View("AppointmentSpa", model);
            }

            var user = await _context.Users.FindAsync(model.UserId);
            if (user == null) return NotFound();

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            // Xử lý pet
            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId.Value && p.UserId == model.UserId);
                if (pet == null) pet = null; // Pet đã xóa
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
                    UserId = model.UserId
                };
                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();
            }

            // Cập nhật thông tin lịch
            appointment.UserId = model.UserId;
            appointment.PetId = pet?.PetId ?? appointment.PetId;
            appointment.ServiceId = model.ServiceId;
            appointment.AppointmentDate = model.AppointmentDate;
            appointment.AppointmentTime = model.AppointmentTime;
            appointment.OwnerPhoneNumber = model.OwnerPhoneNumber;

            await _context.SaveChangesAsync();

            // Blockchain
            if (_blockchainService != null)
            {
                var jsonData = System.Text.Json.JsonSerializer.Serialize(new
                {
                    appointment.AppointmentId,
                    appointment.Status,
                    AppointmentDate = appointment.AppointmentDate.ToString("dd/MM/yyyy"),
                    AppointmentTime = appointment.AppointmentTime.ToString(@"hh\:mm"),
                    PetName = pet?.Name ?? "[Đã xóa]",
                    PetType = pet?.Type ?? "-",
                    ServiceName = appointment.Service?.Name ?? "-",
                    UserName = appointment.User?.FullName ?? "-"
                });

                await _blockchainService.AddAppointmentBlockAsync(
                    appointment.PetId.GetValueOrDefault(), 
                    appointment.AppointmentId,
                    "Spa",
                    "ADMIN_UPDATE",
                    jsonData,
                    performedBy
                );
            }

            TempData["SuccessMessage"] = "✅ Cập nhật lịch Spa thành công!";
            return RedirectToAction("PendingAppointments");
        }

        [HttpGet]
        public async Task<IActionResult> GetUserPetsAndPhone(string userId)
        {
            if (string.IsNullOrEmpty(userId))
                return Json(new { phone = "", pets = new List<object>() });

            var user = await _context.Users.FindAsync(userId);
            var pets = await _context.Pets
                .Where(p => p.UserId == userId)
                .Select(p => new
                {
                    petId = p.PetId,
                    name = p.Name,
                    type = p.Type,
                    breed = p.Breed,
                    age = p.Age,
                    weight = p.Weight.Value.ToString("0.00")
                }).ToListAsync();

            return Json(new { phone = user?.PhoneNumber ?? "", pets });
        }

        // =================== HOMESTAY APPOINTMENT ===================
        [HttpGet]
        public async Task<IActionResult> AppointmentHomestay()
        {
            // Lấy danh sách user trừ Admin
            var users = await _context.Users.ToListAsync();
            var userList = new List<ApplicationUser>();
            foreach (var u in users)
            {
                if (!await _userManager.IsInRoleAsync(u, "Admin"))
                    userList.Add(u);
            }
            ViewBag.Users = userList;

            // Chọn user đầu tiên nếu chưa chọn ai
            var selectedUser = userList.FirstOrDefault();
            var userPets = selectedUser != null
                ? await _context.Pets.Where(p => p.UserId == selectedUser.Id).ToListAsync()
                : new List<Pet>();

            ViewBag.UserPets = userPets;

            // Lấy dịch vụ Homestay
            ViewBag.HomestayServices = await _context.Services
                .Where(s => s.Category == ServiceCategory.Homestay)
                .ToListAsync();

            var model = new HomestayBookingViewModel
            {
                UserId = selectedUser?.Id,
                OwnerPhoneNumber = selectedUser?.PhoneNumber,
                StartDate = DateTime.Now,
                EndDate = DateTime.Now.AddDays(3),
                UserPets = userPets
            };

            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> AppointmentHomestay(HomestayBookingViewModel model)
        {
            if (!ModelState.IsValid)
            {
                ViewBag.Users = await _context.Users
                    .Where(u => !_userManager.IsInRoleAsync(u, "Admin").Result)
                    .ToListAsync();

                ViewBag.Pets = await _context.Pets
                    .Where(p => p.UserId == model.UserId)
                    .ToListAsync();

                ViewBag.HomestayServices = await _context.Services
                    .Where(s => s.Category == ServiceCategory.Homestay)
                    .ToListAsync();

                return View(model);
            }

            // ✅ Lấy thông tin user khách
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == model.UserId);
            if (user == null) return NotFound();
            model.OwnerPhoneNumber = user.PhoneNumber;

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            // ✅ Lấy dịch vụ homestay
            var selectedService = await _context.Services
                .FirstOrDefaultAsync(s => s.ServiceId == model.ServiceId && s.Category == ServiceCategory.Homestay);
            if (selectedService == null) return NotFound();

            // ✅ Xử lý thú cưng (y như Spa)
            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets
                    .FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId.Value && p.UserId == user.Id);
                if (pet == null) return NotFound();
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
                    UserId = user.Id
                };
                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();
            }

            // ✅ Tạo lịch Homestay
            var appointment = new Appointment
            {
                StartDate = model.StartDate,
                EndDate = model.EndDate,
                Status = AppointmentStatus.Confirmed,
                ServiceId = model.ServiceId,
                UserId = user.Id,
                CreatedDate = DateTime.UtcNow,
                OwnerPhoneNumber = model.OwnerPhoneNumber,
                PetId = pet.PetId
            };

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            // ✅ Lưu Blockchain
            if (_blockchainService != null)
            {
                var jsonData = System.Text.Json.JsonSerializer.Serialize(new
                {
                    appointment.AppointmentId,
                    appointment.Status,
                    StartDate = appointment.StartDate.ToString("dd/MM/yyyy"),
                    EndDate = appointment.EndDate.ToString("dd/MM/yyyy"),
                    PetName = appointment.Pet.Name,
                    PetType = appointment.Pet.Type,
                    ServiceName = appointment.Service.Name,
                    UserName = appointment.User.FullName
                });

                await _blockchainService.AddAppointmentBlockAsync(
                    appointment.PetId.GetValueOrDefault(), 
                    appointment.AppointmentId,  // ✅ sửa giống Spa
                    "Homestay",
                    "ADMIN_ADD",
                    jsonData,
                    performedBy
                );
            }

            TempData["SuccessMessage"] = "✅ Admin đặt lịch Homestay thành công!";
            return RedirectToAction("AppointmentHistory");
        }

        [HttpGet]
        public async Task<IActionResult> UpdateAppointmentHomestay(int id)
        {
            // Lấy lịch Homestay cần sửa
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .FirstOrDefaultAsync(a => a.AppointmentId == id);

            if (appointment == null)
                return NotFound();

            // Lấy danh sách user trừ Admin
            var users = await _context.Users.ToListAsync();
            var userList = new List<ApplicationUser>();
            foreach (var u in users)
            {
                if (!await _userManager.IsInRoleAsync(u, "Admin"))
                    userList.Add(u);
            }
            ViewBag.Users = userList;

            // Lấy pets của user hiện tại
            var userPets = await _context.Pets
                .Where(p => p.UserId == appointment.UserId)
                .ToListAsync();
            ViewBag.UserPets = userPets;

            // Lấy dịch vụ Homestay
            ViewBag.HomestayServices = await _context.Services
                .Where(s => s.Category == ServiceCategory.Homestay)
                .ToListAsync();

            // Map dữ liệu ra ViewModel
            var model = new HomestayBookingViewModel
            {
                AppointmentId = appointment.AppointmentId,
                UserId = appointment.UserId,
                OwnerPhoneNumber = appointment.OwnerPhoneNumber,
                ServiceId = appointment.ServiceId,
                ExistingPetId = appointment.PetId,
                PetName = appointment.Pet?.Name,
                PetType = appointment.Pet?.Type,
                PetBreed = appointment.Pet?.Breed,
                PetAge = appointment.Pet?.Age,
                PetWeight = appointment.Pet?.Weight,
                StartDate = appointment.StartDate,
                EndDate = appointment.EndDate,
                UserPets = userPets,
                IsUpdate = true
            };

            return View("AppointmentHomestay", model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateAppointmentHomestay(HomestayBookingViewModel model)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.User)
                .Include(a => a.Service)
                .FirstOrDefaultAsync(a => a.AppointmentId == model.AppointmentId);

            if (appointment == null) return NotFound();

            if ((appointment.StartDate.Date - DateTime.Today).TotalDays < 1)
            {
                TempData["ErrorMessage"] = "❌ Chỉ được sửa trước 1 ngày.";
                return RedirectToAction("PendingAppointments");
            }

            if (!ModelState.IsValid)
            {
                ViewBag.HomestayServices = await _context.Services
                    .Where(s => s.Category == ServiceCategory.Homestay).ToListAsync();
                ViewBag.UserPets = await _context.Pets.Where(p => p.UserId == model.UserId).ToListAsync();
                return View("AppointmentHomestay", model);
            }

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            // Xử lý pet
            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId.Value && p.UserId == model.UserId);
                if (pet == null) pet = null; // pet đã xóa
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
                    UserId = model.UserId
                };
                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();
            }

            // Cập nhật thông tin lịch
            appointment.PetId = pet?.PetId ?? appointment.PetId;
            appointment.ServiceId = model.ServiceId;
            appointment.StartDate = model.StartDate;
            appointment.EndDate = model.EndDate;
            appointment.OwnerPhoneNumber = model.OwnerPhoneNumber;
            appointment.UserId = model.UserId;

            await _context.SaveChangesAsync();

            // Blockchain
            if (_blockchainService != null)
            {
                var jsonData = System.Text.Json.JsonSerializer.Serialize(new
                {
                    appointment.AppointmentId,
                    appointment.Status,
                    StartDate = appointment.StartDate.ToString("dd/MM/yyyy"),
                    EndDate = appointment.EndDate.ToString("dd/MM/yyyy"),
                    PetName = pet?.Name ?? "[Đã xóa]",
                    PetType = pet?.Type ?? "-",
                    ServiceName = appointment.Service?.Name ?? "-",
                    UserName = appointment.User?.FullName ?? "-"
                });

                await _blockchainService.AddAppointmentBlockAsync(
                    appointment.PetId.GetValueOrDefault(), 
                    appointment.AppointmentId,
                    "Homestay",
                    "ADMIN_UPDATE",
                    jsonData,
                    performedBy
                );
            }

            TempData["SuccessMessage"] = "✅ Cập nhật lịch Homestay thành công!";
            return RedirectToAction("PendingAppointments");
        }

        // =================== VET APPOINTMENT ===================
        [HttpGet]
        public async Task<IActionResult> AppointmentVet()
        {
            // Danh sách user (trừ Admin)
            var users = await _context.Users.ToListAsync();
            var userList = new List<ApplicationUser>();
            foreach (var u in users)
                if (!await _userManager.IsInRoleAsync(u, "Admin"))
                    userList.Add(u);

            ViewBag.Users = userList;

            // Chọn user đầu tiên nếu có
            var selectedUser = userList.FirstOrDefault();
            var userPets = selectedUser != null
                ? await _context.Pets.Where(p => p.UserId == selectedUser.Id).ToListAsync()
                : new List<Pet>();
            ViewBag.UserPets = userPets;

            // Dịch vụ Thú y
            ViewBag.VetServices = await _context.Services
                .Where(s => s.Category == ServiceCategory.Vet)
                .ToListAsync();

            var model = new VetBookingViewModel
            {
                UserId = selectedUser?.Id,
                OwnerPhoneNumber = selectedUser?.PhoneNumber,
                AppointmentDate = DateTime.Now,
                AppointmentTime = new TimeSpan(9, 0, 0),
                UserPets = userPets
            };

            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> AppointmentVet(VetBookingViewModel model)
        {
            // Kiểm tra user
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == model.UserId);
            if (user == null)
            {
                ModelState.AddModelError("", "Không tìm thấy người dùng.");
                return View(model);
            }

            model.OwnerPhoneNumber = user.PhoneNumber;

            // Lấy thông tin admin hiện tại (người thao tác)
            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            // Kiểm tra dịch vụ thú y
            var selectedService = await _context.Services
                .FirstOrDefaultAsync(s => s.ServiceId == model.ServiceId && s.Category == ServiceCategory.Vet);

            if (selectedService == null)
            {
                ModelState.AddModelError("", "Chọn dịch vụ khám không hợp lệ.");
                ViewBag.Users = await _context.Users
                    .Where(u => !_userManager.IsInRoleAsync(u, "Admin").Result)
                    .ToListAsync();
                ViewBag.VetServices = await _context.Services
                    .Where(s => s.Category == ServiceCategory.Vet)
                    .ToListAsync();
                ViewBag.UserPets = await _context.Pets.Where(p => p.UserId == model.UserId).ToListAsync();
                return View(model);
            }

            // Xử lý thú cưng
            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId && p.UserId == user.Id);
                if (pet == null)
                {
                    ModelState.AddModelError("", "Chọn thú cưng không hợp lệ.");
                    ViewBag.Users = await _context.Users
                        .Where(u => !_userManager.IsInRoleAsync(u, "Admin").Result)
                        .ToListAsync();
                    ViewBag.VetServices = await _context.Services
                        .Where(s => s.Category == ServiceCategory.Vet)
                        .ToListAsync();
                    ViewBag.UserPets = await _context.Pets.Where(p => p.UserId == model.UserId).ToListAsync();
                    return View(model);
                }

                model.PetName = pet.Name;
                model.PetType = pet.Type;
                model.PetBreed = pet.Breed;
                model.PetAge = pet.Age;
                model.PetWeight = pet.Weight;
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
                    UserId = user.Id
                };
                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();
            }

            // Tạo lịch hẹn
            var appointment = new Appointment
            {
                AppointmentDate = model.AppointmentDate,
                AppointmentTime = model.AppointmentTime,
                Status = AppointmentStatus.Confirmed, // Admin tạo = xác nhận luôn
                ServiceId = selectedService.ServiceId,
                UserId = user.Id,
                CreatedDate = DateTime.UtcNow,
                OwnerPhoneNumber = model.OwnerPhoneNumber,
                PetId = pet.PetId,
                Note = model.Note
            };

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            // Nạp lại các quan hệ (để ghi blockchain)
            await _context.Entry(appointment).Reference(a => a.Pet).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.Service).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.User).LoadAsync();

            // --- Ghi vào Blockchain ---
            if (_blockchainService != null)
            {
                var jsonData = System.Text.Json.JsonSerializer.Serialize(new
                {
                    appointment.AppointmentId,
                    appointment.Status,
                    AppointmentDate = appointment.AppointmentDate.ToString("dd/MM/yyyy"),
                    AppointmentTime = appointment.AppointmentTime.ToString(@"hh\:mm"),
                    PetName = appointment.Pet?.Name,
                    PetType = appointment.Pet?.Type,
                    ServiceName = appointment.Service?.Name,
                    UserName = appointment.User?.FullName ?? performedBy,
                    Note = appointment.Note ?? ""
                });

                await _blockchainService.AddAppointmentBlockAsync(
                    appointment.PetId.GetValueOrDefault(),
                    appointment.AppointmentId,
                    "Vet",
                    "ADMIN_ADD",
                    jsonData,
                    performedBy
                );
            }

            TempData["SuccessMessage"] = "✅ Admin đã đặt lịch Thú y thành công!";
            return RedirectToAction("AppointmentHistory");
        }

        [HttpGet]
        public async Task<IActionResult> UpdateAppointmentVet(int id)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == id);

            if (appointment == null) return NotFound();

            if ((appointment.AppointmentDate - DateTime.Now).TotalDays < 1)
            {
                TempData["ErrorMessage"] = "❌ Chỉ được sửa trước 1 ngày.";
                return RedirectToAction("PendingAppointments");
            }

            // Danh sách user (trừ admin)
            var users = await _context.Users.ToListAsync();
            var userList = new List<ApplicationUser>();
            foreach (var u in users)
                if (!await _userManager.IsInRoleAsync(u, "Admin"))
                    userList.Add(u);

            ViewBag.Users = userList;

            // Pets của user
            var userPets = await _context.Pets
                .Where(p => p.UserId == appointment.UserId)
                .ToListAsync();
            ViewBag.UserPets = userPets;

            // Dịch vụ Vet
            var vetServices = await _context.Services
                .Where(s => s.Category == ServiceCategory.Vet)
                .ToListAsync();
            ViewBag.VetServices = vetServices;

            var model = new VetBookingViewModel
            {
                AppointmentId = appointment.AppointmentId,
                UserId = appointment.UserId,
                ExistingPetId = appointment.PetId,
                PetName = appointment.Pet?.Name,
                PetType = appointment.Pet?.Type,
                PetBreed = appointment.Pet?.Breed,
                PetAge = appointment.Pet?.Age,
                PetWeight = appointment.Pet?.Weight,
                ServiceId = appointment.ServiceId,
                AppointmentDate = appointment.AppointmentDate,
                AppointmentTime = appointment.AppointmentTime,
                Note = appointment.Note,
                OwnerPhoneNumber = appointment.OwnerPhoneNumber,
                UserPets = userPets,
                IsUpdate = true
            };

            return View("AppointmentVet", model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateAppointmentVet(VetBookingViewModel model)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == model.AppointmentId);

            if (appointment == null) return NotFound();

            if ((appointment.AppointmentDate - DateTime.Now).TotalDays < 1)
            {
                TempData["ErrorMessage"] = "❌ Chỉ được sửa trước 1 ngày.";
                return RedirectToAction("PendingAppointments");
            }

            // Xử lý Pet
            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets
                    .FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId.Value && p.UserId == model.UserId);

                if (pet == null)
                {
                    ModelState.AddModelError("", "Chọn thú cưng không hợp lệ.");
                    ViewBag.Users = await _context.Users
                        .Where(u => !_userManager.IsInRoleAsync(u, "Admin").Result)
                        .ToListAsync();
                    ViewBag.UserPets = await _context.Pets.Where(p => p.UserId == model.UserId).ToListAsync();
                    ViewBag.VetServices = await _context.Services
                        .Where(s => s.Category == ServiceCategory.Vet)
                        .ToListAsync();
                    return View("AppointmentVet", model);
                }
            }
            else
            {
                // Tạo Pet mới
                pet = new Pet
                {
                    Name = model.PetName,
                    Type = model.PetType,
                    Breed = model.PetBreed,
                    Age = model.PetAge,
                    Weight = model.PetWeight,
                    UserId = model.UserId
                };
                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();
            }

            // Cập nhật appointment
            appointment.PetId = pet.PetId;
            appointment.ServiceId = model.ServiceId;
            appointment.UserId = model.UserId;
            appointment.AppointmentDate = model.AppointmentDate;
            appointment.AppointmentTime = model.AppointmentTime;
            appointment.OwnerPhoneNumber = model.OwnerPhoneNumber;
            appointment.Note = model.Note;

            await _context.SaveChangesAsync();

            // Reload navigation
            await _context.Entry(appointment).Reference(a => a.Pet).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.Service).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.User).LoadAsync();

            // Blockchain
            if (_blockchainService != null)
            {
                var currentUser = await _userManager.GetUserAsync(User);
                var performedBy = currentUser?.FullName ?? "Hệ thống";

                var jsonData = System.Text.Json.JsonSerializer.Serialize(new
                {
                    appointment.AppointmentId,
                    appointment.Status,
                    AppointmentDate = appointment.AppointmentDate.ToString("dd/MM/yyyy"),
                    AppointmentTime = appointment.AppointmentTime.ToString(@"hh\:mm"),
                    PetName = appointment.Pet?.Name ?? model.PetName,
                    PetType = appointment.Pet?.Type ?? model.PetType,
                    ServiceName = appointment.Service?.Name ?? "",
                    UserName = appointment.User?.FullName ?? performedBy,
                    Note = appointment.Note ?? ""
                });

                await _blockchainService.AddAppointmentBlockAsync(
                    appointment.PetId.GetValueOrDefault(),
                    appointment.AppointmentId,
                    "Vet",
                    "ADMIN_UPDATE",
                    jsonData,
                    performedBy
                );
            }

            TempData["SuccessMessage"] = "✅ Cập nhật lịch Thú y thành công!";
            return RedirectToAction("PendingAppointments");
        }
    }
}
