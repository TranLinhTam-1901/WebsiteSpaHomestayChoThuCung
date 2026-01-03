using DoAnCoSo.Models;
using DoAnCoSo.Models.Blockchain;
using DoAnCoSo.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Controllers.Api
{
    [Route("api/Pet")]
    [ApiController]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
    public class PetApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly BlockchainService _blockchainService;

        public PetApiController(ApplicationDbContext context, UserManager<ApplicationUser> userManager, BlockchainService blockchainService)
        {
            _context = context;
            _userManager = userManager;
            _blockchainService = blockchainService;
        }

        // 1. Lấy danh sách thú cưng
        [HttpGet]
        public async Task<IActionResult> GetPets()
        {
            var userId = _userManager.GetUserId(User);
            var pets = await _context.Pets
                .Where(p => p.UserId == userId)
                .OrderByDescending(p => p.PetId)
                .ToListAsync();
            return Ok(pets);
        }

        // 2. Lấy chi tiết thú cưng
        [HttpGet("{id}")]
        public async Task<IActionResult> GetPet(int id)
        {
            var userId = _userManager.GetUserId(User);
            var pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == id && p.UserId == userId);
            if (pet == null) return NotFound(new { message = "Không tìm thấy thú cưng." });
            return Ok(pet);
        }

        // 3. Thêm mới thú cưng (Sử dụng FromForm để Flutter gửi file ảnh)
        [HttpPost("Add")]
        public async Task<IActionResult> Add([FromForm] Pet pet, IFormFile? imageFile)
        {
            ModelState.Remove("UserId");
    ModelState.Remove("User");

            var currentUser = await _userManager.GetUserAsync(User);
            if (currentUser == null) return Unauthorized();

            if (imageFile != null && imageFile.Length > 0)
            {
                var fileName = Guid.NewGuid().ToString() + Path.GetExtension(imageFile.FileName);
                var filePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot/images/pets", fileName);
                using (var stream = new FileStream(filePath, FileMode.Create)) await imageFile.CopyToAsync(stream);
                pet.ImageUrl = "/images/pets/" + fileName;
            }

            pet.UserId = currentUser.Id;
            _context.Pets.Add(pet);
            await _context.SaveChangesAsync();

            // ⛓️ 1. Tạo 1 đối tượng duy nhất dùng cho cả Blockchain và Trả về API
            var dataResponse = new
            {
                pet.PetId,
                pet.Name,
                pet.Type,
                pet.Breed,
                pet.Gender,
                pet.Age,
                pet.Weight,
                pet.Height,
                pet.Color,
                pet.ImageUrl,
                pet.UserId,
                OwnerName = currentUser.FullName // Thêm cái này nếu Blockchain cần
            };

            // 2. Gửi vào Blockchain
            await _blockchainService.AddPetBlockAsync(dataResponse, "ADD", currentUser.FullName);

            // 3. Trả về cho App (Dùng chung dataResponse luôn cho gọn)
            return Ok(new { message = "Thêm thành công!", pet = dataResponse });
        }

        // 4. Cập nhật thú cưng
        [HttpPut("Update/{id}")]
        public async Task<IActionResult> Update(int id, [FromForm] Pet pet, IFormFile? imageFile)
        {
            // Bỏ qua kiểm tra lỗi cho User và UserId
            ModelState.Remove("User");
            ModelState.Remove("UserId");

            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var userId = _userManager.GetUserId(User);
            // Lưu ý: Dùng Include(p => p.User) nếu bạn cần lấy FullName chính xác từ existingPet
            var existingPet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == id && p.UserId == userId);

            if (existingPet == null) return NotFound(new { message = "Không có quyền chỉnh sửa hoặc không tìm thấy thú cưng." });

            var currentUser = await _userManager.GetUserAsync(User);

            if (imageFile != null)
            {
                var fileName = Guid.NewGuid().ToString() + Path.GetExtension(imageFile.FileName);
                var filePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot/images/pets", fileName);
                using (var stream = new FileStream(filePath, FileMode.Create)) await imageFile.CopyToAsync(stream);
                existingPet.ImageUrl = "/images/pets/" + fileName;
            }

            // Map data từ form gửi lên vào database
            existingPet.Name = pet.Name;
            existingPet.Type = pet.Type;
            existingPet.Breed = pet.Breed;
            existingPet.Gender = pet.Gender;
            existingPet.Age = pet.Age;
            existingPet.Weight = pet.Weight;
            existingPet.Height = pet.Height;
            existingPet.Color = pet.Color;
            existingPet.DateOfBirth = pet.DateOfBirth;
            existingPet.DistinguishingMarks = pet.DistinguishingMarks;
            existingPet.VaccinationRecords = pet.VaccinationRecords;
            existingPet.MedicalHistory = pet.MedicalHistory; // Kiểm tra xem C# đặt tên m hay M
            existingPet.Allergies = pet.Allergies;
            existingPet.DietPreferences = pet.DietPreferences;
            existingPet.HealthNotes = pet.HealthNotes;

            await _context.SaveChangesAsync();

            // ✅ 1. Tạo một Object "sạch" (không chứa thuộc tính User lồng nhau)
            var resultData = new
            {
                existingPet.PetId,
                existingPet.Name,
                existingPet.Type,
                existingPet.Breed,
                existingPet.Gender,
                existingPet.Age,
                existingPet.Weight,
                existingPet.ImageUrl,
                existingPet.UserId,
                OwnerName = currentUser?.FullName ?? "Hệ thống"
            };

            // ⛓️ 2. Gửi vào Blockchain Log Update
            await _blockchainService.AddPetBlockAsync(resultData, "UPDATE", resultData.OwnerName);

            // ✅ 3. Trả về cho App (Dùng resultData để CHẮC CHẮN không bị lỗi vòng lặp JSON 500)
            return Ok(new { message = "Cập nhật thành công!", pet = resultData });
        }

        // 5. Xóa thú cưng
        [HttpDelete("Delete/{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var currentUser = await _userManager.GetUserAsync(User);
            var userId = currentUser.Id;
            bool isAdmin = User.IsInRole("Admin");

            var pet = await _context.Pets.Include(p => p.User).FirstOrDefaultAsync(p => p.PetId == id);
            if (pet == null) return NotFound();

            if (!isAdmin && pet.UserId != userId) return Forbid();

            // 1. Sao lưu vào DeletedPets
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
                DeletedBy = currentUser.FullName
            };
            _context.DeletedPets.Add(deletedPet);

            // 2. Update Appointments
            var apps = await _context.Appointments.Where(a => a.PetId == id).ToListAsync();
            foreach (var a in apps) a.Status = AppointmentStatus.Deleted;

            // 3. Xóa Pet
            _context.Pets.Remove(pet);
            await _context.SaveChangesAsync();

            // ⛓️ Blockchain Log Delete
            var deletedRecord = new
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
            await _blockchainService.AddPetBlockAsync(deletedRecord, isAdmin ? "ADMIN_DELETE" : "DELETE", currentUser.FullName);

            return Ok(new { message = "Xóa thành công!" });
        }
    }
}