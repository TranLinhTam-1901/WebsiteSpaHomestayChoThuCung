using DoAnCoSo.DTO;
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

public class FavoriteController : Controller
{
    private readonly ApplicationDbContext _context;

    public FavoriteController(ApplicationDbContext context)
    {
        _context = context;
    }

    private const string FavoriteSessionKey = "FavoriteProductIds"; // Khóa session duy nhất cho yêu thích

    // GET: /Favorite/
    [Authorize]
    public IActionResult Index()
    {
        // Cast User to ClaimsPrincipal
        var userId = (User as ClaimsPrincipal)?.FindFirstValue(ClaimTypes.NameIdentifier);

        if (userId == null)
        {
            return RedirectToAction("Login", "Account");
        }

        var products = _context.Favorites
            .Where(f => f.UserId == userId)
            .Select(f => f.Product)
            .ToList();

        return View(products);
    }

    // POST: /Favorite/Toggle
    [Authorize]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Toggle([FromBody] FavoriteToggleRequest request)
    {
        // Cast User to ClaimsPrincipal
        var userId = (User as ClaimsPrincipal)?.FindFirstValue(ClaimTypes.NameIdentifier); // Lấy ID người dùng đang đăng nhập

        if (userId == null)
        {
            return Json(new { success = false, message = "User not logged in" });
        }

        var favorite = _context.Favorites
            .FirstOrDefault(f => f.UserId == userId && f.ProductId == request.Id);

        bool isFavorited;

        if (favorite != null)
        {
            _context.Favorites.Remove(favorite);
            isFavorited = false;
        }
        else
        {
            _context.Favorites.Add(new Favorite
            {
                UserId = userId,
                ProductId = request.Id
            });
            isFavorited = true;
        }

        _context.SaveChanges();

        var count = _context.Favorites.Count(f => f.UserId == userId);

        return Json(new
        {
            success = true,
            isFavorited = isFavorited,
            count = count
        });
    }

    [Authorize]
    [HttpGet]
    public IActionResult GetFavoriteStatus()
    {
        var userId = (User as ClaimsPrincipal)?.FindFirstValue(ClaimTypes.NameIdentifier);

        if (userId == null)
        {
            return Json(new { favoriteIds = new List<int>() });
        }

        var favorites = _context.Favorites
            .Where(f => f.UserId == userId)
            .Select(f => f.ProductId)
            .ToList();

        return Json(new { favoriteIds = favorites });
    }
}