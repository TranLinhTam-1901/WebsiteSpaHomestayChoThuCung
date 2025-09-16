namespace DoAnCoSo.Models
{
    public class ChatCustomer
    {
        public string Id { get; set; }
        public string FullName { get; set; }
        public int UnreadCount { get; set; }
        public DateTime LastMessageAt { get; set; }
    }

}
