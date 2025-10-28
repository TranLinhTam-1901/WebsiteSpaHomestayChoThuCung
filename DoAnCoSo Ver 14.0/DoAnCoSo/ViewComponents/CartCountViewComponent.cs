
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Identity; // Đảm bảo bạn có model ShoppingCart
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
public class CartCountViewComponent : ViewComponent
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;

    public CartCountViewComponent(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
    {
        _context = context;
        _userManager = userManager;
    }

    public async Task<IViewComponentResult> InvokeAsync()
    {
        int itemCount = 0;

        var user = await _userManager.GetUserAsync(User as System.Security.Claims.ClaimsPrincipal);

        if (user != null)
        {
            var userId = user.Id;

            itemCount = await _context.CartItems
                                      .Where(ci => ci.UserId == userId)
                                      .SumAsync(ci => ci.Quantity);
        }

        return View(itemCount);
    }
}