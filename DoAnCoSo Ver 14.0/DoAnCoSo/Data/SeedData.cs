using DoAnCoSo.Helpers;
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

                var adminUser1 = await userManager.FindByEmailAsync("Admin1@gmail.com"); // Thay bằng email admin bạn muốn
                if (adminUser1 == null)
                {
                    Console.WriteLine("Tài khoản Admin không tìm thấy, đang tạo..."); // Thông báo nếu user chưa tồn tại
                    adminUser1 = new ApplicationUser
                    {
                        UserName = "Admin1@gmail.com",
                        Email = "Admin1@gmail.com",
                        FullName = "Admin1",
                        Address = "System 1",
                        PhoneNumber = "0987654321"
                    };

                    // Tạo user với mật khẩu
                    var password = "Admin1@gmail.com";
                    Console.WriteLine($"Đang cố gắng tạo tài khoản Admin với email: {adminUser1.Email} và username: {adminUser1.UserName}");
                    var result = await userManager.CreateAsync(adminUser1, password);

                    if (result.Succeeded)
                    {
                        // ✅ Tạo cặp khóa RSA cho admin
                        var (pub, priv) = EncryptionHelper.GenerateRsaKeyPair();
                        adminUser1.PublicKey = pub;
                        adminUser1.PrivateKey = priv;
                        await userManager.UpdateAsync(adminUser1);
                        Console.WriteLine($"Đã tạo RSA key cho {adminUser1.Email}");

                        Console.WriteLine("Tài khoản Admin1 đã được tạo thành công.");
                        await userManager.AddToRoleAsync(adminUser1, SD.Role_Admin);
                        Console.WriteLine("Đã thêm tài khoản Admin2 vào vai trò Admin.");
                    }
                    else
                    {
                        Console.WriteLine("Lỗi khi tạo tài khoản Admin1:");
                        foreach (var error in result.Errors)
                        {
                            Console.WriteLine($"Lỗi: {error.Description}");
                        }
                    }
                }
                else
                {
                    Console.WriteLine("Tài khoản Admin đã tồn tại.");
                }

                // 🔹 Tạo thêm tài khoản Admin2 nếu chưa tồn tại
                //var adminUser2 = await userManager.FindByEmailAsync("Admin2@gmail.com");
                //if (adminUser2 == null)
                //{
                //    Console.WriteLine("Tài khoản Admin2 không tìm thấy, đang tạo...");
                //    adminUser2 = new ApplicationUser
                //    {
                //        UserName = "Admin2@gmail.com",
                //        Email = "Admin2@gmail.com",
                //        FullName = "Admin2",
                //        Address = "System 2",
                //        PhoneNumber = "0987654322"
                //    };

                //    var password2 = "Admin2@gmail.com";
                //    var result2 = await userManager.CreateAsync(adminUser2, password2);

                //    if (result2.Succeeded)
                //    {
                //        // ✅ Tạo cặp khóa RSA cho admin
                //        var (pub, priv) = EncryptionHelper.GenerateRsaKeyPair();
                //        adminUser2.PublicKey = pub;
                //        adminUser2.PrivateKey = priv;
                //        await userManager.UpdateAsync(adminUser2);
                //        Console.WriteLine($"Đã tạo RSA key cho {adminUser2.Email}");

                //        Console.WriteLine("Tài khoản Admin2 đã được tạo thành công.");
                //        await userManager.AddToRoleAsync(adminUser2, SD.Role_Admin);
                //        Console.WriteLine("Đã thêm tài khoản Admin2 vào vai trò Admin.");
                //    }
                //    else
                //    {
                //        Console.WriteLine("Lỗi khi tạo tài khoản Admin2:");
                //        foreach (var error in result2.Errors)
                //        {
                //            Console.WriteLine($"Lỗi: {error.Description}");
                //        }
                //    }
                //}
                //else
                //{
                //    Console.WriteLine("Tài khoản Admin2 đã tồn tại.");
                //}

                if (!context.SystemStates.Any())
                {
                    context.SystemStates.Add(new SystemState { CurrentAdminIndex = 0 });
                    context.SaveChanges();
                }
            }
            Console.WriteLine("Phương thức SeedData.Initialize() kết thúc.");
        }
    }
}