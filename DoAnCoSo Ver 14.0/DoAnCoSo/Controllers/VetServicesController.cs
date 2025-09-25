using DoAnCoSo.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Controllers
{
    public class VetServicesController : Controller
    {
        private readonly ApplicationDbContext _context;

        public VetServicesController(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            var vetServices = await _context.Services
                .Where(s => s.Category == ServiceCategory.Vet)
                .Include(s => s.ServiceDetails) // load các dịch vụ con
                .ToListAsync();

            return View(vetServices);
        }
    }
}