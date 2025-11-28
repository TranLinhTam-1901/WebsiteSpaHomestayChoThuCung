using DoAnCoSo.Models;
using DoAnCoSo.Models.Blockchain;
using DoAnCoSo.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin")]
    public class PetController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly BlockchainService _blockchainService;

        public PetController(ApplicationDbContext context, UserManager<ApplicationUser> userManager, BlockchainService blockchainService)
        {
            _context = context;
            _userManager = userManager;
            _blockchainService = blockchainService;
        }

        // 📋 Danh sách tất cả thú cưng
        public async Task<IActionResult> Index()
        {
            var pets = await _context.Pets
                .Include(p => p.User)
                .OrderByDescending(p => p.PetId)
                .ToListAsync();

            return View(pets);
        }

        // 📋 Chi tiết thú cưng (Admin xem được tất cả)
        public async Task<IActionResult> Details(int id)
        {
            var pet = await _context.Pets
                .Include(p => p.User) // lấy thông tin chủ sở hữu
                .FirstOrDefaultAsync(p => p.PetId == id);

            if (pet == null)
            {
                TempData["ErrorMessage"] = "❌ Không tìm thấy hồ sơ thú cưng.";
                return RedirectToAction(nameof(Index));
            }

            return View(pet);
        }

        // ➕ Thêm thú cưng
        [HttpGet]
        public IActionResult Add()
        {
            var users = _userManager.GetUsersInRoleAsync("Customer").Result.OrderBy(u => u.FullName).ToList();
            ViewData["UserId"] = new SelectList(users, "Id", "FullName");
            return View(new Pet());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Add(Pet pet, IFormFile? imageFile)
        {
            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            try
            {
                if (string.IsNullOrWhiteSpace(pet.UserId))
                {
                    TempData["ErrorMessage"] = "⚠️ Vui lòng chọn người sở hữu thú cưng.";
                    var users = await _userManager.GetUsersInRoleAsync("Customer");
                    ViewData["UserId"] = new SelectList(users.OrderBy(u => u.FullName), "Id", "FullName", pet.UserId);
                    return View(pet);
                }

                // Upload ảnh
                if (imageFile != null && imageFile.Length > 0)
                {
                    var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "pets");
                    if (!Directory.Exists(uploadsFolder))
                        Directory.CreateDirectory(uploadsFolder);

                    var fileName = Guid.NewGuid() + Path.GetExtension(imageFile.FileName);
                    var filePath = Path.Combine(uploadsFolder, fileName);
                    using var stream = new FileStream(filePath, FileMode.Create);
                    await imageFile.CopyToAsync(stream);

                    pet.ImageUrl = "/images/pets/" + fileName;
                }

                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();

                // Chuẩn hóa blockchain call
                var petRecord = new
                {
                    pet.PetId,
                    pet.Name,
                    pet.Type,
                    pet.Breed,
                    pet.Gender,
                    pet.Age,
                    pet.Weight,
                    OwnerName = (await _userManager.FindByIdAsync(pet.UserId))?.FullName ?? "Unknown",
                    pet.ImageUrl
                };

                await _blockchainService.AddPetBlockAsync(petRecord, "ADMIN_ADD", performedBy);

                TempData["SuccessMessage"] = "🎉 Thêm hồ sơ thú cưng thành công!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "❌ Không thể thêm hồ sơ: " + ex.Message;
                var users = await _userManager.GetUsersInRoleAsync("Customer");
                ViewData["UserId"] = new SelectList(users.OrderBy(u => u.FullName), "Id", "FullName", pet.UserId);
                return View(pet);
            }
        }

        // ✏️ Cập nhật thú cưng
        [HttpGet]
        public async Task<IActionResult> Update(int id)
        {
            var pet = await _context.Pets.Include(p => p.User).FirstOrDefaultAsync(p => p.PetId == id);
            if (pet == null) return RedirectToAction(nameof(Index));

            var users = await _userManager.GetUsersInRoleAsync("Customer");
            ViewData["UserId"] = new SelectList(users.OrderBy(u => u.FullName), "Id", "FullName", pet.UserId);
            return View(pet);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Update(int id, Pet pet, IFormFile? imageFile)
        {
            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            var existingPet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == id);
            if (existingPet == null) return RedirectToAction(nameof(Index));

            try
            {
                if (imageFile != null && imageFile.Length > 0)
                {
                    var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "pets");
                    if (!Directory.Exists(uploadsFolder))
                        Directory.CreateDirectory(uploadsFolder);

                    var fileName = Guid.NewGuid() + Path.GetExtension(imageFile.FileName);
                    var filePath = Path.Combine(uploadsFolder, fileName);
                    using var stream = new FileStream(filePath, FileMode.Create);
                    await imageFile.CopyToAsync(stream);

                    pet.ImageUrl = "/images/pets/" + fileName;
                }
                else
                {
                    pet.ImageUrl = existingPet.ImageUrl;
                }

                _context.Entry(existingPet).CurrentValues.SetValues(pet);
                await _context.SaveChangesAsync();

                var petRecord = new
                {
                    existingPet.PetId,
                    existingPet.Name,
                    existingPet.Type,
                    existingPet.Breed,
                    existingPet.Gender,
                    existingPet.Age,
                    existingPet.Weight,
                    OwnerName = existingPet.User?.FullName ?? "Unknown",
                    existingPet.ImageUrl
                };

                await _blockchainService.AddPetBlockAsync(petRecord, "ADMIN_UPDATE", performedBy);

                TempData["SuccessMessage"] = "✅ Cập nhật hồ sơ thú cưng thành công!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "❌ Lỗi khi cập nhật: " + ex.Message;
                var users = await _userManager.GetUsersInRoleAsync("Customer");
                ViewData["UserId"] = new SelectList(users.OrderBy(u => u.FullName), "Id", "FullName", pet.UserId);
                return View(pet);
            }
        }

        // 🗑️ Xóa
        [HttpPost, ActionName("DeleteConfirmed")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int PetId)
        {
            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            var pet = await _context.Pets.Include(p => p.User).FirstOrDefaultAsync(p => p.PetId == PetId);
            if (pet == null) return RedirectToAction(nameof(Index));

            try
            {
                var deletedPet = new DeletedPets
                {
                    OriginalPetId = pet.PetId,
                    Name = pet.Name,
                    Type = pet.Type,
                    Breed = pet.Breed,
                    Gender = pet.Gender,
                    Age = pet.Age,
                    Weight = pet.Weight,
                    UserId = pet.UserId,
                    ImageUrl = pet.ImageUrl,
                    DeletedAt = DateTime.Now,
                    DeletedBy = performedBy
                };

                _context.DeletedPets.Add(deletedPet);
                await _context.SaveChangesAsync(); // cần save để có Id

                // 2. Cập nhật Appointment liên quan
                var appointments = await _context.Appointments
                    .Where(a => a.PetId == PetId)
                    .ToListAsync();

                foreach (var a in appointments)
                {
                    a.DeletedPetId = deletedPet.Id; // gán DeletedPetId
                    a.Status = AppointmentStatus.Deleted; // đánh dấu đã xóa
                }
                await _context.SaveChangesAsync(); // lưu Appointment trước khi xóa Pet

                _context.DeletedPets.Add(deletedPet);
                await _context.SaveChangesAsync();

                _context.Pets.Remove(pet);
                await _context.SaveChangesAsync();

                // 5. Ghi log blockchain
                try
                {
                    var deletedPetRecord = new
                    {
                        deletedPet.OriginalPetId,
                        deletedPet.Name,
                        deletedPet.Type,
                        deletedPet.Breed,
                        deletedPet.Gender,
                        deletedPet.Age,
                        deletedPet.Weight,
                        deletedPet.UserId,
                        deletedPet.ImageUrl,
                        deletedPet.DeletedAt,
                        deletedPet.DeletedBy
                    };

                    var operation = isAdmin ? "ADMIN_DELETE" : "DELETE";
                    await _blockchainService.AddPetBlockAsync(deletedPetRecord, operation, performedBy);
                }
                catch (Exception bcEx)
                {
                    deletedPet.OriginalPetId,
                    deletedPet.Name,
                    deletedPet.Type,
                    deletedPet.Breed,
                    deletedPet.Gender,
                    deletedPet.Age,
                    deletedPet.Weight,
                    deletedPet.UserId,
                    deletedPet.ImageUrl,
                    deletedPet.DeletedAt,
                    deletedPet.DeletedBy
                };

                await _blockchainService.AddPetBlockAsync(deletedPetRecord, "ADMIN_DELETE", performedBy);
                TempData["SuccessMessage"] = "🗑️ Hồ sơ thú cưng đã được đánh dấu xóa!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "⚠️ Không thể xóa hồ sơ: " + ex.Message;
            }

            return RedirectToAction(nameof(Index));
        }
    }
}
