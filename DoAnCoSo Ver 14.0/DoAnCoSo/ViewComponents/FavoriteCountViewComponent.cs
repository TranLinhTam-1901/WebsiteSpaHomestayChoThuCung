using DoAnCoSo.Models;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

public class FavoriteCountViewComponent : ViewComponent
{
    private readonly ApplicationDbContext _context;

    public FavoriteCountViewComponent(ApplicationDbContext context)
    {
        _context = context;
    }

    public IViewComponentResult Invoke()
    {
        var userId = (User as ClaimsPrincipal)?.FindFirstValue(ClaimTypes.NameIdentifier);

        int favoriteCount = 0;

        if (userId != null)
        {
            favoriteCount = _context.Favorites.Count(f => f.UserId == userId); // Lấy số lượng sản phẩm yêu thích của người dùng
        }

        return View(favoriteCount); // Trả về số lượng yêu thích cho View
    }
}