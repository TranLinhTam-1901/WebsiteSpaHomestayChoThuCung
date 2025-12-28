using DoAnCoSo.Models;

public class Favorite
{
    public int Id { get; set; }

    public string UserId { get; set; } // Khóa ngoại đến bảng AspNetUsers
    public ApplicationUser User { get; set; }

    public int ProductId { get; set; } // Khóa ngoại đến bảng Product
    public Product Product { get; set; }
}