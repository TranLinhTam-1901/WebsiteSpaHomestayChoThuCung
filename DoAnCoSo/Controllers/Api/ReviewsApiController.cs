using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace DoAnCoSo.Controllers.Api
{
    [ApiController]
    [Route("api")]
    public class ReviewsApiController : ControllerBase 
    {
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _env;

        public ReviewsApiController(ApplicationDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        [HttpGet("products/{productId}/reviews")]
        public async Task<IActionResult> GetProductReviews(int productId)
        {
            var reviews = await _context.Reviews
                .Where(r =>
                    r.TargetType == ReviewTargetType.Product &&
                    r.TargetId == productId)
                .Include(r => r.User)
                .Include(r => r.Images)
                .OrderByDescending(r => r.CreatedDate)
                .ToListAsync();

            var averageRating = reviews.Any()
                ? Math.Round(reviews.Average(r => r.Rating), 2)
                : 0;

            return Ok(new
            {
                averageRating,
                totalReviews = reviews.Count,
                reviews = reviews.Select(r => new
                {
                    id = r.Id,
                    rating = r.Rating,
                    comment = r.Comment,
                    createdDate = r.CreatedDate,
                    userName = r.User?.FullName ?? "Ẩn danh",
                    images = r.Images.Select(i => i.ImageUrl)
                })
            });
        }

        
        [HttpPost("reviews")]
        [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]

        public async Task<IActionResult> AddReviewApi(
        [FromForm] int targetId,
        [FromForm] int rating,
        [FromForm] string? comment,
        [FromForm] List<IFormFile>? reviewImages)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var review = new Review
            {
                UserId = userId,
                TargetId = targetId,
                TargetType = ReviewTargetType.Product,
                Rating = rating,
                Comment = comment,
                CreatedDate = DateTime.Now,
                Images = new List<ReviewImage>()
            };

            if (reviewImages != null && reviewImages.Any())
            {
                var uploadDir = Path.Combine(_env.WebRootPath, "images", "reviews");
                if (!Directory.Exists(uploadDir))
                    Directory.CreateDirectory(uploadDir);

                foreach (var file in reviewImages.Where(f => f.Length > 0))
                {
                    var fileName = $"{Guid.NewGuid()}_{file.FileName}";
                    var filePath = Path.Combine(uploadDir, fileName);

                    using var fs = new FileStream(filePath, FileMode.Create);
                    await file.CopyToAsync(fs);

                    review.Images.Add(new ReviewImage
                    {
                        ImageUrl = $"/images/reviews/{fileName}"
                    });
                }
            }

            _context.Reviews.Add(review);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã gửi đánh giá" });
        }

    }
}
