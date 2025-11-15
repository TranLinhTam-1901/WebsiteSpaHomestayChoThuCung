
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Mvc;


namespace DoAnCoSo.Controllers
{
    public class ServiceController : Controller
    {
        private readonly ApplicationDbContext _context;

        public ServiceController(ApplicationDbContext context)
        {
            _context = context;
        }

        public IActionResult Spa()
        {
            var spaServices = _context.Services
                .Where(s => s.Category == ServiceCategory.Spa)
                .ToList();
            return View(spaServices);
        }

        public IActionResult LuuTru()
        {
            var luuTruServices = _context.Services
                .Where(s => s.Category == ServiceCategory.Homestay)
                .ToList();
            return View(luuTruServices);
        }
    }
}
