using DoAnCoSo.Data;
using DoAnCoSo.Helpers;
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

using DoAnCoSo.Data;
using DoAnCoSo.Helpers;
using DoAnCoSo.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

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
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, "Admins");
        }

        await base.OnConnectedAsync();
    }

    // Khách gửi tin nhắn
    public async Task SendMessageToAdmin(string message)
    {
        var customerId = Context.UserIdentifier;
        var customer = await _userManager.FindByIdAsync(customerId);

        var admins = (await _userManager.GetUsersInRoleAsync("Admin"))
            .OrderBy(a => a.UserName).ToList();
        if (!admins.Any()) return;

        // Lấy hoặc tạo SystemState
        var state = await _context.SystemStates.FirstOrDefaultAsync();
        if (state == null)
        {
            state = new SystemState { CurrentAdminIndex = 0 };
            _context.SystemStates.Add(state);
            await _context.SaveChangesAsync();
        }

        // Lấy hoặc tạo conversation
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

            // Update index
            state.CurrentAdminIndex = (state.CurrentAdminIndex + 1) % admins.Count;
            await _context.SaveChangesAsync();
        }
        else if (string.IsNullOrEmpty(conversation.AdminId))
        {
            // Nếu conversation đã tồn tại nhưng chưa gán admin
            var admin = admins[state.CurrentAdminIndex % admins.Count];
            conversation.AdminId = admin.Id;
            state.CurrentAdminIndex = (state.CurrentAdminIndex + 1) % admins.Count;
            await _context.SaveChangesAsync();
        }

        var adminUser = await _userManager.FindByIdAsync(conversation.AdminId);

        // Mã hóa tin nhắn
        var (cipherForAdmin, encryptedAesKeyForAdmin) = EncryptionHelper.EncryptHybrid(message, adminUser.PublicKey);
        var (cipherForCustomer, encryptedAesKeyForCustomer) = EncryptionHelper.EncryptHybrid(message, customer.PublicKey);

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
            SentAt = DateTime.UtcNow,
            IsRead = false
        };

        _context.ChatMessages.Add(chatMessage);
        conversation.LastUpdated = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        // Realtime
        await Clients.User(conversation.AdminId).SendAsync("ReceiveMessage",
            customerId, customer.UserName, message, chatMessage.SentAt);

        await Clients.Caller.SendAsync("ReceiveMessage",
            customerId, customer.UserName, message, chatMessage.SentAt);

        await Clients.Group("Admins").SendAsync("UpdateCustomerList");
    }

    // Admin gửi tin nhắn
    public async Task SendMessageToCustomer(string customerId, string message)
    {
        var adminId = Context.UserIdentifier;
        var admin = await _userManager.FindByIdAsync(adminId);
        var customer = await _userManager.FindByIdAsync(customerId);

        // Tìm hoặc tạo conversation
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
        }
        else if (conversation.AdminId == null)
        {
            conversation.AdminId = adminId;
        }

        // Mã hóa
        var (cipherForCustomer, encryptedAesKeyForCustomer) = EncryptionHelper.EncryptHybrid(message, customer.PublicKey);
        var (cipherForAdmin, encryptedAesKeyForAdmin) = EncryptionHelper.EncryptHybrid(message, admin.PublicKey);

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
            SentAt = DateTime.UtcNow,
            IsRead = false
        };

        _context.ChatMessages.Add(chatMessage);
        conversation.LastUpdated = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        // Realtime
        await Clients.User(customerId).SendAsync("ReceiveMessage",
            adminId, admin.UserName, message, chatMessage.SentAt);

        await Clients.Caller.SendAsync("ReceiveMessage",
            adminId, admin.UserName, message, chatMessage.SentAt);

        await Clients.Group("Admins").SendAsync("UpdateCustomerList");
    }
}

