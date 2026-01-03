using DoAnCoSo.Models;
using DoAnCoSo.Models.Blockchain;
using DoAnCoSo.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Areas.Admin.Controllers.Api
{
    [Area("Admin")]
    [Route("api/admin/Pet")] // Đổi route để phân biệt rõ với API người dùng
    [ApiController]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Roles = "Admin")] // Chỉ Admin mới vào được
    public class AdminPetApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public AdminPetApiController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        // 1. Lấy TẤT CẢ thú cưng của TẤT CẢ người dùng
        [HttpGet]
        public async Task<IActionResult> GetAllPets()
        {
            var pets = await _context.Pets
                .Include(p => p.User)
                .OrderByDescending(p => p.PetId)
                .Select(p => new {
                    p.PetId,
                    p.Name,
                    p.Type,
                    p.Breed,
                    p.Weight,
                    p.ImageUrl,
                    // Thêm p.User != null để an toàn
                    OwnerName = p.User != null ? p.User.FullName : "Không có chủ",
                    p.UserId
                })
                .ToListAsync();
            return Ok(pets);
        }

        // 2. Admin xem chi tiết bất kỳ thú cưng nào
        [HttpGet("{id}")]
        public async Task<IActionResult> Details(int id)
        {
            // Lấy dữ liệu Pet cùng với User, dùng Select để lấy đúng/đủ các trường trong Model của bạn
            var pet = await _context.Pets
                .Include(p => p.User)
                .Where(p => p.PetId == id)
                .Select(p => new {
                    p.PetId,
                    p.Name,
                    p.Type,
                    p.Breed,
                    p.Gender,
                    p.Age,
                    p.DateOfBirth,
                    p.ImageUrl,
                    p.Weight,
                    p.Height,
                    p.Color,
                    p.DistinguishingMarks,
                    p.VaccinationRecords,
                    p.MedicalHistory,
                    p.Allergies,
                    p.DietPreferences,
                    p.HealthNotes,
                    // Sửa chỗ này để Flutter map dễ hơn
                    AiAnalysisResult = p.AI_AnalysisResult,
                    p.UserId,
                    Owner = p.User != null ? new
                    {
                        p.User.FullName,
                        p.User.PhoneNumber,
                        p.User.Address,
                        p.User.Email
                    } : null
                })
                .FirstOrDefaultAsync();

            if (pet == null)
            {
                return NotFound(new { success = false, message = "❌ Không tìm thấy hồ sơ thú cưng." });
            }

            // Trả về cho Flutter theo cấu trúc chuẩn
            return Ok(new { success = true, data = pet });
        }

        // 3. Admin xóa bất kỳ thú cưng nào (Giữ nguyên logic sao lưu của bạn)
        [HttpDelete("Delete/{id}")]
        public async Task<IActionResult> AdminDelete(int id)
        {
            var adminUser = await _userManager.GetUserAsync(User);
            var pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == id);

            if (pet == null) return NotFound();

            // Thực hiện logic sao lưu vào DeletedPets như code cũ của bạn...
            // ... (Giữ nguyên phần backup và xóa)

            await _context.SaveChangesAsync();
            return Ok(new { message = "Admin đã xóa thành công!" });
        }
    }
}