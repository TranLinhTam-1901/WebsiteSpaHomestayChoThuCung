using DoAnCoSo.Models;
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

        public PetController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
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
            var model = new Pet();
            return View(model); // ✅ luôn truyền model rỗng xuống View
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Add(Pet pet, IFormFile? imageFile)
        {
            try
            {
                var userId = _userManager.GetUserId(User);
                if (string.IsNullOrEmpty(userId))
                {
                    TempData["ErrorMessage"] = "⚠️ Bạn cần đăng nhập để thêm hồ sơ thú cưng.";
                    return RedirectToAction("Login", "Account");
                }

                // Upload ảnh
                if (imageFile != null && imageFile.Length > 0)
                {
                    var fileName = Guid.NewGuid().ToString() + Path.GetExtension(imageFile.FileName);
                    var filePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot/images/pets", fileName);

                    using (var stream = new FileStream(filePath, FileMode.Create))
                    {
                        await imageFile.CopyToAsync(stream);
                    }

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

                TempData["SuccessMessage"] = "🎉 Thêm hồ sơ thú cưng thành công!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "❌ Không thể lưu thú cưng: " + ex.Message;
                return View(pet);
            }
        }

        // ✏️ Cập nhật
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

            if (existingPet == null)
            {
                TempData["ErrorMessage"] = "❌ Bạn không có quyền chỉnh sửa hồ sơ này.";
                return RedirectToAction(nameof(Index));
            }

            try
            {
                // Upload ảnh mới (nếu có)
                if (imageFile != null && imageFile.Length > 0)
                {
                    var fileName = Guid.NewGuid().ToString() + Path.GetExtension(imageFile.FileName);
                    var filePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot/images/pets", fileName);

                    using (var stream = new FileStream(filePath, FileMode.Create))
                    {
                        await imageFile.CopyToAsync(stream);
                    }

                    pet.ImageUrl = "/images/pets/" + fileName;
                }
                else
                {
                    // Giữ lại ảnh cũ nếu không upload ảnh mới
                    pet.ImageUrl = existingPet.ImageUrl;
                }

                // Gán lại UserId
                pet.UserId = userId;

                _context.Entry(existingPet).CurrentValues.SetValues(pet);
                await _context.SaveChangesAsync();

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
            var userId = _userManager.GetUserId(User);
            var pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == id && p.UserId == userId);

            if (pet == null)
            {
                TempData["ErrorMessage"] = "❌ Không tìm thấy hồ sơ thú cưng.";
                return RedirectToAction(nameof(Index));
            }

            return View(pet);
        }

        [HttpPost, ActionName("DeleteConfirmed")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            var userId = _userManager.GetUserId(User);
            var pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == id && p.UserId == userId);

            if (pet == null)
            {
                TempData["ErrorMessage"] = "❌ Không tìm thấy hồ sơ để xóa.";
                return RedirectToAction(nameof(Index));
            }

            try
            {
                // Nếu có ảnh -> xóa file vật lý
                if (!string.IsNullOrEmpty(pet.ImageUrl))
                {
                    var fullPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", pet.ImageUrl.TrimStart('/'));
                    if (System.IO.File.Exists(fullPath))
                        System.IO.File.Delete(fullPath);
                }

                _context.Pets.Remove(pet);
                await _context.SaveChangesAsync();

                TempData["SuccessMessage"] = "🗑️ Xóa hồ sơ thú cưng thành công!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "⚠️ Không thể xóa hồ sơ: " + ex.Message;
            }

            return RedirectToAction(nameof(Index));
        }
    }
}
