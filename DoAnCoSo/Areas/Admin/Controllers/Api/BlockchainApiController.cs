using DoAnCoSo.Data;
using DoAnCoSo.Models;
using DoAnCoSo.Models.Blockchain;
using DoAnCoSo.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DoAnCoSo.Areas.Admin.Controllers.Api
{
    [Area("Admin")]
    [Route("api/admin/Blockchain")] // Cấu hình đường dẫn API
    [ApiController] // Attribute bắt buộc cho Web API
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Roles = "Admin")] // Chỉ Admin mới vào được
    public class BlockchainApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly BlockchainService _blockchainService;

        public BlockchainApiController(ApplicationDbContext context, BlockchainService blockchainService)
        {
            _context = context;
            _blockchainService = blockchainService;
        }

        // GET: api/admin/blockchain
        [HttpGet]
        public async Task<IActionResult> GetIndex()
        {
            // Lấy tất cả blockchain records
            var allRecords = await _context.BlockchainRecords
                                         .OrderByDescending(b => b.BlockNumber)
                                         .ToListAsync();

            // Parse ReferenceId sang int và lọc
            var petIds = allRecords
                         .Select(b => int.TryParse(b.ReferenceId, out int id) ? id : 0)
                         .Where(id => id != 0)
                         .Distinct()
                         .ToList();

            // Lấy pets còn tồn tại
            var pets = await _context.Pets
                                   .Where(p => petIds.Contains(p.PetId))
                                   .ToListAsync();

            // Lấy pets đã bị xóa
            var deletedPets = await _context.DeletedPets
                                          .Where(dp => petIds.Contains(dp.OriginalPetId))
                                          .ToListAsync();

            // Kết hợp cả hai vào dictionary
            var petsDict = pets.ToDictionary(p => p.PetId.ToString(), p => p.Name);

            foreach (var dp in deletedPets)
            {
                petsDict[dp.OriginalPetId.ToString()] = dp.Name;
            }

            // Trả về đối tượng JSON thay vì ViewModel của View
            return Ok(new
            {
                records = allRecords,
                petsDict = petsDict
            });
        }

        // GET: api/admin/blockchain/pet/5
        [HttpGet("pet/{petId}")]
        public async Task<IActionResult> GetByPet(int petId)
        {
            var pet = await _context.Pets.FirstOrDefaultAsync(p => p.PetId == petId);

            // Đối với API, nếu không tìm thấy pet có thể trả về lỗi hoặc vẫn trả về record nếu có trong DeletedPets
            string petName = pet?.Name;
            if (petName == null)
            {
                var deletedPet = await _context.DeletedPets.FirstOrDefaultAsync(dp => dp.OriginalPetId == petId);
                petName = deletedPet?.Name ?? "Unknown Pet";
            }

            var allRecords = await _context.BlockchainRecords
                                          .OrderByDescending(b => b.BlockNumber)
                                          .ToListAsync();

            // Lọc records của pet cụ thể
            var records = allRecords
                          .Where(b => int.TryParse(b.ReferenceId, out int id) && id == petId)
                          .ToList();

            return Ok(new
            {
                currentPetName = petName,
                records = records
            });
        }
    }
}