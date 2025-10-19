using DoAnCoSo.Models;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class PromotionController : Controller
    {
        private readonly ApplicationDbContext _context;

        public PromotionController(ApplicationDbContext context)
        {
            _context = context;
        }

        // Danh sách khuyến mãi
        public async Task<IActionResult> Index()
        {
            var promos = await _context.Promotions.OrderByDescending(p => p.StartDate).ToListAsync();
            return View(promos);
        }

        // GET: Tạo khuyến mãi
        public IActionResult Create()
        {
            var model = new Promotion
            {
                IsCampaign = false,                
                StartDate = DateTime.Today,
                EndDate = DateTime.Today.AddDays(7)
            };
            return View(model);
        }

        [HttpPost]
        public async Task<IActionResult> Create(Promotion promo, IFormFile? imageFile)
        {
            if (!ModelState.IsValid)
            {
                return View(promo);
            }

            // 🖼️ Nếu có upload ảnh khuyến mãi
            if (imageFile != null && imageFile.Length > 0)
            {
                // Đường dẫn thư mục lưu ảnh (wwwroot/images/promotions)
                var uploadPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "promotions");
                if (!Directory.Exists(uploadPath))
                {
                    Directory.CreateDirectory(uploadPath);
                }

                // Đặt tên file duy nhất (tránh trùng)
                var fileName = $"{Guid.NewGuid()}{Path.GetExtension(imageFile.FileName)}";
                var filePath = Path.Combine(uploadPath, fileName);

                // Lưu file vào server
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await imageFile.CopyToAsync(stream);
                }

                // Lưu tên file (không lưu full path)
                promo.Image = fileName;
            }

            // Nếu không có ảnh upload, có thể đặt ảnh mặc định (tùy bạn)
            if (string.IsNullOrEmpty(promo.Image))
            {
                promo.Image = "default-promo.jpg"; // ảnh mặc định trong wwwroot/images/promotions/
            }

            // Thêm khuyến mãi vào DB
            _context.Promotions.Add(promo);
            await _context.SaveChangesAsync();

            TempData["Success"] = "🎉 Tạo khuyến mãi thành công!";
            return RedirectToAction(nameof(Index));
        }

        public async Task<IActionResult> Edit(int id)
        {
            var promo = await _context.Promotions.FindAsync(id);
            if (promo == null) return NotFound();
            return View(promo);
        }

       
        [HttpPost]
        public async Task<IActionResult> Edit(int id, Promotion promo)
        {
            if (id != promo.Id) return NotFound();

            if (ModelState.IsValid)
            {
                _context.Update(promo);
                await _context.SaveChangesAsync();
                TempData["Success"] = "Cập nhật thành công!";
                return RedirectToAction(nameof(Index));
            }
            return View(promo);
        }

        // Xóa khuyến mãi
        [HttpPost]
        public async Task<IActionResult> Delete(int id)
        {
            var promo = await _context.Promotions.FindAsync(id);
            if (promo == null) return NotFound();

            _context.Promotions.Remove(promo);
            await _context.SaveChangesAsync();
            TempData["Success"] = "Đã xóa khuyến mãi!";
            return RedirectToAction(nameof(Index));
        }

        public async Task<IActionResult> UsageDetails(int id)
        {
            var promo = await _context.Promotions
                .Include(p => p.OrderPromotions)
                    .ThenInclude(op => op.Order)
                        .ThenInclude(o => o.User)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (promo == null) return NotFound();

            var usageList = promo.OrderPromotions.Select(op => new PromotionUsageViewModel
            {
                UserName = op.Order.User.FullName ?? op.Order.User.UserName,
                Email = op.Order.User.Email,
                OrderId = op.Order.Id,
                UsedAt = op.UsedAt,
                DiscountApplied = op.DiscountApplied
            }).ToList();

            ViewBag.Promotion = promo;
            return View(usageList);

        }



    }

}
