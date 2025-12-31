using DoAnCoSo.Data;
using DoAnCoSo.Hubs;
using DoAnCoSo.Models;
using DoAnCoSo.Repositories;
using DoAnCoSo.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Localization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;


var builder = WebApplication.CreateBuilder(args);

// Cấu hình Culture cho ứng dụng

builder.Services.Configure<RequestLocalizationOptions>(options =>

{

    var supportedCultures = new[] { new CultureInfo("vi-VN"), new CultureInfo("en-US") /* Thêm các culture khác nếu cần */ };

    options.DefaultRequestCulture = new RequestCulture("vi-VN"); // Đặt culture mặc định là tiếng Việt

    options.SupportedCultures = supportedCultures;

    options.SupportedUICultures = supportedCultures;

});

builder.Services.AddDbContext<ApplicationDbContext>(options =>
options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
//options.UseMySql(
//    builder.Configuration.GetConnectionString("DefaultConnection"),
//    new MySqlServerVersion(new Version(8, 0, 36))
//));

// Đặt trước AddControllersWithViews();
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
 .AddDefaultTokenProviders()
 .AddDefaultUI()
 .AddEntityFrameworkStores<ApplicationDbContext>();
builder.Services.AddRazorPages();
// ================= JWT AUTH =================

builder.Services.AddAuthentication()
    .AddCookie() // cho Web
    .AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"])
            )
        };
    });

//hien thi thong bao quyen han truy cap admin 
builder.Services.ConfigureApplicationCookie(options =>
{
    options.LoginPath = "/Identity/Account/Login";
    options.LogoutPath = "/Identity/Account/Logout";
    options.AccessDeniedPath = "/Identity/Account/AccessDenied";
});

builder.Services.Configure<SecurityStampValidatorOptions>(options =>
{
    options.ValidationInterval = TimeSpan.Zero; // Kiểm tra mỗi request
});

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter",
        policy =>
        {
            policy.AllowAnyOrigin()
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        });
});

builder.Services.AddControllers();
// Add services to the container.
//builder.Services.AddControllersWithViews();

builder.Services.AddScoped<IProductRepository, EFProductRepository>();
builder.Services.AddScoped<ICategoryRepository, EFCategoryRepository>();

// Đăng ký CustomUserIdProvider cho SignalR
builder.Services.AddSingleton<IUserIdProvider, CustomUserIdProvider>();
builder.Services.AddSignalR();

builder.Services.AddScoped<IChatMessageRepository, ChatMessageRepository>();

// Đăng ký InventoryService     
builder.Services.AddScoped<IInventoryService, InventoryService>();

// Đăng ký CustomUserIdProvider cho SignalR
builder.Services.AddSingleton<IUserIdProvider, CustomUserIdProvider>();

// Bind EmailSettings từ appsettings.json
builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection("EmailSettings"));

// Đăng ký EmailService
builder.Services.AddScoped<EmailService>();

// ✅ Đăng ký BlockchainService
builder.Services.AddScoped<BlockchainService>();

builder.Services.AddSingleton<GeminiVisionService>();

builder.Services.AddScoped<IProductApiService, ProductApiService>();


var app = builder.Build();

var supportedCultures = new[] { new CultureInfo("vi-VN"), new CultureInfo("en-US") };
app.UseRequestLocalization(new RequestLocalizationOptions
{
    DefaultRequestCulture = new RequestCulture("vi-VN"),
    SupportedCultures = supportedCultures,
    SupportedUICultures = supportedCultures
});

// SEED DATA 
using (var scope = app.Services.CreateScope()) // Tạo một scope dịch vụ để có thể truy cập các dịch vụ đã đăng ký
{
    var serviceProvider = scope.ServiceProvider; // Lấy IServiceProvider từ scope
    try
    {
        await SeedData.Initialize(serviceProvider); // Gọi phương thức Initialize trong class SeedData để seed dữ liệu
    }
    catch (Exception ex)
    {
        var logger = serviceProvider.GetRequiredService<ILogger<Program>>(); // Lấy logger để ghi log lỗi
        logger.LogError(ex, "An error occurred seeding the DB."); // Ghi log nếu có lỗi xảy ra trong quá trình seed
    }
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseRouting();

app.UseCors("AllowFlutter");
// đặt useStaticFiles tại đây để có thể load ảnh 
app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();
app.UseSession();

app.MapControllers(); // bắt API

app.MapRazorPages();

// Route cho khu vực Admin
app.MapControllerRoute(
    name: "Admin",
    pattern: "{area:exists}/{controller=Revenue}/{action=Index}/{id?}");

// Route mặc định
app.MapControllerRoute(
        name: "default",
        pattern: "{controller=Home}/{action=Index}/{id?}");

// Route cho SignalR Hub
app.MapHub<ChatHub>("/chathub");

app.Run();