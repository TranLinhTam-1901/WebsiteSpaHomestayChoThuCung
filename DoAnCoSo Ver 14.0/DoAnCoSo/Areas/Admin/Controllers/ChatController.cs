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
        public async Task<IActionResult> GetMessages(string customerId, int skip = 0, int take = 20)
        {
            var adminId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            var conversation = await _context.Conversations
                .FirstOrDefaultAsync(c =>
                    (c.CustomerId == customerId && c.AdminId == adminId) ||
                    (c.CustomerId == adminId && c.AdminId == customerId));

            if (conversation == null) return Ok(new List<object>());

            var messages = await _context.ChatMessages
                .Where(m => m.ConversationId == conversation.Id)
                .OrderByDescending(m => m.SentAt)
                .Skip(skip)
                .Take(take)
                .ToListAsync();

            var admin = await _userManager.FindByIdAsync(adminId);
            var decryptedList = new List<object>();

            foreach (var m in messages)
            {
                var plain = TryDecryptMessage(m, admin);
                decryptedList.Add(new
                {
                    fromUserId = m.SenderId,
                    message = plain,
                    sentAt = m.SentAt
                });
            }

            decryptedList.Reverse();
            return Ok(decryptedList);
        }

        [HttpGet]
        public async Task<IActionResult> GetCustomers()
        {
            var adminId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            var result = await _context.Conversations
                .Where(c => c.AdminId == adminId || c.CustomerId == adminId)
                .OrderByDescending(c => c.LastUpdated)
                .Select(c => new
                {
                    id = c.CustomerId == adminId ? c.AdminId : c.CustomerId,
                    fullName = c.CustomerId == adminId ? c.Admin.FullName : c.Customer.FullName,
                    unreadCount = _context.ChatMessages.Count(m => m.ConversationId == c.Id && !m.IsRead && m.SenderId != adminId),
                    lastUpdated = c.LastUpdated
                })
                .ToListAsync();

            return Ok(result);
        }


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
                    msg.IsRead = true;

                await _context.SaveChangesAsync();
            }

            return Ok(new { success = true });
        }

        // ✅ Fix decrypt logic: nếu chính mình gửi thì trả plaintext
        private string TryDecryptMessage(ChatMessage message, ApplicationUser currentUser)
        {
            try
            {
                // Nếu mình là người gửi → giải bằng bản sao (sender copy)
                if (message.SenderId == currentUser.Id)
                {
                    if (!string.IsNullOrEmpty(message.SenderCopy) && !string.IsNullOrEmpty(message.SenderAesKey))
                        return EncryptionHelper.DecryptHybrid(message.SenderCopy, message.SenderAesKey, currentUser.PrivateKey);
                }
                else
                {
                    // Nếu mình là người nhận → giải bản chính
                    if (!string.IsNullOrEmpty(message.Message) && !string.IsNullOrEmpty(message.EncryptedAesKey))
                        return EncryptionHelper.DecryptHybrid(message.Message, message.EncryptedAesKey, currentUser.PrivateKey);
                }

                return message.Message;
            }
            catch
            {
                return message.Message;
            }
        }
    }
}
