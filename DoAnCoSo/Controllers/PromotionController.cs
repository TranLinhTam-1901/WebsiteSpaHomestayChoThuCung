using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Controllers
{
    public class PromotionController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public PromotionController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        // Danh sách khuyến mãi
        public async Task<IActionResult> Index()
        {
            var user = await _userManager.GetUserAsync(User);
            var now = DateTime.Now;

            // 🧩 Bước 1: Tạo query khuyến mãi đang hoạt động và trong thời gian hợp lệ
            var query = _context.Promotions
                .Where(p => p.IsActive && p.EndDate >= now && p.StartDate <= now);

            // 🧩 Bước 2: Nếu user đã đăng nhập
            if (user != null)
            {
                // Lấy danh sách ID các mã private mà user này được gán
                var assignedPrivateIds = await _context.UserPromotions
                    .Where(up => up.UserId == user.Id)
                    .Select(up => up.PromotionId)
                    .ToListAsync();

                // Chỉ hiển thị mã public + private được gán
                query = query.Where(p => !p.IsPrivate || assignedPrivateIds.Contains(p.Id));

                // Lưu danh sách mã đã lưu (nếu có)
                ViewBag.SavedPromotionIds = assignedPrivateIds;
            }
            else
            {
                // 🧩 Nếu chưa đăng nhập -> chỉ hiển thị mã public
                query = query.Where(p => !p.IsPrivate);
                ViewBag.SavedPromotionIds = new List<int>();
            }

            // 🧩 Bước 3: Trả về danh sách khuyến mãi
            var promotions = await query.OrderByDescending(p => p.StartDate).ToListAsync();
            return View(promotions);
        }


        // Chi tiết khuyến mãi
        public async Task<IActionResult> Details(int id)
        {
            var promo = await _context.Promotions.FindAsync(id);
            if (promo == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy mã khuyến mãi.";
                return RedirectToAction("Index");
            }

            var user = await _userManager.GetUserAsync(User);
            bool alreadySaved = false;

            if (user != null)
            {
                alreadySaved = await _context.UserPromotions
                    .AnyAsync(up => up.PromotionId == id && up.UserId == user.Id);
            }

            ViewBag.AlreadySaved = alreadySaved;
            return View(promo);
        }


        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SavePromotion(int promotionId)
        {
            var user = await _userManager.GetUserAsync(User);
            if (user == null)
            {
                TempData["ErrorMessage"] = "Vui lòng đăng nhập để lưu mã khuyến mãi.";
                return RedirectToPage("/Account/Login", new { area = "Identity" });
            }

            var promo = await _context.Promotions.FindAsync(promotionId);
            if (promo == null || !promo.IsActive || promo.EndDate < DateTime.Now)
            {
                TempData["ErrorMessage"] = "Mã khuyến mãi không hợp lệ hoặc đã hết hạn.";
                return RedirectToAction("Index");
            }

            // Kiểm tra user đã lưu mã này chưa
            bool alreadySaved = _context.UserPromotions
                .Any(up => up.UserId == user.Id && up.PromotionId == promotionId);

            if (alreadySaved)
            {
                TempData["InfoMessage"] = "Bạn đã lưu mã này trước đó.";
                return RedirectToAction("Details", new { id = promotionId });
            }

            // Tạo bản ghi mới
            var userPromo = new UserPromotion
            {
                UserId = user.Id,
                PromotionId = promotionId,
                DateSaved = DateTime.Now
            };

            _context.UserPromotions.Add(userPromo);
            await _context.SaveChangesAsync();

            TempData["SuccessMessage"] = "🎉 Mã khuyến mãi đã được lưu vào tài khoản của bạn!";
            return RedirectToAction("Details", new { id = promotionId });
        }

        [HttpGet]
        public async Task<IActionResult> MyPromotions()
        {
            var user = await _userManager.GetUserAsync(User);
            if (user == null)
            {
                TempData["ErrorMessage"] = "Bạn cần đăng nhập để xem khuyến mãi.";
                return RedirectToPage("/Account/Login", new { area = "Identity" });
            }

            // Lấy danh sách mã mà user đã lưu
            var myPromos = await _context.UserPromotions
                .Where(up => up.UserId == user.Id)
                .Include(up => up.Promotion)
                .Select(up => new
                {
                    Id = up.Promotion.Id, // ✅ cần dòng này để View nhận ra promo.Id
                    Title = up.Promotion.Title,
                    Code = up.Promotion.Code,
                    Discount = up.Promotion.Discount,
                    IsPercent = up.Promotion.IsPercent,
                    StartDate = up.Promotion.StartDate,
                    EndDate = up.Promotion.EndDate,
                    IsUsed = up.IsUsed,
                    DateSaved = up.DateSaved,
                    UsedAt = up.UsedAt
                })
                .OrderByDescending(up => up.DateSaved)
                .ToListAsync();

            return View(myPromos);
        }

        [Authorize]
        [HttpGet]
        public async Task<IActionResult> Apply(int id)
        {
            var user = await _userManager.GetUserAsync(User);
            if (user == null)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            var promo = await _context.Promotions.FindAsync(id);
            if (promo == null)
            {
                TempData["Error"] = "❌ Không tìm thấy mã khuyến mãi.";
                return RedirectToAction(nameof(Index));
            }

            // 🔒 Kiểm tra điều kiện hợp lệ
            if (!promo.IsActive || promo.EndDate < DateTime.Now || promo.StartDate > DateTime.Now)
            {
                TempData["Error"] = "⚠️ Mã khuyến mãi này đã hết hạn hoặc chưa bắt đầu.";
                return RedirectToAction(nameof(MyPromotions));
            }

            // 🔐 Nếu là mã private → kiểm tra user có được gán không
            if (promo.IsPrivate)
            {
                bool allowed = await _context.UserPromotions
                    .AnyAsync(up => up.PromotionId == promo.Id && up.UserId == user.Id);

                if (!allowed)
                {
                    TempData["Error"] = "🚫 Mã này không được gán cho bạn.";
                    return RedirectToAction(nameof(MyPromotions));
                }
            }

            // ✅ Nếu hợp lệ → Chuyển tới trang sản phẩm, truyền mã
            return RedirectToAction("AllProducts", "Product", new { promoCode = promo.Code });
        }


        [HttpPost]
        [Authorize]
        public async Task<IActionResult> RemoveSavedPromotion(int promotionId)
        {
            var user = await _userManager.GetUserAsync(User);
            if (user == null)
                return RedirectToPage("/Account/Login", new { area = "Identity" });

            var saved = await _context.UserPromotions
                .FirstOrDefaultAsync(up => up.UserId == user.Id && up.PromotionId == promotionId);

            if (saved != null)
            {
                _context.UserPromotions.Remove(saved);
                await _context.SaveChangesAsync();
                TempData["Success"] = "🗑 Đã xóa mã khuyến mãi khỏi danh sách của bạn.";
            }
            else
            {
                TempData["Error"] = "❌ Không tìm thấy mã khuyến mãi cần xóa.";
            }

            return RedirectToAction(nameof(MyPromotions));
        }

    }

}
