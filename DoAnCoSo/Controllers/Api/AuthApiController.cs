using DoAnCoSo.DTO.Auth;
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace DoAnCoSo.Controllers.Api
{
    [ApiController]
    [Route("api/auth")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
    public class AuthApiController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly SignInManager<ApplicationUser> _signInManager;
        private readonly IConfiguration _configuration;
        private readonly RoleManager<IdentityRole> _roleManager;

        public AuthApiController(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        IConfiguration configuration,
        RoleManager<IdentityRole> roleManager)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _configuration = configuration;
            _roleManager = roleManager;
        }

        // ================= REGISTER =================
        [AllowAnonymous]
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequestDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            if (dto.Password != dto.ConfirmPassword)
                return BadRequest("Mật khẩu xác nhận không khớp");

            var existingUser = await _userManager.FindByEmailAsync(dto.Email);
            if (existingUser != null)
                return BadRequest("Email đã tồn tại");

            var user = new ApplicationUser
            {
                UserName = dto.Email,
                Email = dto.Email,
                FullName = dto.FullName,
                Address = dto.Address,
                PhoneNumber = dto.PhoneNumber
            };

            var result = await _userManager.CreateAsync(user, dto.Password);

            if (!result.Succeeded)
                return BadRequest(result.Errors);

            if (!await _roleManager.RoleExistsAsync("Customer"))
            {
                await _roleManager.CreateAsync(new IdentityRole("Customer"));
            }

            // 🔥 GÁN ROLE MẶC ĐỊNH
            await _userManager.AddToRoleAsync(user, "Customer");

            return Ok("Đăng ký thành công");
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<IActionResult> Login(LoginRequestDto dto)
        {
            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user == null)
                return Unauthorized("Sai email hoặc mật khẩu");

            var result = await _signInManager
                .CheckPasswordSignInAsync(user, dto.Password, false);

            if (!result.Succeeded)
                return Unauthorized("Sai email hoặc mật khẩu");



            // =========================
            // 1️⃣ LẤY ROLE CỦA USER
            // =========================
            var roles = await _userManager.GetRolesAsync(user);
            var role = roles.FirstOrDefault(); // Admin / User

            // =========================
            // 2️⃣ TẠO JWT
            // =========================
            var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id),
                    new Claim(ClaimTypes.Email, user.Email)
                };

            foreach (var r in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, r));
            }

            var key = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(_configuration["Jwt:Key"])
            );

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: DateTime.Now.AddDays(1),
                signingCredentials: new SigningCredentials(
                    key, SecurityAlgorithms.HmacSha256)
            );

            var tokenString = new JwtSecurityTokenHandler()
                .WriteToken(token);


            return Ok(new
            {
                token = tokenString,
                user = new {
                    id = user.Id,
                    email = user.Email,
                    role = role
                }

            });
        }


        [AllowAnonymous]
        [HttpPost("google-login")]
        public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginRequestDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            // =========================
            // 1️⃣ TÌM USER THEO EMAIL
            // =========================
            var user = await _userManager.FindByEmailAsync(dto.Email);

            // =========================
            // 2️⃣ NẾU USER CHƯA TỒN TẠI → TẠO MỚI
            // =========================
            if (user == null)
            {
                user = new ApplicationUser
                {
                    UserName = dto.Email,
                    Email = dto.Email,
                    FullName = dto.FullName,
                    LoginProvider = "Google",
                    IsExternalLogin = true,
                    PhoneNumber = "000000000",
                    ExternalProviderId = dto.FirebaseUid,
                    EmailConfirmed = true // Google email đã xác thực
                };

                var createResult = await _userManager.CreateAsync(user);

                if (!createResult.Succeeded)
                    return BadRequest(createResult.Errors);

                // 🔥 GÁN ROLE MẶC ĐỊNH
                if (!await _roleManager.RoleExistsAsync("Customer"))
                {
                    await _roleManager.CreateAsync(new IdentityRole("Customer"));
                }

                await _userManager.AddToRoleAsync(user, "Customer");
            }
            else
            {
                // =========================
                // 3️⃣ USER ĐÃ TỒN TẠI → CẬP NHẬT GOOGLE INFO (NẾU CHƯA CÓ)
                // =========================
                if (string.IsNullOrEmpty(user.ExternalProviderId))
                {
                    user.ExternalProviderId = dto.FirebaseUid;
                    user.LoginProvider = "Google";
                    user.IsExternalLogin = true;

                    await _userManager.UpdateAsync(user);
                }
            }

            // =========================
            // 4️⃣ LẤY ROLE
            // =========================
            var roles = await _userManager.GetRolesAsync(user);
            var role = roles.FirstOrDefault();

            // =========================
            // 5️⃣ TẠO JWT (DÙNG CHUNG LOGIC LOGIN THƯỜNG)
            // =========================
            var claims = new List<Claim>

                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id),
                    new Claim(ClaimTypes.Email, user.Email)
                };

            foreach (var r in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, r));
            }

            var key = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(_configuration["Jwt:Key"])
            );

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: DateTime.Now.AddDays(1),
                signingCredentials: new SigningCredentials(
                key, SecurityAlgorithms.HmacSha256)
            );

            var tokenString = new JwtSecurityTokenHandler().WriteToken(token);

            // =========================
            // 6️⃣ TRẢ RESPONSE
            // =========================
            return Ok(new
            {
                token = tokenString,
                user = new
                {
                    id = user.Id,
                    email = user.Email,
                    role = role
                }
            });
        }


    }
}
