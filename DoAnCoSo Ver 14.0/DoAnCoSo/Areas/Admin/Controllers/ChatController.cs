using DoAnCoSo.Data;
using DoAnCoSo.Helpers;
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin")]
    public class ChatController : Controller
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ApplicationDbContext _context;

        public ChatController(UserManager<ApplicationUser> userManager, ApplicationDbContext context)
        {
            _userManager = userManager;
            _context = context;
        }

        public IActionResult Index()
        {
            var customers = _userManager.GetUsersInRoleAsync("customer").Result;
            return View(customers);
        }

        // ✅ Lấy lịch sử tin nhắn trong 1 cuộc trò chuyện
        [HttpGet]
        public IActionResult GetMessages(string customerId, int skip = 0, int take = 20)
        {
            var adminId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            var conversation = _context.Conversations
                .FirstOrDefault(c =>
                    (c.CustomerId == customerId && c.AdminId == adminId) ||
                    (c.CustomerId == adminId && c.AdminId == customerId));

            if (conversation == null) return Ok(new List<ChatMessage>());

            // Lấy tin nhắn mới → cũ để skip/take
            var messages = _context.ChatMessages
                .Where(m => m.ConversationId == conversation.Id)
                .OrderByDescending(m => m.SentAt)  // mới → cũ
                .Skip(skip)
                .Take(take)
                .Select(m => new {
                    fromUserId = m.SenderId,
                    message = EncryptionHelper.Decrypt(m.Message),
                    sentAt = m.SentAt
                })
                .ToList();

            // Đảo lại mảng để client append từ cũ → mới
            messages.Reverse();

            return Ok(messages);
        }

        [HttpGet]
        public async Task<IActionResult> GetCustomers()
        {
            var adminId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            var result = await _context.Conversations
                .Where(c => c.AdminId == adminId || c.CustomerId == adminId)
                .OrderByDescending(c => c.LastUpdated) // 👈 sort ngay từ DB
                .Select(c => new {
                    id = c.CustomerId == adminId ? c.AdminId : c.CustomerId,
                    fullName = c.CustomerId == adminId ? c.Admin.FullName : c.Customer.FullName,
                    unreadCount = _context.ChatMessages.Count(m => m.ConversationId == c.Id && !m.IsRead && m.SenderId != adminId),
                    lastUpdated = c.LastUpdated
                })
                .ToListAsync();

            return Ok(result);
        }

        // ✅ Đánh dấu tất cả tin nhắn của khách đã đọc
        [HttpPost]
        public async Task<IActionResult> MarkAsRead(string customerId)
        {
            var adminId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            var conv = await _context.Conversations
                .FirstOrDefaultAsync(c => (c.AdminId == adminId && c.CustomerId == customerId)
                                       || (c.AdminId == customerId && c.CustomerId == adminId));

            if (conv != null)
            {
                var unreadMessages = await _context.ChatMessages
                    .Where(m => m.ConversationId == conv.Id && m.SenderId != adminId && !m.IsRead)
                    .ToListAsync();

                foreach (var msg in unreadMessages)
                {
                    msg.IsRead = true;
                }

                await _context.SaveChangesAsync();
            }

            return Ok(new { success = true });
        }
    }
}