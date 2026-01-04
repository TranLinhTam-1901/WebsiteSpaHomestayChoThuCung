using DoAnCoSo.DTO.Product;
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Controllers.Api
{
    [ApiController]
    [Route("api/promotions")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
    public class PromotionsApiControllerUser : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public PromotionsApiControllerUser(
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
        }


        // GET /api/promotions
        // Danh sách khuyến mãi user được thấy
        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var now = DateTime.Now;


            var user = await _userManager.GetUserAsync(User);
            if (user == null) return Unauthorized();
            var userId = user.Id;


            var promotions = await _context.Promotions
            .AsNoTracking()
            .Where(p => p.IsActive && p.StartDate <= now && p.EndDate >= now)

        
            .Where(p => !p.IsPrivate
                || _context.UserPromotions.Any(up => up.UserId == userId && up.PromotionId == p.Id))


                .OrderByDescending(p => p.StartDate)
                .Select(p => new
                {
                    p.Id,
                    p.Title,
                    p.Code,
                    p.ShortDescription,
                    p.Description,
                    p.Discount,
                    p.IsPercent,
                    p.MinOrderValue,
                    p.StartDate,
                    p.EndDate,
                    p.Image,


                    p.MaxUsage,
                    p.MaxUsagePerUser,
                    p.IsPrivate,

                    //  user đã dùng bao nhiêu lần
                    UserUsedCount = _context.OrderPromotions.Count(op =>
                        op.PromotionId == p.Id && op.Order.UserId == userId),

                    // (tuỳ chọn) tổng lượt dùng toàn hệ thống (để disable nếu MaxUsage hết)
                    GlobalUsedCount = _context.OrderPromotions.Count(op => op.PromotionId == p.Id),
                })
                .ToListAsync();

            return Ok(promotions);
        }


        // GET /api/promotions/{id}
        // Chi tiết khuyến mãi
        [HttpGet("{id}")]
        public async Task<IActionResult> Details(int id)
        {
            var now = DateTime.Now;

            var promo = await _context.Promotions.FirstOrDefaultAsync(p => p.Id == id);
            if (promo == null)
                return NotFound(new { message = "Không tìm thấy khuyến mãi." });

            if (!promo.IsActive || promo.StartDate > now || promo.EndDate < now)
                return BadRequest(new { message = "Khuyến mãi không còn hiệu lực." });

            return Ok(new
            {
                promo.Id,
                promo.Title,
                promo.Code,
                promo.ShortDescription,
                promo.Description,
                promo.Discount,
                promo.IsPercent,
                promo.MinOrderValue,
                promo.MaxUsage,
                promo.MaxUsagePerUser,
                promo.StartDate,
                promo.EndDate,
                promo.Image
            });
        }


        // POST /api/promotions/{id}/apply
        // Áp mã – validate & preview cho Checkout
        [Authorize]
        [HttpPost("{id}/apply")]
        public async Task<IActionResult> Apply(int id)
        {
            var now = DateTime.Now;
            var user = await _userManager.GetUserAsync(User);
            if (user == null)
                return Unauthorized();

            var promo = await _context.Promotions.FindAsync(id);
            if (promo == null)
                return NotFound(new { message = "Không tìm thấy khuyến mãi." });

            if (!promo.IsActive || promo.StartDate > now || promo.EndDate < now)
                return BadRequest(new { message = "Khuyến mãi không còn hiệu lực." });

            // kiểm tra số lần user đã dùng (nếu có giới hạn)
            if (promo.MaxUsagePerUser.HasValue)
            {
                var usedCount = await _context.OrderPromotions
                    .CountAsync(op =>
                        op.PromotionId == promo.Id &&
                        op.Order.UserId == user.Id);

                if (usedCount >= promo.MaxUsagePerUser.Value)
                {
                    return BadRequest(new
                    {
                        message = "Bạn đã sử dụng mã này quá số lần cho phép."
                    });
                }
            }

            return Ok(new
            {
                promo.Id,
                promo.Code,
                promo.Discount,
                promo.IsPercent,
                promo.MinOrderValue,
                message = "Áp mã thành công"
            });
        }


        // GET /api/promotions/{id}/products
        // Apply cho trang khuyến mãi: lọc sản phẩm theo MinOrderValue (dựa trên giá bán thực tế)
        [HttpGet("{id:int}/products")]
        public async Task<IActionResult> GetProductsForPromotion(
            int id,
            [FromQuery] int? categoryId // optional: nếu tab product có filter category thì dùng luôn
        )
        {
            var now = DateTime.Now;

            // 1) Lấy promotion + check hiệu lực
            var promo = await _context.Promotions
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == id);

            if (promo == null)
                return NotFound(new { message = "Không tìm thấy khuyến mãi." });

            if (!promo.IsActive || promo.StartDate > now || promo.EndDate < now)
                return BadRequest(new { message = "Khuyến mãi không còn hiệu lực." });

            // 2) MinOrderValue: null/0 => không lọc
            var min = promo.MinOrderValue ?? 0;

            // 3) Query sản phẩm đang bán
            var query = _context.Products
                .AsNoTracking()
                .Where(p => p.IsActive && !p.IsDeleted);

            if (categoryId.HasValue && categoryId.Value > 0)
                query = query.Where(p => p.CategoryId == categoryId.Value);

            // 4) Lọc theo "giá bán thực tế": PriceReduced nếu > 0, ngược lại Price
            query = query.Where(p =>
                min <= 0 ||
                ((p.PriceReduced > 0 ? p.PriceReduced : p.Price) >= min)
            );

            // 5) Trả về DTO giống API list product của bạn
            var items = await query
                .Select(p => new ProductListDto
                {
                    Id = p.Id,
                    Name = p.Name,
                    Price = p.Price,
                    PriceReduced = p.PriceReduced,
                    DiscountPercentage = p.DiscountPercentage,
                    ImageUrl = p.ImageUrl ?? p.Images.Select(i => i.Url).FirstOrDefault(),
                    Trademark = p.Trademark,
                    HasVariants = p.Variants.Any(v => v.IsActive),
                    InStock = p.StockQuantity > 0
                })
                .ToListAsync();

            return Ok(new
            {
                promotion = new
                {
                    promo.Id,
                    promo.Title,
                    promo.Code,
                    promo.MinOrderValue
                },
                total = items.Count,
                items
            });
        }


    }
}
