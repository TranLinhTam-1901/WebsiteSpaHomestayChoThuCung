namespace DoAnCoSo.Models
{
    public class Promotion
    {
        public int Id { get; set; }
        public string Title { get; set; } = "";
        public string ShortDescription { get; set; } = "";
        public string Description { get; set; } = "";
        public string Image { get; set; } = "";
        public int Discount { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }

}
