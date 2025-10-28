using DoAnCoSo.Helper;
using DoAnCoSo.Helpers;
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using System.Web;

public class ChatHub : Hub
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ApplicationDbContext _context;

    public ChatHub(UserManager<ApplicationUser> userManager, ApplicationDbContext context)
    {
        _userManager = userManager;
        _context = context;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.UserIdentifier;
        var user = await _userManager.FindByIdAsync(userId);

        if (user != null && await _userManager.IsInRoleAsync(user, "Admin"))
            await Groups.AddToGroupAsync(Context.ConnectionId, "Admins");

        await base.OnConnectedAsync();
    }

    // ✅ Khách gửi tin nhắn (có thể kèm ảnh)
    public async Task SendMessageToAdmin(string message, List<string>? imageUrls, List<string>? imageKeys)
    {
        var customerId = Context.UserIdentifier;
        var customer = await _userManager.FindByIdAsync(customerId);
        if (customer == null) return;

        var admins = (await _userManager.GetUsersInRoleAsync("Admin"))
            .OrderBy(a => a.UserName)
            .ToList();
        if (!admins.Any()) return;

        var state = await _context.SystemStates.FirstOrDefaultAsync();
        if (state == null)
        {
            state = new SystemState { CurrentAdminIndex = 0 };
            _context.SystemStates.Add(state);
            await _context.SaveChangesAsync();
        }

        // Tìm hoặc tạo cuộc hội thoại
        var conversation = await _context.Conversations
            .FirstOrDefaultAsync(c => c.CustomerId == customerId);

        if (conversation == null)
        {
            var admin = admins[state.CurrentAdminIndex % admins.Count];
            conversation = new Conversation
            {
                CustomerId = customerId,
                AdminId = admin.Id,
                LastUpdated = DateTime.UtcNow
            };
            _context.Conversations.Add(conversation);
            state.CurrentAdminIndex = (state.CurrentAdminIndex + 1) % admins.Count;
            await _context.SaveChangesAsync();
        }
        else if (string.IsNullOrEmpty(conversation.AdminId))
        {
            var admin = admins[state.CurrentAdminIndex % admins.Count];
            conversation.AdminId = admin.Id;
            state.CurrentAdminIndex = (state.CurrentAdminIndex + 1) % admins.Count;
            await _context.SaveChangesAsync();
        }

        // 🔧 Xử lý ảnh gửi lên
        List<string>? validImageUrls = null;
        if (imageUrls != null && imageUrls.Any())
        {
            validImageUrls = new List<string>();

            foreach (var uploaded in imageUrls)
            {
                if (string.IsNullOrWhiteSpace(uploaded)) continue;

                string token = null;
                try
                {
                    var uri = new Uri(uploaded, UriKind.RelativeOrAbsolute);
                    var query = uri.IsAbsoluteUri ? uri.Query : new Uri("http://dummy" + uploaded).Query;
                    var queryParams = HttpUtility.ParseQueryString(query);
                    token = queryParams["token"];
                }
                catch
                {
                    token = null;
                }

                var chatImg = new ChatImage
                {
                    FileName = token ?? Guid.NewGuid().ToString(), // fallback
                    FilePath = uploaded,
                    Token = token ?? TokenHelper.GenerateToken(),
                    ExpireAt = DateTime.UtcNow.AddMonths(6),
                    UploaderId = customerId
                };
                _context.ChatImages.Add(chatImg);

                validImageUrls.Add(uploaded);
            }
            await _context.SaveChangesAsync();
        }

        // ✅ Đảm bảo admin hợp lệ
        var adminUser = await _userManager.FindByIdAsync(conversation.AdminId);
        if (adminUser == null)
        {
            var newAdmin = admins[state.CurrentAdminIndex % admins.Count];
            conversation.AdminId = newAdmin.Id;
            await _context.SaveChangesAsync();
            adminUser = newAdmin;
        }

        // ✅ Mã hóa nội dung
        var (cipherForAdmin, encryptedAesKeyForAdmin) = EncryptionHelper.EncryptHybrid(message ?? "", adminUser.PublicKey);
        var (cipherForCustomer, encryptedAesKeyForCustomer) = EncryptionHelper.EncryptHybrid(message ?? "", customer.PublicKey);

        var chatMessage = new ChatMessage
        {
            ConversationId = conversation.Id,
            SenderId = customerId,
            ReceiverId = conversation.AdminId,
            SenderName = customer.UserName,
            Message = cipherForAdmin,
            EncryptedAesKey = encryptedAesKeyForAdmin,
            SenderCopy = cipherForCustomer,
            SenderAesKey = encryptedAesKeyForCustomer,
            ImageUrlsJson = validImageUrls != null && validImageUrls.Any()
                ? JsonConvert.SerializeObject(validImageUrls)
                : null,
            ImageKeysJson = imageKeys != null && imageKeys.Any()
                ? JsonConvert.SerializeObject(imageKeys)
                : null,
            SentAt = DateTime.UtcNow,
            IsRead = false
        };

        _context.ChatMessages.Add(chatMessage);
        conversation.LastUpdated = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        // ✅ Gửi lại cho Admin & Customer
        if (!string.IsNullOrEmpty(conversation.AdminId))
        {
            await Clients.User(conversation.AdminId).SendAsync("ReceiveMessage",
                customerId,
                customer.UserName,
                message,
                validImageUrls ?? new List<string>(),
                chatMessage.SentAt);
        }

        await Clients.Caller.SendAsync("ReceiveMessage",
            customerId,
            customer.UserName,
            message,
            validImageUrls ?? new List<string>(),
            chatMessage.SentAt);

        await Clients.Group("Admins").SendAsync("UpdateCustomerList");
    }

    // ✅ Admin gửi tin nhắn (có thể kèm ảnh)
    public async Task SendMessageToCustomer(string customerId, string message, List<string>? imageUrls, List<string>? imageKeys)
    {
        var adminId = Context.UserIdentifier;
        var admin = await _userManager.FindByIdAsync(adminId);
        var customer = await _userManager.FindByIdAsync(customerId);
        if (customer == null || admin == null) return;

        // Tạo hoặc cập nhật conversation
        var conversation = await _context.Conversations
            .FirstOrDefaultAsync(c => c.CustomerId == customerId &&
                                      (c.AdminId == adminId || c.AdminId == null));

        if (conversation == null)
        {
            conversation = new Conversation
            {
                CustomerId = customerId,
                AdminId = adminId,
                LastUpdated = DateTime.UtcNow
            };
            _context.Conversations.Add(conversation);
            await _context.SaveChangesAsync();
        }
        else if (conversation.AdminId == null)
        {
            conversation.AdminId = adminId;
            await _context.SaveChangesAsync();
        }

        // 🔧 Xử lý ảnh giống SendMessageToAdmin
        List<string>? validImageUrls = null;
        if (imageUrls != null && imageUrls.Any())
        {
            validImageUrls = new List<string>();

            foreach (var uploaded in imageUrls)
            {
                if (string.IsNullOrWhiteSpace(uploaded)) continue;

                string token = null;
                try
                {
                    var uri = new Uri(uploaded, UriKind.RelativeOrAbsolute);
                    var query = uri.IsAbsoluteUri ? uri.Query : new Uri("http://dummy" + uploaded).Query;
                    var queryParams = System.Web.HttpUtility.ParseQueryString(query);
                    token = queryParams["token"];
                }
                catch
                {
                    token = null;
                }

                var chatImg = new ChatImage
                {
                    FileName = token ?? Guid.NewGuid().ToString(),
                    FilePath = uploaded,
                    Token = token ?? TokenHelper.GenerateToken(),
                    ExpireAt = DateTime.UtcNow.AddMonths(6),
                    UploaderId = adminId
                };
                _context.ChatImages.Add(chatImg);

                validImageUrls.Add(uploaded);
            }

            await _context.SaveChangesAsync();
        }

        // ✅ Mã hóa tin nhắn
        var (cipherForCustomer, encryptedAesKeyForCustomer) = EncryptionHelper.EncryptHybrid(message ?? "", customer.PublicKey);
        var (cipherForAdmin, encryptedAesKeyForAdmin) = EncryptionHelper.EncryptHybrid(message ?? "", admin.PublicKey);

        var chatMessage = new ChatMessage
        {
            ConversationId = conversation.Id,
            SenderId = adminId,
            ReceiverId = customerId,
            SenderName = admin.UserName,
            Message = cipherForCustomer,
            EncryptedAesKey = encryptedAesKeyForCustomer,
            SenderCopy = cipherForAdmin,
            SenderAesKey = encryptedAesKeyForAdmin,
            ImageUrlsJson = validImageUrls != null && validImageUrls.Any() ? JsonConvert.SerializeObject(validImageUrls) : null,
            ImageKeysJson = imageKeys != null && imageKeys.Any() ? JsonConvert.SerializeObject(imageKeys) : null,
            SentAt = DateTime.UtcNow,
            IsRead = false
        };

        _context.ChatMessages.Add(chatMessage);
        conversation.LastUpdated = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        // Gửi qua SignalR
        await Clients.User(customerId).SendAsync("ReceiveMessage",
            adminId, admin.UserName, message, validImageUrls, chatMessage.SentAt);

        await Clients.Caller.SendAsync("ReceiveMessage",
            adminId, admin.UserName, message, validImageUrls, chatMessage.SentAt);

        await Clients.Group("Admins").SendAsync("UpdateCustomerList");
    }
}
