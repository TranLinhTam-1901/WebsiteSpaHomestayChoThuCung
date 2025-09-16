using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Identity;
using DoAnCoSo.Models;
using DoAnCoSo.Data;

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
            Console.WriteLine($"[ChatHub] {user.UserName} đã vào group Admins");
        }

        await base.OnConnectedAsync();
    }

    // ✅ Khách gửi tin nhắn cho admin
    public async Task SendMessageToAdmin(string message)
    {
        var senderId = Context.UserIdentifier;

        // 🔹 Lấy 1 admin bất kỳ (có thể cải tiến để phân bổ)
        var admin = _userManager.GetUsersInRoleAsync("Admin").Result.FirstOrDefault();
        if (admin == null) return;

        // 🔹 Tìm hoặc tạo conversation
        var conversation = _context.Conversations
            .FirstOrDefault(c => c.CustomerId == senderId && c.AdminId == admin.Id);

        if (conversation == null)
        {
            conversation = new Conversation
            {
                CustomerId = senderId,
                AdminId = admin.Id,
                LastUpdated = DateTime.UtcNow
            };
            _context.Conversations.Add(conversation);
            await _context.SaveChangesAsync(); // lưu conversation trước
        }

        // 🔹 Lưu tin nhắn
        var sender = await _userManager.FindByIdAsync(senderId);

        var chatMessage = new ChatMessage
        {
            ConversationId = conversation.Id,
            SenderId = senderId,
            ReceiverId = admin.Id,
            SenderName = sender?.UserName, // 👈 thêm tên
            Message = message,
            SentAt = TimeZoneInfo.ConvertTimeBySystemTimeZoneId(DateTime.UtcNow, "SE Asia Standard Time"),
            IsRead = false
        };
        _context.ChatMessages.Add(chatMessage);

        conversation.LastUpdated = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        // 🔹 Gửi realtime cho admin
        await Clients.Group("Admins").SendAsync("ReceiveMessage", senderId, sender?.UserName, message, chatMessage.SentAt);
        await Clients.User(senderId).SendAsync("ReceiveMessage", senderId, sender?.UserName, message, chatMessage.SentAt);

    }

    // Admin gửi tin nhắn cho khách
    public async Task SendMessageToCustomer(string customerId, string message)
    {
        var senderId = Context.UserIdentifier;

        // Tìm hoặc tạo conversation
        var conversation = _context.Conversations
            .FirstOrDefault(c => c.CustomerId == customerId && c.AdminId == senderId);

        if (conversation == null)
        {
            conversation = new Conversation
            {
                CustomerId = customerId,
                AdminId = senderId,
                LastUpdated = DateTime.UtcNow
            };
            _context.Conversations.Add(conversation);
            await _context.SaveChangesAsync();
        }

        var sender = await _userManager.FindByIdAsync(senderId);

        var chatMessage = new ChatMessage
        {
            ConversationId = conversation.Id,
            SenderId = senderId,
            ReceiverId = customerId,
            SenderName = sender?.UserName,
            Message = message,
            SentAt = TimeZoneInfo.ConvertTimeBySystemTimeZoneId(DateTime.UtcNow, "SE Asia Standard Time"),
            IsRead = false
        };
        _context.ChatMessages.Add(chatMessage);

        conversation.LastUpdated = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        // 🔹 Gửi realtime cho khách
        await Clients.User(customerId).SendAsync("ReceiveMessage", senderId, sender?.UserName, message, chatMessage.SentAt);

        // 🔹 Gửi realtime cho admin (người gửi) để update chat ngay
        await Clients.Caller.SendAsync("ReceiveMessage", senderId, sender?.UserName, message, chatMessage.SentAt);
    }
}
