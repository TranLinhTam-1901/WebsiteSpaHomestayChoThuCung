using DoAnCoSo.Data;
using DoAnCoSo.Models;
using Microsoft.EntityFrameworkCore; // ✅ thêm dòng này
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DoAnCoSo.Repositories
{
    public interface IChatMessageRepository
    {
        Task SaveMessage(string senderId, string receiverId, string message);
        Task<List<ChatMessage>> GetConversation(string userId1, string userId2);
    }

    public class ChatMessageRepository : IChatMessageRepository
    {
        private readonly ApplicationDbContext _context;

        public ChatMessageRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task SaveMessage(string senderId, string receiverId, string message)
        {
            var chatMsg = new ChatMessage
            {
                SenderId = senderId,
                ReceiverId = receiverId,
                Message = message,
                SentAt = DateTime.UtcNow,
                IsRead = false
            };

            _context.ChatMessages.Add(chatMsg);
            await _context.SaveChangesAsync();
        }

        public async Task<List<ChatMessage>> GetConversation(string userId1, string userId2)
        {
            return await _context.ChatMessages
                .Where(m => (m.SenderId == userId1 && m.ReceiverId == userId2) ||
                            (m.SenderId == userId2 && m.ReceiverId == userId1))
                .OrderBy(m => m.SentAt)
                .ToListAsync();
        }
    }
}
