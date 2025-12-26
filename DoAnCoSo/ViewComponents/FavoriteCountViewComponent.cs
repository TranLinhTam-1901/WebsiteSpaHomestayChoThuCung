using DoAnCoSo.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

public class FavoriteCountViewComponent : ViewComponent
{
    private readonly ApplicationDbContext _context;

    public FavoriteCountViewComponent(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IViewComponentResult> InvokeAsync()
    {
        var user = User as ClaimsPrincipal;
        var userId = user?.FindFirstValue(ClaimTypes.NameIdentifier);

        int favoriteCount = 0;

        if (!string.IsNullOrEmpty(userId))
        {
            favoriteCount = await _context.Favorites
                .Where(f => f.UserId == userId
                            && f.Product != null
                            && f.Product.IsActive)   // ✅ chỉ đếm sản phẩm còn hoạt động
                .CountAsync();
        }

        return View(favoriteCount);
    }

}