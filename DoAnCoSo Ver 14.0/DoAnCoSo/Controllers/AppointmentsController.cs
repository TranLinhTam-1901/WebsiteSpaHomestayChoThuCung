using DoAnCoSo.Models;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Controllers
{
    [Authorize]
    public class AppointmentsController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly BlockchainService _blockchainService;

        public AppointmentsController(ApplicationDbContext context, UserManager<ApplicationUser> userManager, BlockchainService blockchainService)
        {
            _context = context;
            _userManager = userManager;
            _blockchainService = blockchainService;
        }

        private object GetAppointmentBlockchainRecord(Appointment appointment, string performedBy)
        {
            if (appointment.Service?.Category == ServiceCategory.Homestay)
            {
                return new
                {
                    appointment.AppointmentId,
                    appointment.Status,
                    StartDate = appointment.StartDate.ToString("dd/MM/yyyy"),
                    EndDate = appointment.EndDate.ToString("dd/MM/yyyy"),
                    PetId = appointment.PetId,
                    PetName = appointment.Pet?.Name,
                    PetType = appointment.Pet?.Type,
                    PetBreed = appointment.Pet?.Breed,
                    ServiceId = appointment.ServiceId,
                    ServiceName = appointment.Service?.Name,
                    UserId = appointment.UserId,
                    UserName = appointment.User?.FullName ?? performedBy
                };
            }
            else // Spa hoặc Vet
            {
                return new
                {
                    appointment.AppointmentId,
                    appointment.Status,
                    AppointmentDate = appointment.AppointmentDate.ToString("dd/MM/yyyy"),
                    AppointmentTime = appointment.AppointmentTime.ToString(@"hh\:mm"),
                    PetId = appointment.PetId,
                    PetName = appointment.Pet?.Name,
                    PetType = appointment.Pet?.Type,
                    PetBreed = appointment.Pet?.Breed,
                    ServiceId = appointment.ServiceId,
                    ServiceName = appointment.Service?.Name,
                    UserId = appointment.UserId,
                    UserName = appointment.User?.FullName ?? performedBy
                };
            }
        }

        // --- SPA ---
        [HttpGet]
        public async Task <IActionResult> BookAppointmentSpa()
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            var userId = _userManager.GetUserId(User);
            var user = await _userManager.FindByIdAsync(userId);

            var spaServices = await _context.Services.Where(s => s.Category == ServiceCategory.Spa).ToListAsync();
            var spaPricings = await _context.SpaPricings.ToListAsync(); // phải tồn tại DbSet<SpaPricing> SpaPricings trong ApplicationDbContext
            var userPets = _context.Pets.Where(p => p.UserId == userId).ToList();

            var vm = new SpaBookingViewModel
            {
                OwnerPhoneNumber = user?.PhoneNumber,
                AppointmentDate = DateTime.Now,
                AppointmentTime = new TimeSpan(9, 0, 0),
                UserPets = userPets
            };

            ViewBag.SpaServices = spaServices;
            ViewBag.SpaPricings = spaPricings;

            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> BookAppointmentSpa(SpaBookingViewModel model)
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            var userId = _userManager.GetUserId(User);
            var user = await _userManager.FindByIdAsync(userId);
            model.OwnerPhoneNumber = user?.PhoneNumber;

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            var selectedService = await _context.Services
                .FirstOrDefaultAsync(s => s.ServiceId == model.ServiceId && s.Category == ServiceCategory.Spa);

            if (selectedService == null)
            {
                ModelState.AddModelError("", "Dịch vụ không hợp lệ.");
                ViewBag.SpaServices = _context.Services.Where(s => s.Category == ServiceCategory.Spa).ToList();
                model.UserPets = _context.Pets.Where(p => p.UserId == userId).ToList();
                return View(model);
            }

            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets
                    .FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId && p.UserId == userId);

                if (pet == null)
                {
                    ModelState.AddModelError("", "Chọn thú cưng không hợp lệ.");
                    ViewBag.SpaServices = _context.Services.Where(s => s.Category == ServiceCategory.Spa).ToList();
                    model.UserPets = _context.Pets.Where(p => p.UserId == userId).ToList();
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
                    Weight = model.PetWeight, // ✅ decimal? mapping thẳng
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
                ServiceId = model.ServiceId,
                UserId = userId,
                CreatedDate = DateTime.UtcNow,
                OwnerPhoneNumber = model.OwnerPhoneNumber,
                PetId = pet.PetId
            };

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            await _context.Entry(appointment).Reference(a => a.Pet).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.Service).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.User).LoadAsync();

            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy);
                await _blockchainService.AddAppointmentBlockAsync(
                    record,
                    appointment.Service.Category.ToString(),
                    "ADD",
                    performedBy
                );
            }

            TempData["ServiceName"] = "Spa";
            return RedirectToAction("AppointmentSuccess");
        }

        [HttpGet]
        public async Task<IActionResult> UpdateAppointmentSpa(int id)
        {
            var userId = _userManager.GetUserId(User);

            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .FirstOrDefaultAsync(a => a.AppointmentId == id && a.UserId == userId);

            if (appointment == null) return NotFound();

            var userPets = await _context.Pets.Where(p => p.UserId == userId).ToListAsync();
            var spaServices = await _context.Services.Where(s => s.Category == ServiceCategory.Spa).ToListAsync();
            var spaPricings = await _context.SpaPricings.ToListAsync();

            var model = new SpaBookingViewModel
            {
                AppointmentId = appointment.AppointmentId,
                ExistingPetId = appointment.PetId,
                AppointmentDate = appointment.AppointmentDate,
                AppointmentTime = appointment.AppointmentTime,
                ServiceId = appointment.ServiceId,
                PetName = appointment.Pet?.Name,
                PetType = appointment.Pet?.Type,
                PetBreed = appointment.Pet?.Breed,
                PetAge = appointment.Pet?.Age,
                PetWeight = appointment.Pet?.Weight,
                OwnerPhoneNumber = appointment.OwnerPhoneNumber,
                UserPets = userPets,
                IsUpdate = true
            };

            ViewBag.SpaServices = spaServices;
            ViewBag.SpaPricings = spaPricings; // ✅ Đây là dòng quan trọng

            return View("BookAppointmentSpa", model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateAppointmentSpa(SpaBookingViewModel model)
        {
            var userId = _userManager.GetUserId(User);
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == model.AppointmentId && a.UserId == userId);

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            if (appointment == null) return NotFound();

            var today = TimeZoneInfo.ConvertTimeFromUtc(
                DateTime.UtcNow,
                TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time")
            ).Date;

            if ((appointment.AppointmentDate.Date - today).TotalDays < 1)
            {
                TempData["ErrorMessage"] = "❌ Chỉ được sửa trước 1 ngày.";
                return RedirectToAction("CustomerAppointmentHistory");
            }

            // Xử lý pet
            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId.Value && p.UserId == userId);
                if (pet == null)
                {
                    ModelState.AddModelError("", "Chọn thú cưng không hợp lệ.");
                    ViewBag.SpaServices = _context.Services.Where(s => s.Category == ServiceCategory.Spa).ToList();
                    model.UserPets = await _context.Pets.Where(p => p.UserId == userId).ToListAsync();
                    return View("BookAppointmentSpa", model);
                }
            }
            else
            {
                // Tạo pet mới
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

            // Cập nhật appointment
            appointment.AppointmentDate = model.AppointmentDate;
            appointment.AppointmentTime = model.AppointmentTime;
            appointment.ServiceId = model.ServiceId;
            appointment.PetId = pet.PetId;

            await _context.SaveChangesAsync();

            // Reload navigation properties trước khi ghi blockchain
            await _context.Entry(appointment).Reference(a => a.Pet).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.Service).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.User).LoadAsync();

            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy);
                await _blockchainService.AddAppointmentBlockAsync(
                    record,
                    appointment.Service.Category.ToString(),
                    "UPDATE", // "ADD", "UPDATE", "CANCEL"
                    performedBy
                );
            }

            TempData["SuccessMessage"] = "✅ Cập nhật lịch Spa thành công!";
            return RedirectToAction("CustomerAppointmentHistory");
        }

        // --- HOMESTAY ---
        [HttpGet]
        public async Task<IActionResult> BookAppointmentHomestay()
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            var userId = _userManager.GetUserId(User);
            var user = await _userManager.FindByIdAsync(userId);

            var userPets = _context.Pets.Where(p => p.UserId == userId).ToList();
            var homestayServices = _context.Services.Where(s => s.Category == ServiceCategory.Homestay).ToList();

            var model = new HomestayBookingViewModel
            {
                StartDate = DateTime.Now,
                EndDate = DateTime.Now.AddDays(3),
                OwnerPhoneNumber = user?.PhoneNumber,
                UserPets = userPets
            };

            ViewBag.UserPets = userPets;
            ViewBag.HomestayServices = homestayServices;

            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> BookAppointmentHomestay(HomestayBookingViewModel model)
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            var userId = _userManager.GetUserId(User);
            var user = await _userManager.FindByIdAsync(userId);
            model.OwnerPhoneNumber = user?.PhoneNumber;

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            var selectedService = await _context.Services
                .FirstOrDefaultAsync(s => s.ServiceId == model.ServiceId && s.Category == ServiceCategory.Homestay);

            if (selectedService == null)
            {
                ModelState.AddModelError("", "Chọn loại phòng không hợp lệ.");
                ViewBag.HomestayServices = _context.Services.Where(s => s.Category == ServiceCategory.Homestay).ToList();
                model.UserPets = _context.Pets.Where(p => p.UserId == userId).ToList();
                return View(model);
            }

            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId && p.UserId == userId);
                if (pet == null)
                {
                    ModelState.AddModelError("", "Chọn thú cưng không hợp lệ.");
                    ViewBag.HomestayServices = _context.Services.Where(s => s.Category == ServiceCategory.Homestay).ToList();
                    model.UserPets = _context.Pets.Where(p => p.UserId == userId).ToList();
                    return View(model);
                }

                // Map thông tin pet về model
                model.PetName = pet.Name;
                model.PetType = pet.Type;
                model.PetBreed = pet.Breed;
                model.PetAge = pet.Age;
                model.PetWeight = pet.Weight;
            }
            else
            {
                // Tạo pet mới
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
                OwnerPhoneNumber = model.OwnerPhoneNumber,
                PetId = pet.PetId
            };

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            await _context.Entry(appointment).Reference(a => a.Pet).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.Service).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.User).LoadAsync();

            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy);
                await _blockchainService.AddAppointmentBlockAsync(
                    record,
                    appointment.Service.Category.ToString(),
                    "ADD", // "ADD", "UPDATE", "CANCEL"
                    performedBy
                );
            }

            TempData["ServiceName"] = "Homestay";
            return RedirectToAction("AppointmentSuccess");
        }

        [HttpGet]
        public async Task<IActionResult> UpdateAppointmentHomestay(int id)
        {
            var userId = _userManager.GetUserId(User);
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .FirstOrDefaultAsync(a => a.AppointmentId == id && a.UserId == userId);

            if (appointment == null)
                return NotFound();

            if ((appointment.StartDate - DateTime.Now).TotalDays < 1)
            {
                TempData["ErrorMessage"] = "❌ Chỉ được sửa trước 1 ngày.";
                return RedirectToAction("CustomerAppointmentHistory");
            }

            // Lấy danh sách pet của user để select
            var userPets = await _context.Pets
                .Where(p => p.UserId == userId)
                .ToListAsync();

            var homestayServices = await _context.Services
                .Where(s => s.Category == ServiceCategory.Homestay)
                .ToListAsync();

            // Build ViewModel
            var model = new HomestayBookingViewModel
            {
                AppointmentId = appointment.AppointmentId,
                ExistingPetId = appointment.PetId,
                StartDate = appointment.StartDate,
                EndDate = appointment.EndDate,
                ServiceId = appointment.ServiceId,
                PetName = appointment.Pet?.Name,
                PetType = appointment.Pet?.Type,
                PetBreed = appointment.Pet?.Breed,
                PetAge = appointment.Pet?.Age,
                PetWeight = appointment.Pet?.Weight,
                OwnerPhoneNumber = appointment.OwnerPhoneNumber,
                UserPets = userPets,
                IsUpdate = true // Có thể dùng flag nếu cần hiển thị nút "Cập nhật"
            };

            ViewBag.UserPets = userPets;
            ViewBag.HomestayServices = homestayServices;

            // Dùng lại view BookAppointmentHomestay
            return View("BookAppointmentHomestay", model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateAppointmentHomestay(HomestayBookingViewModel model)
        {
            var userId = _userManager.GetUserId(User);
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == model.AppointmentId && a.UserId == userId);

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            if (appointment == null) return NotFound();

            var today = TimeZoneInfo.ConvertTimeFromUtc(
                DateTime.UtcNow,
                TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time")
            ).Date;

            if ((appointment.StartDate.Date - today).TotalDays < 2)

            {
                TempData["ErrorMessage"] = "❌ Chỉ được sửa trước 2 ngày.";
                return RedirectToAction("CustomerAppointmentHistory");
            }

            // Xử lý pet
            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId.Value && p.UserId == userId);
                if (pet == null)
                {
                    ModelState.AddModelError("", "Chọn thú cưng không hợp lệ.");
                    ViewBag.HomestayServices = _context.Services.Where(s => s.Category == ServiceCategory.Homestay).ToList();
                    model.UserPets = await _context.Pets.Where(p => p.UserId == userId).ToListAsync();
                    return View("BookAppointmentHomestay", model);
                }
            }
            else
            {
                // Tạo pet mới
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

            // Cập nhật appointment
            appointment.PetId = pet.PetId;
            appointment.ServiceId = model.ServiceId;
            appointment.StartDate = model.StartDate;
            appointment.EndDate = model.EndDate;
            appointment.OwnerPhoneNumber = model.OwnerPhoneNumber;

            await _context.SaveChangesAsync();

            // Reload navigation properties
            await _context.Entry(appointment).Reference(a => a.Pet).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.Service).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.User).LoadAsync();

            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy);
                await _blockchainService.AddAppointmentBlockAsync(
                    record,
                    appointment.Service.Category.ToString(),
                    "UPDATE", // "ADD", "UPDATE", "CANCEL"
                    performedBy
                );
            }

            TempData["SuccessMessage"] = "✅ Cập nhật lịch Homestay thành công!";
            return RedirectToAction("CustomerAppointmentHistory");
        }

        // --- VET ---
        [HttpGet]
        public async Task<IActionResult> BookAppointmentVet()
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            var userId = _userManager.GetUserId(User);
            var user = await _userManager.FindByIdAsync(userId);

            var userPets = await _context.Pets.Where(p => p.UserId == userId).ToListAsync();
            var vetServices = await _context.Services
                .Where(s => s.Category == ServiceCategory.Vet)
                .ToListAsync();

            var model = new VetBookingViewModel
            {
                AppointmentDate = DateTime.Now,
                AppointmentTime = new TimeSpan(9, 0, 0),
                OwnerPhoneNumber = user?.PhoneNumber,
                UserPets = userPets
            };

            ViewBag.VetServices = vetServices;
            ViewBag.UserPets = userPets;

            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> BookAppointmentVet(VetBookingViewModel model)
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            var userId = _userManager.GetUserId(User);
            var user = await _userManager.FindByIdAsync(userId);
            model.OwnerPhoneNumber = user?.PhoneNumber;

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            var selectedService = await _context.Services
                .FirstOrDefaultAsync(s => s.ServiceId == model.ServiceId && s.Category == ServiceCategory.Vet);

            if (selectedService == null)
            {
                ModelState.AddModelError("", "Chọn dịch vụ khám không hợp lệ.");
                ViewBag.VetServices = _context.Services.Where(s => s.Category == ServiceCategory.Vet).ToList();
                model.UserPets = _context.Pets.Where(p => p.UserId == userId).ToList();
                return View(model);
            }

            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId && p.UserId == userId);
                if (pet == null)
                {
                    ModelState.AddModelError("", "Chọn thú cưng không hợp lệ.");
                    ViewBag.VetServices = _context.Services.Where(s => s.Category == ServiceCategory.Vet).ToList();
                    model.UserPets = _context.Pets.Where(p => p.UserId == userId).ToList();
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
                OwnerPhoneNumber = model.OwnerPhoneNumber,
                PetId = pet.PetId,
                Note = model.Note
            };

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            // Nạp lại quan hệ để ghi blockchain
            await _context.Entry(appointment).Reference(a => a.Pet).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.Service).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.User).LoadAsync();

            // --- Blockchain ---
            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy);
                await _blockchainService.AddAppointmentBlockAsync(
                    record,
                    appointment.Service.Category.ToString(),
                    "ADD", // "ADD", "UPDATE", "CANCEL"
                    performedBy
                );
            }

            TempData["ServiceName"] = "Thú y";
            return RedirectToAction("AppointmentSuccess");
        }

        [HttpGet]
        public async Task<IActionResult> UpdateAppointmentVet(int id)
        {
            var userId = _userManager.GetUserId(User);

            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .FirstOrDefaultAsync(a => a.AppointmentId == id && a.UserId == userId);

            if (appointment == null)
                return NotFound();

            if ((appointment.AppointmentDate - DateTime.Now).TotalDays < 1)
            {
                TempData["ErrorMessage"] = "❌ Chỉ được sửa trước 1 ngày.";
                return RedirectToAction("CustomerAppointmentHistory");
            }

            var userPets = await _context.Pets
                .Where(p => p.UserId == userId)
                .ToListAsync();

            var vetServices = await _context.Services
                .Where(s => s.Category == ServiceCategory.Vet)
                .ToListAsync();

            var model = new VetBookingViewModel
            {
                AppointmentId = appointment.AppointmentId,
                OwnerPhoneNumber = appointment.OwnerPhoneNumber,
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
                UserPets = userPets,
                IsUpdate = true
            };

            ViewBag.VetServices = vetServices;
            ViewBag.UserPets = userPets;

            return View("BookAppointmentVet", model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateAppointmentVet(VetBookingViewModel model)
        {
            var userId = _userManager.GetUserId(User);
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == model.AppointmentId && a.UserId == userId);

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            if (appointment == null)
                return NotFound();

            // Chỉ được sửa trước 1 ngày
            var today = TimeZoneInfo.ConvertTimeFromUtc(
                DateTime.UtcNow,
                TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time")
            ).Date;

            if ((appointment.AppointmentDate.Date - today).TotalDays < 1)
            {
                TempData["ErrorMessage"] = "❌ Chỉ được sửa trước 1 ngày.";
                return RedirectToAction("CustomerAppointmentHistory");
            }

            // Xử lý Pet (chọn từ list hoặc tạo mới)
            Pet pet;
            if (model.ExistingPetId.HasValue)
            {
                pet = await _context.Pets
                    .FirstOrDefaultAsync(p => p.PetId == model.ExistingPetId.Value && p.UserId == userId);

                if (pet == null)
                {
                    ModelState.AddModelError("", "Chọn thú cưng không hợp lệ.");
                    ViewBag.VetServices = _context.Services.Where(s => s.Category == ServiceCategory.Vet).ToList();
                    model.UserPets = await _context.Pets.Where(p => p.UserId == userId).ToListAsync();
                    return View("BookAppointmentVet", model);
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
                    UserId = userId
                };
                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();
            }

            // Cập nhật Appointment
            appointment.PetId = pet.PetId;
            appointment.ServiceId = model.ServiceId;
            appointment.AppointmentDate = model.AppointmentDate;
            appointment.AppointmentTime = model.AppointmentTime;
            appointment.Note = model.Note;

            await _context.SaveChangesAsync();

            // Reload navigation
            await _context.Entry(appointment).Reference(a => a.Pet).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.Service).LoadAsync();
            await _context.Entry(appointment).Reference(a => a.User).LoadAsync();

            // Ghi Blockchain
            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy);
                await _blockchainService.AddAppointmentBlockAsync(
                    record,
                    appointment.Service.Category.ToString(),
                    "UPDATE", // "ADD", "UPDATE", "CANCEL"
                    performedBy
                );
            }

            TempData["SuccessMessage"] = "✅ Cập nhật lịch Thú y thành công!";
            return RedirectToAction("CustomerAppointmentHistory");
        }

        // --- VIEW ---
        public IActionResult AppointmentSuccess()
        {
            ViewBag.ServiceName = TempData["ServiceName"] ?? "dịch vụ";
            return View();
        }

        public async Task<IActionResult> CustomerAppointmentHistory()
        {
            var userId = _userManager.GetUserId(User);

            // Lấy danh sách appointment của user, bao gồm Pet và Service
            var appointments = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .Where(a => a.UserId == userId)
                .OrderByDescending(a => a.CreatedDate)
                .ToListAsync();

            // Lấy danh sách DeletedPets của user
            var deletedPets = await _context.DeletedPets
                .Where(dp => dp.UserId == userId)
                .ToListAsync();

            // Gán DeletedPet cho các appointment bị null Pet
            foreach (var appointment in appointments)
            {
                if (appointment.Pet == null && appointment.DeletedPetId.HasValue)
                {
                    var deletedPet = deletedPets.FirstOrDefault(dp => dp.Id == appointment.DeletedPetId.Value);
                    if (deletedPet != null)
                    {
                        appointment.DeletedPet = deletedPet;
                    }
                }
            }

            return View(appointments);
        }

        public async Task<IActionResult> AppointmentDetails(int id)
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            var userId = _userManager.GetUserId(User);

            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                    .ThenInclude(p => p.ServiceRecords)
                        .ThenInclude(sr => sr.Service)
                .Include(a => a.DeletedPet) // include pet đã bị xóa
                .Include(a => a.Service)
                .Include(a => a.User) // để hiển thị tên khách
                .FirstOrDefaultAsync(a => a.AppointmentId == id && a.UserId == userId);

            if (appointment == null)
                return NotFound();

            return View(appointment);
        }

        // --- CANCEL ---
        [HttpGet]
        public async Task<IActionResult> AppointmentCancel(int id)
        {
            var userId = _userManager.GetUserId(User);

            var appointment = await _context.Appointments
                .Include(a => a.Service)
                .Include(a => a.Pet)
                .FirstOrDefaultAsync(a => a.AppointmentId == id && a.UserId == userId);

            if (appointment == null)
                return NotFound();

            return View(appointment); // View: AppointmentCancel.cshtml
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ConfirmCancelAppointment(int id)
        {
            var userId = _userManager.GetUserId(User);

            var appointment = await _context.Appointments
                .Include(a => a.Service)
                .Include(a => a.Pet)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.AppointmentId == id && a.UserId == userId);

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            if (appointment == null)
                return NotFound();

            var today = TimeZoneInfo.ConvertTimeFromUtc(
                DateTime.UtcNow,
                TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time")
            ).Date;

            // Kiểm tra điều kiện hủy
            if (appointment.Service?.Category == ServiceCategory.Homestay)
            {
                if ((appointment.StartDate.Date - today).TotalDays < 2)
                {
                    TempData["ErrorMessage"] = "❌ Homestay chỉ có thể hủy trước 2 ngày.";
                    return RedirectToAction("CustomerAppointmentHistory");
                }
            }
            else if (appointment.Service?.Category == ServiceCategory.Spa)
            {
                if ((appointment.AppointmentDate.Date - today).TotalDays < 1)
                {
                    TempData["ErrorMessage"] = "❌ Spa chỉ có thể hủy lịch trước 1 ngày.";
                    return RedirectToAction("CustomerAppointmentHistory");
                }
            }
            else if (appointment.Service?.Category == ServiceCategory.Vet)
            {
                if ((appointment.AppointmentDate.Date - today).TotalDays < 1)
                {
                    TempData["ErrorMessage"] = "❌ Thú y chỉ có thể hủy lịch trước 1 ngày.";
                    return RedirectToAction("CustomerAppointmentHistory");
                }
            }

            appointment.Status = AppointmentStatus.Cancelled;
            await _context.SaveChangesAsync();

            // Ghi blockchain
            if (_blockchainService != null)
            {
                var record = GetAppointmentBlockchainRecord(appointment, performedBy);
                await _blockchainService.AddAppointmentBlockAsync(
                    record,
                    appointment.Service.Category.ToString(),
                    "CANCEL", // "ADD", "UPDATE", "CANCEL"
                    performedBy
                );
            }

            TempData["SuccessMessage"] = "🗑️ Lịch hẹn đã được hủy.";
            return RedirectToAction("CustomerAppointmentHistory");
        }
    }
}
