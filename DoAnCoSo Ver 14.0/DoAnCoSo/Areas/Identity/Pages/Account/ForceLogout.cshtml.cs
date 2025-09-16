using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Threading.Tasks;

namespace DoAnCoSo.Areas.Identity.Pages.Account
{
    [IgnoreAntiforgeryToken] // bỏ CSRF để fetch từ JS
    public class ForceLogoutModel : PageModel
    {
        public async Task<IActionResult> OnPostAsync()
        {
            // Xóa cookie hiện tại → máy cũ logout ngay
            await HttpContext.SignOutAsync(IdentityConstants.ApplicationScheme);
            return new JsonResult(new { success = true });
        }
    }
}
