using DoAnCoSo.Services;
using Microsoft.AspNetCore.Mvc;

namespace DoAnCoSo.Controllers
{
    public class AIController : Controller
    {
        private readonly GeminiVisionService _vision;

        public AIController(GeminiVisionService vision)
        {
            _vision = vision;
        }

        [HttpPost]
        public async Task<IActionResult> Analyze(IFormFile image)
        {
            if (image == null)
                return BadRequest("No image uploaded");

            var result = await _vision.AnalyzeImageAsync(image);

            return Content(result, "application/json");
        }
    }
}
