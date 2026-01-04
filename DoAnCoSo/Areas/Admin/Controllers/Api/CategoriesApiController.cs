using DoAnCoSo.Models;
using DoAnCoSo.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace YourProject.Controllers
{
    [Route("api/admin/categories")]
    [ApiController]
    [Area("Admin")]
    public class CategoriesApiController : ControllerBase
    {
        private readonly ICategoryRepository _categoryRepository;
        private readonly ApplicationDbContext _context;

        // Constructor injection để nhận repository
        public CategoriesApiController(ICategoryRepository categoryRepository, ApplicationDbContext context)
        {
            _categoryRepository = categoryRepository;
            _context = context;
        }

        // 1. Lấy tất cả Category
        [HttpGet]
        public async Task<IActionResult> GetAllCategories()
        {
            var categories = await _categoryRepository.GetAllAsync();
            if (categories == null || !categories.Any())
            {
                return NotFound("No categories found.");
            }
            return Ok(categories);
        }

        // 2. Lấy Category theo ID
        [HttpGet("{id}")]
        public async Task<IActionResult> GetCategoryById(int id)
        {
            var category = await _categoryRepository.GetByIdAsync(id);
            if (category == null)
            {
                return NotFound($"Category with ID {id} not found.");
            }
            return Ok(category);
        }

        // 3. Thêm mới Category
        [HttpPost]
        public async Task<IActionResult> AddCategory([FromBody] Category category)
        {
            if (category == null || !ModelState.IsValid)
            {
                return BadRequest("Invalid category data.");
            }

            // Làm sạch tên category trước khi lưu vào database
            category.Name = category.Name?.Trim();

            await _categoryRepository.AddAsync(category);
            return CreatedAtAction(nameof(GetCategoryById), new { id = category.Id }, category);
        }

        // 4. Cập nhật Category
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateCategory(int id, [FromBody] Category category)
        {
            if (id != category.Id || !ModelState.IsValid)
            {
                return BadRequest("Invalid category data.");
            }

            // Kiểm tra xem Category đã tồn tại trong cơ sở dữ liệu hay chưa
            var existingCategory = await _context.Categories.FindAsync(id);
            if (existingCategory == null)
            {
                return NotFound($"Category with ID {id} not found.");
            }

            // Gắn category hiện tại vào context nếu nó chưa được theo dõi
            _context.Entry(existingCategory).CurrentValues.SetValues(category);

            // Save changes to database
            await _context.SaveChangesAsync();
            return NoContent();
        }


        // 5. Ẩn Category (thay vì xóa)
        [HttpPatch("{id}/hide")]
        public async Task<IActionResult> HideCategory(int id)
        {
            var category = await _categoryRepository.GetByIdAsync(id);
            if (category == null)
            {
                return NotFound($"Category with ID {id} not found.");
            }

            // Mark as deleted (ẩn category)
            category.IsDeleted = true;
            await _categoryRepository.UpdateAsync(category);
            return NoContent();
        }

        // 7. Hiển thị lại Category (Mở ẩn)
        [HttpPatch("{id}/show")]
        public async Task<IActionResult> ShowCategory(int id)
        {
            var category = await _categoryRepository.GetByIdAsync(id);
            if (category == null)
            {
                return NotFound($"Category with ID {id} not found.");
            }

            // Đặt lại IsDeleted = false để hiện lại
            category.IsDeleted = false;
            await _categoryRepository.UpdateAsync(category);

            return NoContent(); // Trả về 204
        }

        // 6. Xóa Category (nếu bạn muốn xóa thật sự, có thể sử dụng DELETE)
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            var category = await _categoryRepository.GetByIdAsync(id);
            if (category == null)
            {
                return NotFound($"Category with ID {id} not found.");
            }

            await _categoryRepository.DeleteAsync(id);
            return NoContent();
        }
    }
}
