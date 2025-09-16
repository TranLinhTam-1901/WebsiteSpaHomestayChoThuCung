using DoAnCoSo.Data;
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authorization;
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
            var customers = _userManager.GetUsersInRoleAsync("customer").Result;
            return View(customers);
        }

        // ✅ Lấy danh sách cuộc trò chuyện
        public async Task<IActionResult> GetConversations()
        {
            var conversations = await _context.Conversations
                .Include(c => c.Customer)
                .OrderByDescending(c => c.LastUpdated)
                .ToListAsync();

            // ✅ Lấy tin nhắn cuối cùng cho từng cuộc trò chuyện
            foreach (var conv in conversations)
            {
                var lastMessage = _context.ChatMessages
                    .Where(m => m.ConversationId == conv.Id)
                    .OrderByDescending(m => m.SentAt)
                    .FirstOrDefault();

                // Gắn tin nhắn cuối vào ViewData để hiển thị trong sidebar
                if (lastMessage != null)
                {
                    ViewData[$"LastMessage_{conv.Id}"] = lastMessage.Message;
                    ViewData[$"LastMessageTime_{conv.Id}"] = lastMessage.SentAt;
                }
            }

            return PartialView("_ConversationList", conversations);
        }

        [HttpGet]
        public IActionResult GetChatHistory(int skip = 0, int take = 20)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            var conversation = _context.Conversations
                .FirstOrDefault(c => c.CustomerId == userId);

            // Tạo conversation nếu chưa có
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

            var messages = _context.ChatMessages
                .Where(m => m.ConversationId == conversation.Id)
                .OrderByDescending(m => m.SentAt)
                .Skip(skip)
                .Take(take)
                .OrderBy(m => m.SentAt)
                .Select(m => new {
                    senderId = m.SenderId,
                    message = m.Message,
                    sentAt = m.SentAt
                })
                .ToList();

            return Json(messages);
        }
    }
}