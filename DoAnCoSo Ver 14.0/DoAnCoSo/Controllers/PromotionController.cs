using DoAnCoSo.Models;
using Microsoft.AspNetCore.Mvc;

namespace DoAnCoSo.Controllers
{
    public class PromotionController : Controller
    {
        private readonly ApplicationDbContext _context;

        public PromotionController(ApplicationDbContext context)
        {
            _context = context;
        }

        // Danh sách khuyến mãi
        public IActionResult Index()
        {
            var promos = _context.Promotions.ToList();
            return View(promos);
        }

        // Chi tiết khuyến mãi
        public IActionResult Details(int id)
        {
            var promo = _context.Promotions.FirstOrDefault(p => p.Id == id);
            if (promo == null) return NotFound();
            return View(promo);
        }
    }

}
