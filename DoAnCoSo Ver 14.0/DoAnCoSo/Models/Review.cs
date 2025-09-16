namespace DoAnCoSo.Models
{
    public class Review
    {
        public int Id { get; set; }
        public string? UserId { get; set; }
        public ApplicationUser User { get; set; }

        public int ServiceId { get; set; }
        public Service Service { get; set; }

        public int Rating { get; set; } // 1-5 sao
        public string? Comment { get; set; }
    }
}
