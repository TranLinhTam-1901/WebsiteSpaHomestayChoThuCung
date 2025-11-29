using DoAnCoSo.Models;
using DoAnCoSo.Models.Blockchain;
using DoAnCoSo.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Controllers
{
    [Authorize]
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

        // 🐾 Danh sách thú cưng
        public async Task<IActionResult> Index()
        {
            var userId = _userManager.GetUserId(User);
            var pets = await _context.Pets
                .Where(p => p.UserId == userId)
                .OrderByDescending(p => p.PetId)
                .ToListAsync();

            return View(pets);
        }

        // 📋 Chi tiết
        public async Task<IActionResult> Details(int id)
        {
            var userId = _userManager.GetUserId(User);
            var pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == id && p.UserId == userId);

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
            return View(new Pet()); // luôn truyền model rỗng
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Add(Pet pet, IFormFile? imageFile)
        {
            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            try
            {
                var userId = _userManager.GetUserId(User);
                if (string.IsNullOrEmpty(userId))
                {
                    TempData["ErrorMessage"] = "⚠️ Bạn cần đăng nhập để thêm hồ sơ thú cưng.";
                    return RedirectToAction("Login", "Account");
                }

                // Upload ảnh nếu có
                if (imageFile != null && imageFile.Length > 0)
                {
                    var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "pets");
                    if (!Directory.Exists(uploadsFolder))
                        Directory.CreateDirectory(uploadsFolder);

                    var fileName = Guid.NewGuid().ToString() + Path.GetExtension(imageFile.FileName);
                    var filePath = Path.Combine(uploadsFolder, fileName);

                    using (var stream = new FileStream(filePath, FileMode.Create))
                        await imageFile.CopyToAsync(stream);

                    pet.ImageUrl = "/images/pets/" + fileName;
                }

                // Validate cơ bản
                if (string.IsNullOrWhiteSpace(pet.Name) || string.IsNullOrWhiteSpace(pet.Type))
                {
                    TempData["ErrorMessage"] = "⚠️ Vui lòng nhập tên và loại thú cưng.";
                    return View(pet);
                }

                pet.UserId = userId;
                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();

                // Serialize dữ liệu an toàn
                var petRecord = new
                {
                    pet.PetId,
                    pet.Name,
                    pet.Type,
                    pet.Breed,
                    pet.Gender,
                    pet.Age,
                    pet.Weight,
                    OwnerName = currentUser?.FullName ?? "Unknown",
                    pet.ImageUrl
                };

                await _blockchainService.AddPetBlockAsync(petRecord, "ADD", performedBy);

                TempData["SuccessMessage"] = "🎉 Thêm hồ sơ thú cưng thành công!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "❌ Không thể lưu thú cưng: " + ex.Message;
                return View(pet);
            }
        }

        // ✏️ Cập nhật thú cưng
        [HttpGet]
        public async Task<IActionResult> Update(int id)
        {
            var userId = _userManager.GetUserId(User);
            var pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == id && p.UserId == userId);

            if (pet == null)
            {
                TempData["ErrorMessage"] = "❌ Không tìm thấy hồ sơ thú cưng.";
                return RedirectToAction(nameof(Index));
            }

            return View(pet);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Update(int id, Pet pet, IFormFile? imageFile)
        {
            var userId = _userManager.GetUserId(User);
            var existingPet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == id && p.UserId == userId);

            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";

            if (existingPet == null)
            {
                TempData["ErrorMessage"] = "❌ Bạn không có quyền chỉnh sửa hồ sơ này.";
                return RedirectToAction(nameof(Index));
            }

            try
            {
                // Upload ảnh mới nếu có
                if (imageFile != null && imageFile.Length > 0)
                {
                    var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "pets");
                    if (!Directory.Exists(uploadsFolder))
                        Directory.CreateDirectory(uploadsFolder);

                    var fileName = Guid.NewGuid().ToString() + Path.GetExtension(imageFile.FileName);
                    var filePath = Path.Combine(uploadsFolder, fileName);

                    using (var stream = new FileStream(filePath, FileMode.Create))
                        await imageFile.CopyToAsync(stream);

                    pet.ImageUrl = "/images/pets/" + fileName;
                }
                else
                {
                    pet.ImageUrl = existingPet.ImageUrl; // giữ lại ảnh cũ
                }

                pet.UserId = userId; // đảm bảo UserId không bị thay đổi

                _context.Entry(existingPet).CurrentValues.SetValues(pet);
                await _context.SaveChangesAsync();

                // Serialize JSON an toàn
                var petRecord = new
                {
                    existingPet.PetId,
                    existingPet.Name,
                    existingPet.Type,
                    existingPet.Breed,
                    existingPet.Gender,
                    existingPet.Age,
                    existingPet.Weight,
                    OwnerName = currentUser?.FullName ?? "Unknown",
                    existingPet.ImageUrl
                };

                await _blockchainService.AddPetBlockAsync(petRecord, "UPDATE", performedBy);

                TempData["SuccessMessage"] = "✅ Cập nhật thông tin thành công!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "❌ Lỗi khi cập nhật: " + ex.Message;
                return View(pet);
            }
        }

        // 🗑️ Xóa
        [HttpGet]
        public async Task<IActionResult> Delete(int id)
        {
            var pet = await _context.Pets
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.PetId == id);

            if (pet == null)
            {
                TempData["ErrorMessage"] = "❌ Không tìm thấy hồ sơ thú cưng.";
                return RedirectToAction(nameof(Index));
            }

            return View(pet);
        }

        [HttpPost, ActionName("DeleteConfirmed")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int PetId)
        {
            var currentUser = await _userManager.GetUserAsync(User);
            var performedBy = currentUser?.FullName ?? "Hệ thống";
            var userId = _userManager.GetUserId(User);
            bool isAdmin = User.IsInRole("Admin");

            // Lấy pet kèm User
            var pet = await _context.Pets
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.PetId == PetId);

            if (pet == null)
            {
                TempData["ErrorMessage"] = "❌ Không tìm thấy hồ sơ thú cưng.";
                return RedirectToAction(nameof(Index));
            }

            // Kiểm tra quyền
            if (!isAdmin && pet.UserId != userId)
            {
                TempData["ErrorMessage"] = "❌ Bạn không có quyền xóa hồ sơ này.";
                return RedirectToAction(nameof(Index));
            }

            try
            {
                // 1. Tạo bản ghi DeletedPet
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

                // 3. Xóa ảnh vật lý (nếu có)
                if (!string.IsNullOrEmpty(pet.ImageUrl))
                {
                    try
                    {
                        var fullPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", pet.ImageUrl.TrimStart('/'));
                        if (System.IO.File.Exists(fullPath))
                            System.IO.File.Delete(fullPath);
                    }
                    catch (Exception fileEx)
                    {
                        Console.WriteLine("Lỗi xóa file ảnh: " + fileEx.Message);
                    }
                }

                // 4. Xóa Pet khỏi bảng chính
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
                    Console.WriteLine("Blockchain log lỗi (bỏ qua): " + bcEx.Message);
                }

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
