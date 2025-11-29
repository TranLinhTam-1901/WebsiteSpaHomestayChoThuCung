using DoAnCoSo.Models;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin")]
    public class UserController : Controller
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ApplicationDbContext _context;
        private readonly RoleManager<IdentityRole> _roleManager;
        public UserController(UserManager<ApplicationUser> userManager, ApplicationDbContext context, RoleManager<IdentityRole> roleManager)
        {
            _userManager = userManager;
            _context = context;
            _roleManager = roleManager;
        }


        public async Task<IActionResult> UserList(string? search)
        {

            // Bước 1: tạo query
            var query = _context.Users.Select(u => new UserInfoViewModel
            {
                Id = u.Id,
                FullName = u.FullName,
                UserName = u.UserName,
                Email = u.Email,
                Role = "",
                IsLocked = u.LockoutEnabled && u.LockoutEnd.HasValue && u.LockoutEnd.Value > DateTimeOffset.Now
            });

            // Bước 2: lọc theo từ khóa tìm kiếm
            if (!string.IsNullOrWhiteSpace(search))
            {
                string keyword = search.Trim().ToLower();

                query = query.Where(u =>
                    u.FullName.ToLower().Contains(keyword) ||
                    u.UserName.ToLower().Contains(keyword) ||
                    u.Email.ToLower().Contains(keyword)
                );
            }

            // Bước 3: thực thi query
            var users = await query.ToListAsync();


            foreach (var userViewModel in users)
            {
                var user = await _userManager.FindByIdAsync(userViewModel.Id);
                if (user != null)
                {
                    var roles = await _userManager.GetRolesAsync(user);
                    userViewModel.Role = string.Join(", ", roles);
                }
            }

            ViewBag.CurrentUserId = _userManager.GetUserId(User);

            return View(users);
        }



        [HttpGet]
        public async Task<IActionResult> EditUser(string id)
        {
            if (id == null) return NotFound();

            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound();

            var model = new UserInfoViewModel
            {
                Id = user.Id,
                UserName = user.UserName,
                Email = user.Email,
                FullName = user.FullName // Thêm dòng này để lấy FullName
            };

            // Lấy Role hiện tại của người dùng
            var roles = await _userManager.GetRolesAsync(user);
            model.Role = roles.FirstOrDefault(); // Lấy vai trò đầu tiên nếu có

            // Lấy danh sách tất cả các vai trò
            var allRoles = _roleManager.Roles.Select(r => r.Name).ToList();
            ViewBag.AllRoles = allRoles; // Truyền danh sách vai trò sang View

            return View(model);
        }


        [HttpPost]
        public async Task<IActionResult> EditUser(UserInfoViewModel model)
        {
            if (!ModelState.IsValid) return View(model);

            var user = await _userManager.FindByIdAsync(model.Id);
            if (user == null) return NotFound();

            user.UserName = model.UserName;
            user.Email = model.Email;
            user.FullName = model.FullName;

            // Lấy danh sách vai trò hiện tại của người dùng
            var existingRoles = await _userManager.GetRolesAsync(user);

            // Lấy vai trò mới được chọn từ dropdown
            var newRole = model.Role;

            // Nếu vai trò mới khác với vai trò hiện tại (hoặc người dùng chưa có vai trò)
            if (existingRoles.FirstOrDefault() != newRole)
            {
                // Xóa người dùng khỏi tất cả các vai trò hiện tại
                await _userManager.RemoveFromRolesAsync(user, existingRoles);

                // Thêm người dùng vào vai trò mới (nếu vai trò mới không phải là null hoặc empty)
                if (!string.IsNullOrEmpty(newRole))
                {
                    var addRoleResult = await _userManager.AddToRoleAsync(user, newRole);

                    if (!addRoleResult.Succeeded)
                    {
                        foreach (var error in addRoleResult.Errors)
                        {
                            ModelState.AddModelError("", $"Lỗi khi cập nhật vai trò: {error.Description}");
                        }
                        // Không return RedirectToAction ở đây, cần hiển thị lại form với lỗi
                    }
                }
            }

            var result = await _userManager.UpdateAsync(user);
            if (result.Succeeded)
            {
                return RedirectToAction("UserList");
            }
            else
            {
                ModelState.AddModelError("", "Có lỗi xảy ra khi cập nhật thông tin.");
                return View(model);
            }
        }

        //[HttpPost]
        //public async Task<IActionResult> DeleteUser(string id)
        //{
        //    if (id == null) return NotFound();

        //    var user = await _userManager.FindByIdAsync(id);
        //    if (user == null) return NotFound();

        //    // Lấy danh sách các Appointments liên quan đến người dùng này
        //    var appointmentsToDelete = _context.Appointments.Where(a => a.UserId == id);

        //    // Xóa các Appointments này
        //    _context.Appointments.RemoveRange(appointmentsToDelete);

        //    // Lưu các thay đổi vào database
        //    try
        //    {
        //        await _context.SaveChangesAsync();
        //    }
        //    catch (Exception ex)
        //    {
        //        ModelState.AddModelError("", $"Lỗi khi xóa các Appointments liên quan: {ex.Message}");
        //        return RedirectToAction("UserList"); // Hoặc xử lý lỗi khác nếu cần
        //    }

        //    // Sau khi đã xóa các Appointments, tiến hành xóa vai trò của người dùng
        //    var roles = await _userManager.GetRolesAsync(user);
        //    var removeRolesResult = await _userManager.RemoveFromRolesAsync(user, roles);

        //    if (!removeRolesResult.Succeeded)
        //    {
        //        foreach (var error in removeRolesResult.Errors)
        //        {
        //            ModelState.AddModelError("", $"Lỗi khi xóa vai trò của người dùng: {error.Description}");
        //        }
        //        return RedirectToAction("UserList"); // Hoặc xử lý lỗi khác nếu cần
        //    }

        //    // Cuối cùng, xóa tài khoản người dùng
        //    var result = await _userManager.DeleteAsync(user);

        //    if (result.Succeeded)
        //    {
        //        return RedirectToAction("UserList");
        //    }
        //    else
        //    {
        //        foreach (var error in result.Errors)
        //        {
        //            ModelState.AddModelError("", $"Có lỗi xảy ra khi xóa người dùng: {error.Description}");
        //        }
        //        return RedirectToAction("UserList");
        //    }
        //}


        // ✅ KHÓA USER
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> LockUser(string id)
        {
            if (id == null) return NotFound();

            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound();

            // Bật lockout và đặt thời gian khóa rất xa
            user.LockoutEnabled = true;
            user.LockoutEnd = DateTimeOffset.MaxValue;
            user.AccessFailedCount = 0;

            var result = await _userManager.UpdateAsync(user);

            if (result.Succeeded)
            {
                TempData["SuccessMessage"] = $"Đã khóa tài khoản của người dùng {user.UserName}.";
            }
            else
            {
                TempData["ErrorMessage"] = "Có lỗi xảy ra khi khóa người dùng.";
            }

            return RedirectToAction("UserList");
        }

        // ✅ MỞ KHÓA USER
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UnlockUser(string id)
        {
            if (id == null) return NotFound();

            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound();

            user.LockoutEnd = null;
            user.AccessFailedCount = 0;

            var result = await _userManager.UpdateAsync(user);

            if (result.Succeeded)
            {
                TempData["SuccessMessage"] = $"Đã mở khóa tài khoản của người dùng {user.UserName}.";
            }
            else
            {
                TempData["ErrorMessage"] = "Có lỗi xảy ra khi mở khóa người dùng.";
            }

            return RedirectToAction("UserList");
        }
    }
}
