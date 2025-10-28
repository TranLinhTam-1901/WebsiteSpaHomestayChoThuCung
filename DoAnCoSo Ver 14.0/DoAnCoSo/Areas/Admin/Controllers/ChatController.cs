using DoAnCoSo.Helper;
using DoAnCoSo.Helpers;
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Text.Json;

namespace DoAnCoSo.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin")]
    public class ChatController : Controller
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _env;

        public ChatController(UserManager<ApplicationUser> userManager, ApplicationDbContext context, IWebHostEnvironment env)
        {
            _userManager = userManager;
            _context = context;
            _env = env;
        }

        public IActionResult Index()
        {
            var customers = _userManager.GetUsersInRoleAsync("customer").Result;
            return View(customers);
        }

        public async Task<IActionResult> Chat(string customerId)
        {
            var customer = await _userManager.FindByIdAsync(customerId);
            ViewBag.CurrentCustomerName = customer?.FullName ?? customer?.UserName ?? "Người dùng";
            ViewBag.AdminName = (await _userManager.GetUserAsync(User))?.FullName ?? "Admin";
            return View();
        }

        // ✅ Lấy lịch sử tin nhắn trong 1 cuộc trò chuyện
        [HttpGet]
        public async Task<IActionResult> GetMessages(string customerId, int skip = 0, int take = 20)
        {
            var adminId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(adminId))
                return Unauthorized();

            // Lấy conversation giữa admin và customer
            var conversation = await _context.Conversations
                .FirstOrDefaultAsync(c =>
                    (c.CustomerId == customerId && (c.AdminId == adminId || c.AdminId == null)) ||
                    (c.CustomerId == adminId && c.AdminId == customerId));

            if (conversation == null)
                return Ok(new List<object>());

            // Lấy tin nhắn theo phân trang
            var messages = await _context.ChatMessages
                .Where(m => m.ConversationId == conversation.Id)
                .OrderByDescending(m => m.SentAt)
                .Skip(skip)
                .Take(take)
                .OrderBy(m => m.SentAt) // sắp xếp từ cũ → mới
                .ToListAsync();

            var admin = await _userManager.FindByIdAsync(adminId);
            var result = new List<object>();

            foreach (var m in messages)
            {
                var plain = TryDecryptMessage(m, admin);

                List<string> imageUrls = new();
                List<string> imageKeys = new();

                if (!string.IsNullOrEmpty(m.ImageUrlsJson))
                {
                    try { imageUrls = JsonSerializer.Deserialize<List<string>>(m.ImageUrlsJson) ?? new List<string>(); }
                    catch { imageUrls = new List<string>(); }
                }

                if (!string.IsNullOrEmpty(m.ImageKeysJson))
                {
                    try { imageKeys = JsonSerializer.Deserialize<List<string>>(m.ImageKeysJson) ?? new List<string>(); }
                    catch { imageKeys = new List<string>(); }
                }

                result.Add(new
                {
                    fromUserId = m.SenderId,
                    message = plain,
                    sentAt = m.SentAt,
                    imageUrls,
                    imageKeys
                });
            }

            return Ok(result);
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

        [HttpPost]
        public async Task<IActionResult> UploadImage(IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("Không có file");

            // Tạo thư mục nếu chưa tồn tại
            var uploadFolder = Path.Combine(_env.WebRootPath, "uploads", "chat");
            if (!Directory.Exists(uploadFolder))
                Directory.CreateDirectory(uploadFolder);

            var uniqueName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
            var fullPath = Path.Combine(uploadFolder, uniqueName);

            using (var stream = new FileStream(fullPath, FileMode.Create))
                await file.CopyToAsync(stream);

            var token = TokenHelper.GenerateToken();
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "anonymous";

            var chatImg = new ChatImage
            {
                FileName = uniqueName,
                FilePath = $"/uploads/chat/{uniqueName}",
                Token = token,
                ExpireAt = DateTime.UtcNow.AddMonths(6),
                UploaderId = userId
            };
            _context.ChatImages.Add(chatImg);
            await _context.SaveChangesAsync();

            // Trả về đường dẫn đúng route (có thể tùy theo bạn dùng Admin hay Customer)
            return Ok(new { success = true, imageUrl = $"/Chat/GetImage?token={token}" });
        }

        [HttpGet]
        public IActionResult GetImage(string token)
        {
            if (string.IsNullOrEmpty(token))
                return NotFound("Token rỗng");

            var record = _context.ChatImages.FirstOrDefault(x => x.Token == token);
            if (record == null)
                return NotFound("Không tìm thấy token");

            var filePath = Path.Combine(_env.WebRootPath, "uploads", "chat", record.FileName);
            if (!System.IO.File.Exists(filePath))
                return NotFound("File không tồn tại");

            var ext = Path.GetExtension(record.FileName).ToLower();
            var contentType = ext switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".gif" => "image/gif",
                ".webp" => "image/webp",
                _ => "application/octet-stream"
            };

            var bytes = System.IO.File.ReadAllBytes(filePath);
            return File(bytes, contentType);
        }

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
