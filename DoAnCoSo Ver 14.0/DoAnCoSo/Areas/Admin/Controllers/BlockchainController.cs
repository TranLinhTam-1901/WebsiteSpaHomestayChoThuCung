using DoAnCoSo.Data;
using DoAnCoSo.Models;
using DoAnCoSo.Models.Blockchain;
using DoAnCoSo.Services;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Linq;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class BlockchainController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly BlockchainService _blockchainService;

        public BlockchainController(ApplicationDbContext context, BlockchainService blockchainService)
        {
            _context = context;
            _blockchainService = blockchainService;
        }

        public IActionResult Index()
        {
            // Lấy tất cả blockchain records
            var allRecords = _context.BlockchainRecords
                                     .OrderByDescending(b => b.BlockNumber)
                                     .ToList();

            // Parse ReferenceId sang int và lọc
            var petIds = allRecords
                         .Select(b => int.TryParse(b.ReferenceId, out int id) ? id : 0)
                         .Where(id => id != 0)
                         .Distinct()
                         .ToList();

            // Lấy pets còn tồn tại
            var pets = _context.Pets
                               .Where(p => petIds.Contains(p.PetId))
                               .ToList();

            // Lấy pets đã bị xóa
            var deletedPets = _context.DeletedPets
                                      .Where(dp => petIds.Contains(dp.OriginalPetId))
                                      .ToList();

            // Kết hợp cả hai vào dictionary, ưu tiên tên từ DeletePets nếu có
            var petsDict = pets.ToDictionary(p => p.PetId.ToString(), p => p.Name);

            foreach (var dp in deletedPets)
            {
                petsDict[dp.OriginalPetId.ToString()] = dp.Name; // ghi đè tên nếu pet đã xóa
            }

            var viewModel = new BlockchainViewModel
            {
                Records = allRecords,
                PetsDict = petsDict
            };

            return View(viewModel);
        }

        public IActionResult ViewByPet(int petId)
        {
            var pet = _context.Pets.FirstOrDefault(p => p.PetId == petId);
            if (pet == null) return NotFound();

            // Lọc trong memory: ReferenceId là string, convert sang int
            var records = _context.BlockchainRecords
                                  .OrderByDescending(b => b.BlockNumber)
                                  .AsEnumerable() // bắt buộc load memory
                                  .Where(b => int.TryParse(b.ReferenceId, out int id) && id == petId)
                                  .ToList();

            var viewModel = new BlockchainViewModel
            {
                CurrentPetName = pet.Name,
                Records = records
            };

            return View(viewModel);
        }

        // Chi tiết block
        public async Task<IActionResult> Details(int id)
        {
            var block = await _context.BlockchainRecords.FindAsync(id);

            if (block == null)
                return NotFound();

            return View(block);
        }
    }
}