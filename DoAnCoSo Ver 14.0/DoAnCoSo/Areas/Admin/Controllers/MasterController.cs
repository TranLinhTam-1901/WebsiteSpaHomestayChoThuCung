using DoAnCoSo.Models;
using DoAnCoSo.Repositories;
using DoAnCoSo.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin")]
    public class MasterController : Controller
    {
        private readonly IProductRepository _productRepository;
        private readonly ICategoryRepository _categoryRepository;
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public MasterController(
            IProductRepository productRepository,
            ICategoryRepository categoryRepository,
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager)
        {
            _productRepository = productRepository;
            _categoryRepository = categoryRepository;
            _context = context;
            _userManager = userManager;
        }

        public async Task<IActionResult> Index()
        {
            var categories = await _categoryRepository.GetAllAsync();
            var products = await _productRepository.GetAllAsync();

            // Lấy filter từ query string, chuyển về lower để so sánh
            string orderCustomerFilter = (Request.Query["customerName"].ToString() ?? "").ToLower();
            string orderProductFilter = (Request.Query["productName"].ToString() ?? "").ToLower();
            string orderStatusFilter = (Request.Query["orderStatus"].ToString() ?? "").ToLower();

            string userRoleFilter = (Request.Query["userRole"].ToString() ?? "").ToLower();

            string appointmentCustomerFilter = (Request.Query["appointmentCustomerName"].ToString() ?? "").ToLower();
            string appointmentStatusFilter = (Request.Query["appointmentStatus"].ToString() ?? "").ToLower();

            // Query đơn hàng
            var ordersQuery = _context.Orders
                .Include(o => o.User)
                .Include(o => o.OrderDetails)
                    .ThenInclude(od => od.Product)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(orderCustomerFilter))
            {
                ordersQuery = ordersQuery.Where(o => o.User != null && o.User.FullName.ToLower().Contains(orderCustomerFilter));
            }

            if (!string.IsNullOrWhiteSpace(orderProductFilter))
            {
                ordersQuery = ordersQuery.Where(o => o.OrderDetails.Any(od => od.Product != null && od.Product.Name.ToLower().Contains(orderProductFilter)));
            }

            if (!string.IsNullOrWhiteSpace(orderStatusFilter))
            {
                ordersQuery = ordersQuery.Where(o => o.Status.ToString().ToLower() == orderStatusFilter);
            }

            var orders = await ordersQuery.ToListAsync();

            // Query lịch hẹn
            var appointmentsQuery = _context.Appointments
                .Include(a => a.User)
                .Include(a => a.Pet)
                .Include(a => a.Service)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(appointmentCustomerFilter))
            {
                appointmentsQuery = appointmentsQuery.Where(a => a.User != null && a.User.FullName.ToLower().Contains(appointmentCustomerFilter));
            }

            if (!string.IsNullOrWhiteSpace(appointmentStatusFilter))
            {
                if (Enum.TryParse<AppointmentStatus>(appointmentStatusFilter, true, out var parsedStatus))
                {
                    appointmentsQuery = appointmentsQuery.Where(a => a.Status == parsedStatus);
                }
            }

            var filteredAppointments = await appointmentsQuery.ToListAsync();

            var pendingAppointments = filteredAppointments
                .Where(a => a.Status == AppointmentStatus.Pending)
                .ToList();

            var history = filteredAppointments
                .Where(a => a.Status != AppointmentStatus.Pending)
                .ToList();

            // Đếm trạng thái trên toàn bộ (ko phụ thuộc filter)
            var allAppointments = await _context.Appointments.ToListAsync();
            int pendingCount = allAppointments.Count(a => a.Status == AppointmentStatus.Pending);
            int processedCount = allAppointments.Count(a => a.Status != AppointmentStatus.Pending);

            // Query user theo role
            var usersQuery = _context.Users.AsQueryable();

            if (!string.IsNullOrWhiteSpace(userRoleFilter))
            {
                var usersInRole = await _userManager.GetUsersInRoleAsync(userRoleFilter);
                var userIds = usersInRole.Select(u => u.Id).ToList();
                usersQuery = usersQuery.Where(u => userIds.Contains(u.Id));
            }

            var usersFromDb = await usersQuery.ToListAsync();

            var users = new List<UserInfoViewModel>();
            foreach (var u in usersFromDb)
            {
                var roles = await _userManager.GetRolesAsync(u);
                users.Add(new UserInfoViewModel
                {
                    Id = u.Id,
                    FullName = u.FullName,
                    UserName = u.UserName,
                    Email = u.Email,
                    Role = string.Join(", ", roles)
                });
            }

            var model = new MasterViewModel
            {
                Categories = categories,
                Products = products,
                Orders = orders,
                PendingAppointments = pendingAppointments,
                AppointmentHistory = history,
                Users = users,
                PendingAppointmentsCount = pendingCount,
                ProcessedAppointmentsCount = processedCount,
                AppointmentStatusFilter = appointmentStatusFilter
            };

            return View(model);
        }
    }
}