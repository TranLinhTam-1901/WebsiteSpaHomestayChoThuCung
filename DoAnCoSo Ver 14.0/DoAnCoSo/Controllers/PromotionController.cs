using DoAnCoSo.Models;
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

            // Lấy tất cả khuyến mãi đang hoạt động
            var promotions = await _context.Promotions
                .Where(p => p.IsActive && p.EndDate >= DateTime.Now)
                .OrderByDescending(p => p.StartDate)
                .ToListAsync();

            // Nếu user đăng nhập -> lấy danh sách mã đã lưu
            if (user != null)
            {
                var savedIds = await _context.UserPromotions
                    .Where(up => up.UserId == user.Id)
                    .Select(up => up.PromotionId)
                    .ToListAsync();

                ViewBag.SavedPromotionIds = savedIds;
            }
            else
            {
                ViewBag.SavedPromotionIds = new List<int>();
            }

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
                    up.Promotion.Title,
                    up.Promotion.Code,
                    up.Promotion.Discount,
                    up.Promotion.IsPercent,
                    up.Promotion.StartDate,
                    up.Promotion.EndDate,
                    up.IsUsed,
                    up.DateSaved,
                    up.UsedAt
                })
                .OrderByDescending(up => up.DateSaved)
                .ToListAsync();

            return View(myPromos);
        }

    }

}
