using DoAnCoSo.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Data
{
    public static class SeedData
    {
        public static async Task Initialize(IServiceProvider serviceProvider)
        {
            Console.WriteLine("Phương thức SeedData.Initialize() bắt đầu."); // Kiểm tra xem phương thức có được gọi không
            using (var context = new ApplicationDbContext(
                serviceProvider.GetRequiredService<DbContextOptions<ApplicationDbContext>>()))
            {
                var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();
                var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();

                Console.WriteLine("Kiểm tra xem vai trò Admin có tồn tại không..."); // Kiểm tra trước khi kiểm tra vai trò
                // Tạo vai trò Admin nếu chưa tồn tại
                if (!await roleManager.RoleExistsAsync(SD.Role_Admin))
                {
                    Console.WriteLine("Vai trò Admin không tồn tại, đang tạo..."); // Thông báo nếu vai trò chưa tồn tại
                    await roleManager.CreateAsync(new IdentityRole(SD.Role_Admin));
                    Console.WriteLine("Vai trò Admin đã được tạo thành công."); // Thông báo khi vai trò được tạo
                }
                else
                {
                    Console.WriteLine("Vai trò Admin đã tồn tại."); // Thông báo nếu vai trò đã tồn tại
                }

                Console.WriteLine("Kiểm tra xem tài khoản Admin có tồn tại không..."); // Kiểm tra trước khi kiểm tra user
                // Tạo tài khoản Admin nếu chưa tồn tại
                var adminUser = await userManager.FindByEmailAsync("Admin1@gmail.com"); // Thay bằng email admin bạn muốn
                if (adminUser == null)
                {
                    Console.WriteLine("Tài khoản Admin không tìm thấy, đang tạo..."); // Thông báo nếu user chưa tồn tại
                    adminUser = new ApplicationUser
                    {
                        UserName = "Admin1@gmail.com",
                        Email = "Admin1@gmail.com",
                        FullName = "Admin", // Tên đầy đủ của admin (tùy chọn)
                     
                       
                        //Age = 18 , 
                        Address = "Địa chỉ mặc định của Admin", 
                        PhoneNumber = "0123456789" 
                    };

                    // Tạo user với mật khẩu
                    var password = "Admin1@gmail.com"; // **Quan trọng: Sử dụng mật khẩu mạnh và an toàn**
                    Console.WriteLine($"Đang cố gắng tạo tài khoản Admin với email: {adminUser.Email} và username: {adminUser.UserName}"); // Thông báo trước khi tạo user
                    var result = await userManager.CreateAsync(adminUser, password);

                    if (result.Succeeded)
                    {
                        Console.WriteLine("Tài khoản Admin đã được tạo thành công."); // Thông báo khi tạo user thành công
                        // Gán vai trò Admin cho user vừa tạo
                        Console.WriteLine($"Đang thêm tài khoản Admin {adminUser.Email} vào vai trò {SD.Role_Admin}..."); // Thông báo trước khi gán vai trò
                        await userManager.AddToRoleAsync(adminUser, SD.Role_Admin);
                        Console.WriteLine($"Đã thêm tài khoản Admin {adminUser.Email} vào vai trò {SD.Role_Admin} thành công."); // Thông báo khi gán vai trò thành công
                    }
                    else
                    {
                        Console.WriteLine("Lỗi khi tạo tài khoản Admin:"); // Thông báo nếu tạo user thất bại
                        // Ghi log lỗi nếu tạo user không thành công
                        foreach (var error in result.Errors)
                        {
                            Console.WriteLine($"Lỗi: {error.Description}");
                        }
                    }
                }
                else
                {
                    Console.WriteLine("Tài khoản Admin đã tồn tại."); // Thông báo nếu user đã tồn tại
                }
            }
            Console.WriteLine("Phương thức SeedData.Initialize() kết thúc."); // Kiểm tra khi phương thức kết thúc
        }
    }
}