using DoAnCoSo.DTO.Auth;
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

[ApiController]
[Route("api/users")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public class UserApiController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;

    public UserApiController(UserManager<ApplicationUser> userManager)
    {
        _userManager = userManager;
    }

    // GET api/users/me
    [HttpGet("me")]
    public async Task<IActionResult> GetMyProfile()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
            return NotFound();

        var roles = await _userManager.GetRolesAsync(user);

        return Ok(new
        {
            id = user.Id,
            fullName = user.FullName,
            email = user.Email,
            phone = user.PhoneNumber,
            address = user.Address,
            role = roles.FirstOrDefault()
        });
    }

    // PUT api/users/me
    [HttpPut("me")]
    public async Task<IActionResult> UpdateMyProfile([FromBody] UpdateProfileDto dto)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
            return NotFound();

        if (string.IsNullOrWhiteSpace(dto.Phone))
            return BadRequest("Số điện thoại không hợp lệ");

        if (string.IsNullOrWhiteSpace(dto.Address))
            return BadRequest("Địa chỉ không được để trống");

        user.FullName = dto.FullName;
        user.PhoneNumber = dto.Phone;
        user.Address = dto.Address;

        await _userManager.UpdateAsync(user);

        return Ok(new
        {
            success = true,
            message = "Cập nhật thông tin thành công"
        });
    }

}
