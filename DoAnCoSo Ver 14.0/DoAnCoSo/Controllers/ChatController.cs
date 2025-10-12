using DoAnCoSo.Data;
using DoAnCoSo.Helpers;
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace DoAnCoSo.Controllers
{
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
            return View();
        }

        // ✅ Lấy danh sách cuộc trò chuyện
        public async Task<IActionResult> GetConversations()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var user = await _userManager.FindByIdAsync(userId);

            var conversations = await _context.Conversations
                .Include(c => c.Customer)
                .OrderByDescending(c => c.LastUpdated)
                .ToListAsync();

            foreach (var conv in conversations)
            {
                var lastMessage = _context.ChatMessages
                    .Where(m => m.ConversationId == conv.Id)
                    .OrderByDescending(m => m.SentAt)
                    .FirstOrDefault();

                if (lastMessage != null)
                {
                    var plain = TryDecryptMessage(lastMessage, user);
                    ViewData[$"LastMessage_{conv.Id}"] = plain;
                    ViewData[$"LastMessageTime_{conv.Id}"] = lastMessage.SentAt;
                }
            }

            return PartialView("_ConversationList", conversations);
        }

        [HttpGet]
        public async Task<IActionResult> GetChatHistory(int skip = 0, int take = 20)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var user = await _userManager.FindByIdAsync(userId);

            var conversation = _context.Conversations
                .FirstOrDefault(c => c.CustomerId == userId);

            if (conversation == null)
            {
                conversation = new Conversation
                {
                    CustomerId = userId,
                    LastUpdated = DateTime.Now
                };
                _context.Conversations.Add(conversation);
                _context.SaveChanges();
            }

            var messages = await _context.ChatMessages
                .Where(m => m.ConversationId == conversation.Id)
                .OrderByDescending(m => m.SentAt)
                .Skip(skip)
                .Take(take)
                .OrderBy(m => m.SentAt)
                .ToListAsync();

            var decrypted = new List<object>();

            foreach (var m in messages)
            {
                var plain = TryDecryptMessage(m, user);
                decrypted.Add(new
                {
                    senderId = m.SenderId,
                    message = plain,
                    sentAt = m.SentAt
                });
            }

            return Json(decrypted);
        }

        [HttpGet]
        public async Task<IActionResult> GetUnreadCount()
        {
            var customerId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(customerId)) return Unauthorized();

            var unreadCount = await _context.ChatMessages
                .Where(m => m.ReceiverId == customerId && !m.IsRead)
                .CountAsync();

            return Ok(new { count = unreadCount });
        }

        [HttpPost]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var customerId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(customerId)) return Unauthorized();

            var messages = await _context.ChatMessages
                .Where(m => m.ReceiverId == customerId && !m.IsRead)
                .ToListAsync();

            foreach (var m in messages)
                m.IsRead = true;

            await _context.SaveChangesAsync();
            return Ok();
        }

        // ✅ Giải mã chuẩn cấp 2 + fallback AES
        private string TryDecryptMessage(ChatMessage message, ApplicationUser currentUser)
        {
            try
            {
                if (message.SenderId == currentUser.Id)
                {
                    if (!string.IsNullOrEmpty(message.SenderCopy) && !string.IsNullOrEmpty(message.SenderAesKey))
                        return EncryptionHelper.DecryptHybrid(message.SenderCopy, message.SenderAesKey, currentUser.PrivateKey);
                }
                else
                {
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
