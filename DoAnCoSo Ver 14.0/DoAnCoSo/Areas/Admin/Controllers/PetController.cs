using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin")] // 👑 Chỉ Admin được phép
    public class PetController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public PetController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
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

        // 🔍 Xem chi tiết
        public async Task<IActionResult> Details(int id)
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

        // ➕ Thêm thú cưng (Admin có thể chọn user)
        [HttpGet]
        public IActionResult Add()
        {
            var usersInRole = _userManager.GetUsersInRoleAsync("Customer").Result;
            var orderedUsers = usersInRole.OrderBy(u => u.FullName).ToList();

            ViewData["UserId"] = new SelectList(orderedUsers, "Id", "FullName");
            return View(new Pet());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Add(Pet pet, IFormFile? imageFile)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(pet.UserId))
                {
                    TempData["ErrorMessage"] = "⚠️ Vui lòng chọn người sở hữu thú cưng.";
                    var usersInRole = await _userManager.GetUsersInRoleAsync("User");
                    ViewData["UserId"] = new SelectList(usersInRole.OrderBy(u => u.FullName), "Id", "FullName", pet.UserId);
                    return View(pet);
                }

                // 📸 Upload ảnh nếu có
                if (imageFile != null && imageFile.Length > 0)
                {
                    var fileName = Guid.NewGuid().ToString() + Path.GetExtension(imageFile.FileName);
                    var filePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot/images/pets", fileName);

                    using (var stream = new FileStream(filePath, FileMode.Create))
                        await imageFile.CopyToAsync(stream);

                    pet.ImageUrl = "/images/pets/" + fileName;
                }

                _context.Pets.Add(pet);
                await _context.SaveChangesAsync();

                TempData["SuccessMessage"] = "🎉 Đã thêm hồ sơ thú cưng thành công!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "❌ Không thể thêm hồ sơ: " + ex.Message;
                var usersInRole = await _userManager.GetUsersInRoleAsync("User");
                ViewData["UserId"] = new SelectList(usersInRole.OrderBy(u => u.FullName), "Id", "FullName", pet.UserId);
                return View(pet);
            }
        }

        // ✏️ Cập nhật
        [HttpGet]
        public async Task<IActionResult> Update(int id)
        {
            var pet = await _context.Pets
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.PetId == id);

            if (pet == null)
            {
                TempData["ErrorMessage"] = "❌ Không tìm thấy hồ sơ thú cưng.";
                return RedirectToAction(nameof(Index));
            }

            // Lấy danh sách user thường (không phải admin)
            var users = await _context.Users
                .Where(u => !(_context.UserRoles
                    .Any(ur => ur.UserId == u.Id && ur.RoleId ==
                        _context.Roles.FirstOrDefault(r => r.Name == "Admin").Id)))
                .OrderBy(u => u.FullName)
                .ToListAsync();

            ViewData["UserId"] = new SelectList(users, "Id", "FullName", pet.UserId);
            return View(pet);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Update(int id, Pet pet, IFormFile? imageFile)
        {
            if (id != pet.PetId)
            {
                TempData["ErrorMessage"] = "⚠️ ID không hợp lệ.";
                return RedirectToAction(nameof(Index));
            }

            try
            {
                var existingPet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == id);
                if (existingPet == null)
                {
                    TempData["ErrorMessage"] = "❌ Không tìm thấy hồ sơ cần sửa.";
                    return RedirectToAction(nameof(Index));
                }

                // Kiểm tra chủ sở hữu
                if (string.IsNullOrWhiteSpace(pet.UserId))
                {
                    TempData["ErrorMessage"] = "⚠️ Vui lòng chọn người sở hữu thú cưng.";

                    var users = await _context.Users
                        .Where(u => !(_context.UserRoles
                            .Any(ur => ur.UserId == u.Id && ur.RoleId ==
                                _context.Roles.FirstOrDefault(r => r.Name == "Admin").Id)))
                        .OrderBy(u => u.FullName)
                        .ToListAsync();

                    ViewData["UserId"] = new SelectList(users, "Id", "FullName", pet.UserId);
                    return View(pet);
                }

                // Xử lý ảnh mới (nếu có)
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
                    pet.ImageUrl = existingPet.ImageUrl;
                }

                _context.Entry(existingPet).CurrentValues.SetValues(pet);
                await _context.SaveChangesAsync();

                TempData["SuccessMessage"] = "✅ Cập nhật hồ sơ thú cưng thành công!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "❌ Lỗi khi cập nhật: " + ex.Message;

                var users = await _context.Users
                    .Where(u => !(_context.UserRoles
                        .Any(ur => ur.UserId == u.Id && ur.RoleId ==
                            _context.Roles.FirstOrDefault(r => r.Name == "Admin").Id)))
                    .OrderBy(u => u.FullName)
                    .ToListAsync();

                ViewData["UserId"] = new SelectList(users, "Id", "FullName", pet.UserId);
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
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            var pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == id);
            if (pet == null)
            {
                TempData["ErrorMessage"] = "⚠️ Không tìm thấy hồ sơ để xóa.";
                return RedirectToAction(nameof(Index));
            }

            try
            {
                if (!string.IsNullOrEmpty(pet.ImageUrl))
                {
                    var fullPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", pet.ImageUrl.TrimStart('/'));
                    if (System.IO.File.Exists(fullPath))
                        System.IO.File.Delete(fullPath);
                }

                _context.Pets.Remove(pet);
                await _context.SaveChangesAsync();

                TempData["SuccessMessage"] = "🗑️ Đã xóa hồ sơ thú cưng thành công!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "❌ Không thể xóa hồ sơ: " + ex.Message;
            }

            return RedirectToAction(nameof(Index));
        }
    }
}
