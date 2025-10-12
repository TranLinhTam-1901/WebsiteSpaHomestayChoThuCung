using Microsoft.AspNetCore.Mvc;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    public class PetController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
