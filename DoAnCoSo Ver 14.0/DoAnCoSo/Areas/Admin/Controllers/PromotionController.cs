using DoAnCoSo.Models;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Net.NetworkInformation;
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
        public async Task<IActionResult> Create(Promotion promo, IFormFile? imageFile, string[]? AssignedUserIdentifiers)
        {
            if (!ModelState.IsValid)
            {
                return View(promo);
            }

            // Nếu có upload ảnh khuyến mãi
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

           // 🧩 3.Nếu là mã riêng → gán user ngay khi tạo
        if (promo.IsPrivate && AssignedUserIdentifiers != null && AssignedUserIdentifiers.Any())
            {
                var validUserIds = await _context.Users
                    .Where(u => AssignedUserIdentifiers.Contains(u.Id))
                    .Select(u => u.Id)
                    .ToListAsync();

                foreach (var userId in validUserIds)
                {
                    // tránh trùng lặp trong trường hợp đã gán trước
                    bool exists = await _context.UserPromotions
                        .AnyAsync(up => up.UserId == userId && up.PromotionId == promo.Id);

                    if (!exists)
                    {
                        _context.UserPromotions.Add(new UserPromotion
                        {
                            UserId = userId,
                            PromotionId = promo.Id,
                            IsUsed = false,
                            DateSaved = DateTime.Now
                        });
                    }
                }
                await _context.SaveChangesAsync();
            }

            TempData["Success"] = "🎉 Tạo khuyến mãi thành công!";
            return RedirectToAction(nameof(Index));
        }

        public async Task<IActionResult> Edit(int id)
        {
            var promo = await _context.Promotions.FindAsync(id);
            if (promo == null) return NotFound();

            if (promo.IsPrivate)
            {
                var assigned = await _context.UserPromotions
                    .Where(up => up.PromotionId == promo.Id)
                    .Include(up => up.User)
                    .Select(up => new { up.User.Id, up.User.FullName, up.User.Email })
                    .ToListAsync();

                ViewBag.AssignedUsers = assigned;
            }

            return View(promo);
        }


        [HttpPost]
        public async Task<IActionResult> Edit(int id, Promotion promo, IFormFile? imageFile, string[]? AssignedUserIdentifiers)
        {
            if (id != promo.Id) return NotFound();

            if (!ModelState.IsValid)
                return View(promo);

            // 🧱 Lấy bản ghi cũ từ DB để tránh mất dữ liệu
            var existingPromo = await _context.Promotions.FindAsync(id);
            if (existingPromo == null) return NotFound();

            // 🔹 Cập nhật các trường cho phép chỉnh sửa
            existingPromo.Title = promo.Title;
            existingPromo.Code = promo.Code;
            existingPromo.ShortDescription = promo.ShortDescription;
            existingPromo.Description = promo.Description;
            existingPromo.Discount = promo.Discount;
            existingPromo.IsPercent = promo.IsPercent;
            existingPromo.StartDate = promo.StartDate;
            existingPromo.EndDate = promo.EndDate;
            existingPromo.MinOrderValue = promo.MinOrderValue;
            existingPromo.MaxUsage = promo.MaxUsage;
            existingPromo.MaxUsagePerUser = promo.MaxUsagePerUser;
            existingPromo.IsActive = promo.IsActive;
            existingPromo.IsPrivate = promo.IsPrivate;
            existingPromo.IsCampaign = promo.IsCampaign;

            // 🖼️ Nếu có upload ảnh mới → lưu và thay thế ảnh cũ
            if (imageFile != null && imageFile.Length > 0)
            {
                var uploadPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "promotions");
                if (!Directory.Exists(uploadPath))
                {
                    Directory.CreateDirectory(uploadPath);
                }

                // Tạo tên file duy nhất
                var fileName = $"{Guid.NewGuid()}{Path.GetExtension(imageFile.FileName)}";
                var filePath = Path.Combine(uploadPath, fileName);

                // Xóa ảnh cũ (nếu có và không phải ảnh mặc định)
                if (!string.IsNullOrEmpty(existingPromo.Image) && existingPromo.Image != "default-promo.jpg")
                {
                    var oldPath = Path.Combine(uploadPath, existingPromo.Image);
                    if (System.IO.File.Exists(oldPath))
                        System.IO.File.Delete(oldPath);
                }

                // Lưu ảnh mới
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await imageFile.CopyToAsync(stream);
                }

                existingPromo.Image = fileName;
            }

            // 🔸 Nếu không upload ảnh mới thì giữ nguyên ảnh cũ
            // (đã được đảm bảo vì ta chỉ ghi đè khi imageFile != null)

            // 🧩 Nếu là mã riêng tư → cập nhật lại danh sách user
            var existingUserPromos = _context.UserPromotions.Where(up => up.PromotionId == promo.Id);
            _context.UserPromotions.RemoveRange(existingUserPromos);

            if (promo.IsPrivate && AssignedUserIdentifiers != null && AssignedUserIdentifiers.Any())
            {
                var validUserIds = await _context.Users
                    .Where(u => AssignedUserIdentifiers.Contains(u.Id))
                    .Select(u => u.Id)
                    .ToListAsync();

                foreach (var userId in validUserIds)
                {
                    _context.UserPromotions.Add(new UserPromotion
                    {
                        UserId = userId,
                        PromotionId = promo.Id,
                        IsUsed = false,
                        DateSaved = DateTime.Now
                    });
                }
            }

            await _context.SaveChangesAsync();

            TempData["Success"] = "✅ Cập nhật khuyến mãi thành công!";
            return RedirectToAction(nameof(Index));
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

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> AssignToUser(int promotionId, string userIdentifier)
        {
            // 🧩 1. Kiểm tra tồn tại khuyến mãi
            var promo = await _context.Promotions.FindAsync(promotionId);
            if (promo == null)
            {
                TempData["Error"] = "❌ Không tìm thấy khuyến mãi.";
                return RedirectToAction(nameof(Index));
            }

            // 🧩 2. Nếu mã là Public thì không cho gán
            if (!promo.IsPrivate)
            {
                TempData["Info"] = "⚠️ Mã này là public, không thể gán cho người dùng cụ thể.";
                return RedirectToAction(nameof(Edit), new { id = promotionId });
            }

            // 🧩 3. Tìm user bằng ID hoặc Email (bỏ khoảng trắng + không phân biệt hoa thường)
            userIdentifier = userIdentifier?.Trim();
            if (string.IsNullOrEmpty(userIdentifier))
            {
                TempData["Error"] = "⚠️ Vui lòng nhập UserId hoặc Email hợp lệ.";
                return RedirectToAction(nameof(Edit), new { id = promotionId });
            }

            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == userIdentifier || u.Email.ToLower() == userIdentifier.ToLower());

            if (user == null)
            {
                TempData["Error"] = "❌ Không tìm thấy người dùng theo ID hoặc Email.";
                return RedirectToAction(nameof(Edit), new { id = promotionId });
            }

            // 🧩 4. Kiểm tra trùng gán
            var exists = await _context.UserPromotions
                .AnyAsync(up => up.PromotionId == promotionId && up.UserId == user.Id);

            if (exists)
            {
                TempData["Info"] = "ℹ️ Người dùng này đã được gán mã này trước đó.";
                return RedirectToAction(nameof(Edit), new { id = promotionId });
            }

            // 🧩 5. Gán user cho promotion
            try
            {
                _context.UserPromotions.Add(new UserPromotion
                {
                    PromotionId = promotionId,
                    UserId = user.Id,
                    IsUsed = false,
                    DateSaved = DateTime.Now
                });
                await _context.SaveChangesAsync();

                TempData["Success"] = $"✅ Đã gán mã khuyến mãi cho người dùng: {user.Email}";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "❌ Đã xảy ra lỗi trong quá trình gán: " + ex.Message;
            }

            return RedirectToAction(nameof(Edit), new { id = promotionId });
        }

        [HttpGet]
        public async Task<IActionResult> SearchUsers(string term)
        {
            if (string.IsNullOrWhiteSpace(term))
                return Json(new List<object>());

            var users = await _context.Users
                .Where(u =>
                    u.Email.Contains(term) ||
                    u.FullName.Contains(term))
                .OrderBy(u => u.FullName)
                .Select(u => new
                {
                    id = u.Id,
                    fullName = u.FullName,
                    email = u.Email
                })
                .Take(10)
                .ToListAsync();

            return Json(users);
        }
    }
}
