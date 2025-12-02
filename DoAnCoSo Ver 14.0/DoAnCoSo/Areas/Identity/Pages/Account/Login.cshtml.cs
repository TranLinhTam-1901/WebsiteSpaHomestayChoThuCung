// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.
#nullable disable

using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.SignalR;
using System.ComponentModel.DataAnnotations;

namespace DoAnCoSo.Areas.Identity.Pages.Account
{
    public class LoginModel : PageModel
    {
        private readonly SignInManager<ApplicationUser> _signInManager;
        private readonly ILogger<LoginModel> _logger;
        private readonly UserManager<ApplicationUser> _userManager;

        public LoginModel(SignInManager<ApplicationUser> signInManager,
                          UserManager<ApplicationUser> userManager,
                          ILogger<LoginModel> logger)
        {
            _signInManager = signInManager;
            _userManager = userManager;
            _logger = logger;
        }

        /// <summary>
        ///     This API supports the ASP.NET Core Identity default UI infrastructure and is not intended to be used
        ///     directly from your code. This API may change or be removed in future releases.
        /// </summary>
        [BindProperty]
        public InputModel Input { get; set; }

        /// <summary>
        ///     This API supports the ASP.NET Core Identity default UI infrastructure and is not intended to be used
        ///     directly from your code. This API may change or be removed in future releases.
        /// </summary>
        public IList<AuthenticationScheme> ExternalLogins { get; set; }

        /// <summary>
        ///     This API supports the ASP.NET Core Identity default UI infrastructure and is not intended to be used
        ///     directly from your code. This API may change or be removed in future releases.
        /// </summary>
        public string ReturnUrl { get; set; }

        /// <summary>
        ///     This API supports the ASP.NET Core Identity default UI infrastructure and is not intended to be used
        ///     directly from your code. This API may change or be removed in future releases.
        /// </summary>
        [TempData]
        public string ErrorMessage { get; set; }

        /// <summary>
        ///     This API supports the ASP.NET Core Identity default UI infrastructure and is not intended to be used
        ///     directly from your code. This API may change or be removed in future releases.
        /// </summary>
        public class InputModel

        {
            /// <summary>
            ///     This API supports the ASP.NET Core Identity default UI infrastructure and is not intended to be used
            ///     directly from your code. This API may change or be removed in future releases.
            /// </summary>
            [Required]
            [EmailAddress]
            public string Email { get; set; }

            /// <summary>
            ///     This API supports the ASP.NET Core Identity default UI infrastructure and is not intended to be used
            ///     directly from your code. This API may change or be removed in future releases.
            /// </summary>
            [Required]
            [DataType(DataType.Password)]
            public string Password { get; set; }

            /// <summary>
            ///     This API supports the ASP.NET Core Identity default UI infrastructure and is not intended to be used
            ///     directly from your code. This API may change or be removed in future releases.
            /// </summary>
            [Display(Name = "Remember me?")]
            public bool RememberMe { get; set; }
        }

        public async Task OnGetAsync(string returnUrl = null)
        {
            if (!string.IsNullOrEmpty(ErrorMessage))
            {
                ModelState.AddModelError(string.Empty, ErrorMessage);
            }

            returnUrl ??= Url.Content("~/");

            // Clear the existing external cookie to ensure a clean login process
            await HttpContext.SignOutAsync(IdentityConstants.ExternalScheme);

            ExternalLogins = (await _signInManager.GetExternalAuthenticationSchemesAsync()).ToList();

            ReturnUrl = returnUrl;
        }

        public async Task<IActionResult> OnPostAsync(string returnUrl = null)
        {
            returnUrl ??= Url.Content("~/");

            if (!ModelState.IsValid)
            {
                return Page();
            }

            // 🔍 Tìm user theo Email
            var user = await _userManager.FindByEmailAsync(Input.Email);
            if (user == null)
            {
                // Không lộ thông tin user tồn tại hay không
                ModelState.AddModelError(string.Empty, "Tài khoản hoặc mật khẩu không đúng.");
                return Page();
            }

            // 🔐 Thực hiện đăng nhập
            var result = await _signInManager.PasswordSignInAsync(
                user.UserName,          // dùng UserName nội bộ
                Input.Password,
                Input.RememberMe,
                lockoutOnFailure: true  // cho phép tăng AccessFailedCount & lockout nếu sai nhiều
            );

            if (result.Succeeded)
            {
                // 🔹 Update SecurityStamp → tất cả session cũ invalid
                await _userManager.UpdateSecurityStampAsync(user);

                // 🔹 SignIn cho session mới
                await _signInManager.SignInAsync(user, isPersistent: Input.RememberMe);

                // 🔹 Gửi SignalR ForceLogout cho các session cũ
                var hubContext = HttpContext.RequestServices.GetRequiredService<IHubContext<ChatHub>>();
                await hubContext.Clients.User(user.Id).SendAsync("ForceLogout");

                _logger.LogInformation("User logged in.");

                if (await _userManager.IsInRoleAsync(user, "Admin"))
                {
                    return RedirectToAction("Index", "Revenue", new { area = "Admin" });
                }

                return LocalRedirect(returnUrl);
            }

            // ✅ Tài khoản bị khóa (do Admin đặt LockoutEnd rất xa hoặc do login sai nhiều lần)
            if (result.IsLockedOut)
            {
                ModelState.AddModelError(string.Empty, "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.");
                return Page(); // quay lại cùng trang Login, hiển thị message ở asp-validation-summary
            }

            if (result.RequiresTwoFactor)
            {
                return RedirectToPage("./LoginWith2fa", new { ReturnUrl = returnUrl, RememberMe = Input.RememberMe });
            }

            // Sai mật khẩu hoặc lỗi khác
            ModelState.AddModelError(string.Empty, "Tài khoản hoặc mật khẩu không đúng.");
            return Page();
        }

    }
}
