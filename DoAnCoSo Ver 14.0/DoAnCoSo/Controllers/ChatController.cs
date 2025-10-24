using DoAnCoSo.Helper;
using DoAnCoSo.Helpers;
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using System.Security.Claims;

namespace DoAnCoSo.Controllers
{
    public class ChatController : Controller
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _env; // ✅ thêm dòng này

        public ChatController(UserManager<ApplicationUser> userManager, ApplicationDbContext context, IWebHostEnvironment env)
        {
            _userManager = userManager;
            _context = context;
            _env = env; // ✅ khởi tạo
        }

        public IActionResult Index()
        {
            return View();
        }

        public async Task<IActionResult> ChatWithAdmin()
        {
            var admin = await _userManager.GetUsersInRoleAsync("Admin");
            var currentAdmin = admin.FirstOrDefault();
            ViewBag.AdminName = currentAdmin?.FullName ?? currentAdmin?.UserName ?? "Admin";
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
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
                return Unauthorized();

            var conversation = await _context.Conversations
                .FirstOrDefaultAsync(c => c.CustomerId == userId);

            // Nếu chưa có conversation thì tạo mới
            if (conversation == null)
            {
                conversation = new Conversation
                {
                    CustomerId = userId,
                    LastUpdated = DateTime.Now
                };
                _context.Conversations.Add(conversation);
                await _context.SaveChangesAsync();
            }

            // Lấy tin nhắn theo phân trang
            var messages = await _context.ChatMessages
                .Where(m => m.ConversationId == conversation.Id)
                .OrderByDescending(m => m.SentAt)
                .Skip(skip)
                .Take(take)
                .OrderBy(m => m.SentAt) // sắp xếp từ cũ → mới
                .ToListAsync();

            var result = new List<object>();

            foreach (var m in messages)
            {
                var plain = TryDecryptMessage(m, user);

                List<string> imageUrls = new();
                if (!string.IsNullOrEmpty(m.ImageUrlsJson))
                {
                    try
                    {
                        imageUrls = JsonSerializer.Deserialize<List<string>>(m.ImageUrlsJson) ?? new List<string>();
                    }
                    catch
                    {
                        imageUrls = new List<string>();
                    }
                }

                result.Add(new
                {
                    senderId = m.SenderId,
                    message = plain,
                    sentAt = m.SentAt,
                    imageUrls
                });
            }

            return Ok(result);
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

        [HttpPost]
        public async Task<IActionResult> UploadImage(IFormFile file)
        {
            try
            {
                if (file == null || file.Length == 0)
                    return BadRequest("Không có file tải lên.");

                // ✅ đảm bảo thư mục tồn tại
                var uploadFolder = Path.Combine(_env.WebRootPath, "uploads", "chat");
                if (!Directory.Exists(uploadFolder))
                    Directory.CreateDirectory(uploadFolder);

                var uniqueName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
                var fullPath = Path.Combine(uploadFolder, uniqueName);

                using (var stream = new FileStream(fullPath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                // ✅ lưu DB
                var token = TokenHelper.GenerateToken();
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "anonymous";

                var chatImg = new ChatImage
                {
                    FileName = uniqueName,
                    FilePath = $"/uploads/chat/{uniqueName}", // đường dẫn ảo
                    Token = token,
                    ExpireAt = DateTime.UtcNow.AddMonths(6),
                    UploaderId = userId
                };

                _context.ChatImages.Add(chatImg);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, imageUrl = $"/Chat/GetImage?token={token}" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Upload failed: {ex.Message}");
            }
        }

        [HttpGet]
        public IActionResult GetImage(string token)
        {
            if (string.IsNullOrEmpty(token))
                return NotFound("Token rỗng");

            var record = _context.ChatImages.FirstOrDefault(x => x.Token == token);
            if (record == null)
                return NotFound("Không tìm thấy token trong DB");

            var filePath = Path.Combine(_env.WebRootPath, "uploads", "chat", record.FileName);
            if (!System.IO.File.Exists(filePath))
                return NotFound("File không tồn tại trên server");

            // Xác định content type dựa vào extension
            var ext = Path.GetExtension(record.FileName).ToLower();
            var contentType = ext switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".gif" => "image/gif",
                ".webp" => "image/webp",
                _ => "application/octet-stream"
            };

            // Đọc file trực tiếp
            var bytes = System.IO.File.ReadAllBytes(filePath);
            return File(bytes, contentType);
        }

        // ✅ View ảnh theo token
        [HttpGet]
        public IActionResult ViewImage(string file, string token)
        {
            var record = _context.ChatImages.FirstOrDefault(x => x.FileName == file && x.Token == token && x.ExpireAt > DateTime.UtcNow);
            if (record == null)
                return Unauthorized(); // Token sai hoặc ảnh không tồn tại

            var filePath = Path.Combine(_env.WebRootPath, "uploads", "chat", file);
            if (!System.IO.File.Exists(filePath))
                return NotFound();

            var imageBytes = System.IO.File.ReadAllBytes(filePath);
            return File(imageBytes, "image/jpeg");
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
