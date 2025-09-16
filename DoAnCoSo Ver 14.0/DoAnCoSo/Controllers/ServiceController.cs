
using Microsoft.AspNetCore.Mvc;
using DoAnCoSo.Models;
using System.Linq;
using Microsoft.EntityFrameworkCore;


namespace DoAnCoSo.Controllers
{
    public class ServiceController : Controller
    {
        private readonly ApplicationDbContext _context;

        public ServiceController(ApplicationDbContext context)
        {
            _context = context;
        }

        // Hiển thị danh sách dịch vụ Spa
        public IActionResult Spa()
        {
            var spaServices = _context.Services.Where(s => s.Name.Contains("Spa")).ToList();
            return View(spaServices);
        }

        // Hiển thị danh sách dịch vụ Lưu trú
        public IActionResult LuuTru()
        {
            var luuTruServices = _context.Services.Where(s => s.Name.Contains("Lưu trú")).ToList();
            return View(luuTruServices);
        }

       
    }
}
