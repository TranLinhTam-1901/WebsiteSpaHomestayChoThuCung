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

        // --- SPA ---
        public IActionResult BookAppointmentSpa()
        {
            var userId = _userManager.GetUserId(User);
            var user = _userManager.FindByIdAsync(userId).Result;

            var spaServices = _context.Services.Where(s => s.Category == ServiceCategory.Spa).ToList();
            var spaPricings = _context.SpaPricings.ToList(); // phải tồn tại DbSet<SpaPricing> SpaPricings trong ApplicationDbContext
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
        public async Task<IActionResult> BookAppointmentSpa(SpaBookingViewModel model)
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            var userId = _userManager.GetUserId(User);
            var user = await _userManager.FindByIdAsync(userId);
            model.OwnerPhoneNumber = user?.PhoneNumber;

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
                model.PetWeight = pet.Weight; // ✅ vì giờ là decimal?, ko cần parse chuỗi nữa
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

            return RedirectToAction("AppointmentConfirmation");
        }

        // --- HOMESTAY ---
        public async Task<IActionResult> BookAppointmentHomestay()
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            var userId = _userManager.GetUserId(User);
            var user = await _userManager.FindByIdAsync(userId);

            var model = new HomestayBookingViewModel
            {
                StartDate = DateTime.Now,
                EndDate = DateTime.Now,
                OwnerPhoneNumber = user?.PhoneNumber
            };

            ViewBag.HomestayServices = _context.Services
                .Where(s => s.Category == ServiceCategory.Homestay)
                .ToList();

            ViewBag.UserPets = _context.Pets
                .Where(p => p.UserId == userId)
                .ToList();

            return View(model);
        }

        [HttpPost]
        public async Task<IActionResult> BookAppointmentHomestay(HomestayBookingViewModel model, int? existingPetId)
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            if (ModelState.IsValid)
            {
                var userId = _userManager.GetUserId(User);
                var user = await _userManager.FindByIdAsync(userId);

                // <-- Thêm dòng này
                model.OwnerPhoneNumber = user?.PhoneNumber;

                var selectedService = await _context.Services
                    .FirstOrDefaultAsync(s => s.ServiceId == model.ServiceId && s.Category == ServiceCategory.Homestay);

                if (selectedService == null)
                {
                    ViewBag.HomestayServices = _context.Services.Where(s => s.Category == ServiceCategory.Homestay).ToList();
                    return View(model);
                }

                Pet pet;

                if (existingPetId.HasValue)
                {
                    pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == existingPetId.Value && p.UserId == userId);
                    if (pet == null)
                    {
                        ModelState.AddModelError("", "Chọn thú cưng không hợp lệ.");
                        ViewBag.HomestayServices = _context.Services.Where(s => s.Category == ServiceCategory.Homestay).ToList();
                        return View(model);
                    }
                }
                else
                {
                    pet = new Pet
                    {
                        Name = model.PetName,
                        Type = model.PetType,
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
                    ServiceId = model.ServiceId,
                    UserId = userId,
                    CreatedDate = DateTime.UtcNow,
                    OwnerPhoneNumber = model.OwnerPhoneNumber,
                    PetId = pet.PetId
                };

                _context.Appointments.Add(appointment);
                await _context.SaveChangesAsync();

                return RedirectToAction("AppointmentConfirmation");
            }

            ViewBag.HomestayServices = _context.Services.Where(s => s.Category == ServiceCategory.Homestay).ToList();
            return View(model);
        }

        // --- VET (Thú y) ---
        public async Task<IActionResult> BookAppointmentVet()
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            var userId = _userManager.GetUserId(User);
            var user = await _userManager.FindByIdAsync(userId);

            var model = new VetBookingViewModel
            {
                AppointmentDate = DateTime.Now,
                OwnerPhoneNumber = user?.PhoneNumber
            };

            ViewBag.VetServices = _context.Services
                .Where(s => s.Category == ServiceCategory.Vet)
                .ToList();

            model.UserPets = _context.Pets
                .Where(p => p.UserId == userId)
                .ToList();

            return View(model);
        }

        [HttpPost]
        public async Task<IActionResult> BookAppointmentVet(VetBookingViewModel model)
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            var userId = _userManager.GetUserId(User);
            var user = await _userManager.FindByIdAsync(userId);
            model.OwnerPhoneNumber = user?.PhoneNumber;

            var selectedService = await _context.Services
                .FirstOrDefaultAsync(s => s.ServiceId == model.ServiceId && s.Category == ServiceCategory.Vet);

            if (selectedService == null)
            {
                ModelState.AddModelError("", "Dịch vụ không hợp lệ.");
                ViewBag.VetServices = _context.Services.Where(s => s.Category == ServiceCategory.Vet).ToList();
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
                    ViewBag.VetServices = _context.Services.Where(s => s.Category == ServiceCategory.Vet).ToList();
                    model.UserPets = _context.Pets.Where(p => p.UserId == userId).ToList();
                    return View(model);
                }

                model.PetName = pet.Name;
                model.PetType = pet.Type;
                model.PetBreed = pet.Breed;
                model.PetAge = pet.Age;
            }
            else
            {
                pet = new Pet
                {
                    Name = model.PetName,
                    Type = model.PetType,
                    Breed = model.PetBreed,
                    Age = model.PetAge,
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
                PetId = pet.PetId,
                CreatedDate = DateTime.UtcNow,
                OwnerPhoneNumber = model.OwnerPhoneNumber
            };

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            return RedirectToAction("AppointmentConfirmation");
        }


        public IActionResult AppointmentConfirmation() => View();

        public IActionResult AppointmentSuccess() => View();

        public IActionResult CustomerAppointmentHistory()
        {
            var userId = _userManager.GetUserId(User);

            var customerHistory = _context.Appointments
                .Include(a => a.Pet)
                    .ThenInclude(p => p.ServiceRecords)
                        .ThenInclude(sr => sr.Service)
                .Include(a => a.Service)
                .Where(a => a.UserId == userId)
                .ToList();

            return View(customerHistory);
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
                .Include(a => a.Service)
                .FirstOrDefaultAsync(a => a.AppointmentId == id && a.UserId == userId);

            if (appointment == null)
                return NotFound();

            return View(appointment);
        }
    }
}
