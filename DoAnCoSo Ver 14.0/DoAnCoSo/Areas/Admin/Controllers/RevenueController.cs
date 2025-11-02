using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin")]
    public class RevenueController : Controller
    {
        private readonly ApplicationDbContext _context;

        public RevenueController(ApplicationDbContext context)
        {
            _context = context;
        }

        // ✅ Trang chính Dashboard
        public IActionResult Index()
        {
            return View();
        }

        // ✅ API 1: Tổng quan (Doanh thu, Đơn hàng, KM, KH mới)
        [HttpGet]
        public async Task<IActionResult> GetOverview()
        {
            var now = DateTime.Now;
            var startOfMonth = new DateTime(now.Year, now.Month, 1);
            var endOfMonth = startOfMonth.AddMonths(1);

            // ✅ Tính doanh thu thật
            var monthlyRevenue = await _context.Orders
                .Where(o => o.OrderDate >= startOfMonth
                         && o.OrderDate < endOfMonth
                         && o.Status == OrderStatusEnum.DaXacNhan
                         && o.bankStatus == BankStatusEnum.DaThanhToan)
                .SumAsync(o => (decimal?)o.TotalPrice) ?? 0;

            // ✅ Tính tổng đơn hàng hợp lệ
            var totalOrders = await _context.Orders
                .CountAsync(o => o.OrderDate >= startOfMonth
                              && o.OrderDate < endOfMonth
                              && o.Status == OrderStatusEnum.DaXacNhan);

            // Tổng khuyến mãi đã áp dụng
            var totalDiscount = await _context.OrderPromotions
            .Where(op => op.Order.OrderDate >= startOfMonth
              && op.Order.OrderDate < endOfMonth
              && op.Order.Status == OrderStatusEnum.DaXacNhan
              && op.Order.bankStatus == BankStatusEnum.DaThanhToan)
            .SumAsync(op => (decimal?)op.DiscountApplied) ?? 0;


            // Khách hàng mới
            // ✅ Lấy role "Customer"
            var customerRoleId = await _context.Roles
                .Where(r => r.Name == "Customer")
                .Select(r => r.Id)
                .FirstOrDefaultAsync();

            // ✅ Đếm số khách hàng mới trong tháng (chỉ role Customer)
            var newCustomers = await _context.Users
                .Where(u => u.CreatedAt >= startOfMonth
                         && u.CreatedAt < endOfMonth
                         && _context.UserRoles.Any(ur => ur.UserId == u.Id && ur.RoleId == customerRoleId))
                .CountAsync();


            return Json(new
            {
                monthlyRevenue,
                totalOrders,
                totalDiscount,
                newCustomers
            });
        }

        // ✅ API 2: Doanh thu theo thời gian (tuần / tháng / năm)
        [HttpGet]
        public async Task<IActionResult> GetRevenue(string range = "month")
        {
            DateTime startDate, endDate = DateTime.Now;

            if (range == "week")
                startDate = DateTime.Now.AddDays(-7);
            else if (range == "month")
                startDate = new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1);
            else
                startDate = new DateTime(DateTime.Now.Year, 1, 1);

            var query = _context.Orders
            .Where(o => o.OrderDate >= startDate
                && o.OrderDate <= endDate
                && o.Status == OrderStatusEnum.DaXacNhan
                && o.bankStatus == BankStatusEnum.DaThanhToan);


            var data = new List<object>();

            if (range == "week")
            {
                // ⚡ Lấy toàn bộ đơn tuần này
                var orders = await query.ToListAsync();

                // Danh sách 7 ngày trong tuần (Thứ 2 -> Chủ nhật)
                var days = Enum.GetValues(typeof(DayOfWeek))
                               .Cast<DayOfWeek>()
                               .ToList();

                data = days.Select(d => new
                {
                    Label = d.ToString(), // Monday, Tuesday,...
                    Revenue = orders
                        .Where(o => o.OrderDate.DayOfWeek == d)
                        .Sum(o => o.TotalPrice)
                }).ToList<object>();
            }
            else if (range == "month")
            {
                var monthlyData = await query
                 .GroupBy(o => o.OrderDate.Day)
                 .Select(g => new
                 {
                     Day = g.Key,
                     Revenue = g.Sum(o => o.TotalPrice)
                 })
                 .ToListAsync();

                int totalDays = DateTime.DaysInMonth(DateTime.Now.Year, DateTime.Now.Month);

                data = Enumerable.Range(1, totalDays)
                    .Select(day => new
                    {
                        Label = "Ngày " + day,
                        Revenue = monthlyData.FirstOrDefault(x => x.Day == day)?.Revenue ?? 0
                    })
                    .ToList<object>();
            }
            else // year
            {
                var monthly = await query
                .GroupBy(o => o.OrderDate.Month)
                .Select(g => new
                {
                    Month = g.Key,
                    Revenue = g.Sum(o => o.TotalPrice)
                })
                .ToListAsync();

                data = Enumerable.Range(1, 12)
                    .Select(m => new
                    {
                        Label = "Tháng " + m,
                        Revenue = monthly.FirstOrDefault(x => x.Month == m)?.Revenue ?? 0
                    })
                    .ToList<object>();
            }
            return Json(data);
        }

        // ✅ API 3: Doanh thu theo danh mục
        [HttpGet]
        public async Task<IActionResult> GetRevenueByCategory()
        {
            var data = await _context.OrderDetails
                .Include(od => od.Order)
                .Include(od => od.Product)
                .ThenInclude(p => p.Category)
                .Where(od => od.Order.Status == OrderStatusEnum.DaXacNhan
                          && od.Order.bankStatus == BankStatusEnum.DaThanhToan)
                .GroupBy(od => od.Product.Category != null ? od.Product.Category.Name : "Chưa phân loại")
                .Select(g => new
                {
                    Category = g.Key,
                    Revenue = g.Sum(od => od.Quantity * od.Price)
                })
                .ToListAsync();

            return Json(data);
        }


        // ✅ API 4: Top sản phẩm bán chạy
        [HttpGet]
        public async Task<IActionResult> GetTopProducts()
        {
            var data = await _context.OrderDetails
                .AsNoTracking()
                .Include(od => od.Order)
                .Include(od => od.Product)
                .ThenInclude(p => p.Category)
                .Where(od => od.Order.Status == OrderStatusEnum.DaXacNhan
                          && od.Order.bankStatus == BankStatusEnum.DaThanhToan)
                .GroupBy(od => new
                {
                    ProductId = od.ProductId,
                    ProductName = od.Product.Name,
                    CategoryName = od.Product.Category != null ? od.Product.Category.Name : "Chưa phân loại"
                })
                .Select(g => new
                {
                    g.Key.ProductId,
                    ProductName = g.Key.ProductName,
                    CategoryName = g.Key.CategoryName,
                    Quantity = g.Sum(od => od.Quantity),
                    Revenue = g.Sum(od => od.Quantity * od.Price)
                })
                .OrderByDescending(x => x.Revenue)
                .Take(5)
                .ToListAsync();

            return Json(data);
        }

    }
}
