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
        [HttpPost]
        public async Task<IActionResult> Translate([FromBody] TranslateRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.Text))
                return BadRequest("Empty text");

            var result = await _vision.TranslateAsync(req.Text);
            return Content(result, "application/json");
        }

        public class TranslateRequest
        {
            public string Text { get; set; }
        }

    }
}
