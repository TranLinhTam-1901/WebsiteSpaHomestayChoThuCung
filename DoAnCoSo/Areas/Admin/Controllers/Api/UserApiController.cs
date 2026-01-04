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
    [Route("api/admin/User")] // Định nghĩa route cho API
    [ApiController] // Thuộc tính bắt buộc cho Web API
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Roles = "Admin")] // Chỉ Admin mới vào được
    public class UserController : ControllerBase // Kế thừa ControllerBase thay vì Controller
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

        // GET: api/admin/user/list?search=...
        [HttpGet("list")]
        public async Task<IActionResult> GetUserList(string? search)
        {
            var query = _context.Users.Select(u => new UserInfoViewModel
            {
                Id = u.Id,
                FullName = u.FullName,
                UserName = u.UserName,
                Email = u.Email,
                PhoneNumber = u.PhoneNumber, // THÊM DÒNG NÀY
                Address = u.Address,         // THÊM DÒNG NÀY (Giả sử ApplicationUser có field Address)
                Role = "",
                IsLocked = u.LockoutEnabled && u.LockoutEnd.HasValue && u.LockoutEnd.Value > DateTimeOffset.Now
            });

            if (!string.IsNullOrWhiteSpace(search))
            {
                string keyword = search.Trim().ToLower();
                query = query.Where(u =>
                    u.FullName.ToLower().Contains(keyword) ||
                    u.UserName.ToLower().Contains(keyword) ||
                    u.Email.ToLower().Contains(keyword)
                );
            }

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

            return Ok(users); // Trả về danh sách JSON
        }

        // GET: api/admin/user/details/{id}
        [HttpGet("details/{id}")]
        public async Task<IActionResult> GetUserDetails(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound(new { message = "Không tìm thấy người dùng" });

            var roles = await _userManager.GetRolesAsync(user);
            var model = new UserInfoViewModel
            {
                Id = user.Id,
                UserName = user.UserName,
                Email = user.Email,
                FullName = user.FullName,
                PhoneNumber = user.PhoneNumber, // Thêm dòng này
                Address = user.Address,         // Thêm dòng này
                Role = roles.FirstOrDefault()
            };

            return Ok(new
            {
                User = model,
                AllRoles = await _roleManager.Roles.Select(r => r.Name).ToListAsync()
            });
        }

        // POST: api/admin/user/edit
        [HttpPost("edit")]
        public async Task<IActionResult> UpdateUser([FromBody] UserInfoViewModel model)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { message = "Dữ liệu không hợp lệ", errors = ModelState });

                var user = await _userManager.FindByIdAsync(model.Id);
                if (user == null)
                    return NotFound(new { message = "Không tìm thấy người dùng ID: " + model.Id });

                // 1. Cập nhật thông tin cơ bản
                user.UserName = model.UserName;
                user.Email = model.Email;
                user.FullName = model.FullName;
                user.PhoneNumber = model.PhoneNumber;
                user.Address = model.Address;

                // 2. XỬ LÝ CẬP NHẬT ROLE
                if (!string.IsNullOrEmpty(model.Role))
                {
                    // Lấy danh sách Role hiện tại của User
                    var currentRoles = await _userManager.GetRolesAsync(user);

                    // Nếu Role gửi lên khác với Role hiện tại thì mới thực hiện đổi
                    if (!currentRoles.Contains(model.Role))
                    {
                        // Xóa tất cả Role cũ
                        await _userManager.RemoveFromRolesAsync(user, currentRoles);

                        // Kiểm tra Role mới có tồn tại trong hệ thống không trước khi thêm
                        if (await _roleManager.RoleExistsAsync(model.Role))
                        {
                            await _userManager.AddToRoleAsync(user, model.Role);
                        }
                    }
                }

                // 3. Lưu các thay đổi thông tin cơ bản
                var result = await _userManager.UpdateAsync(user);
                if (result.Succeeded) return Ok(new { message = "Cập nhật thành công" });

                return BadRequest(new { message = "Identity Error", errors = result.Errors });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Server Crash: " + ex.Message });
            }
        }

        // POST: api/admin/user/lock/{id}
        [HttpPost("lock/{id}")]
        public async Task<IActionResult> LockUser(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound();

            user.LockoutEnabled = true;
            user.LockoutEnd = DateTimeOffset.MaxValue;

            var result = await _userManager.UpdateAsync(user);
            if (result.Succeeded) return Ok(new { message = $"Đã khóa {user.UserName}" });

            return BadRequest(new { message = "Lỗi khi khóa người dùng" });
        }

        // POST: api/admin/user/unlock/{id}
        [HttpPost("unlock/{id}")]
        public async Task<IActionResult> UnlockUser(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound();

            user.LockoutEnd = null;

            var result = await _userManager.UpdateAsync(user);
            if (result.Succeeded) return Ok(new { message = $"Đã mở khóa {user.UserName}" });

            return BadRequest(new { message = "Lỗi khi mở khóa người dùng" });
        }
    }
}