using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace DoAnCoSo.Models
{
    public class CartItem
    {
        [Key] // Chỉ định Id là khóa chính
        public int Id { get; set; }

        // Khóa ngoại liên kết với người dùng (ApplicationUser)
        // Kiểu dữ liệu phải khớp với khóa chính của ApplicationUser (thường là string)
        [ForeignKey("ApplicationUser")]
        public string UserId { get; set; }
        public virtual ApplicationUser ApplicationUser { get; set; } // Navigation property

        // Khóa ngoại liên kết với sản phẩm (Product)
        [ForeignKey("Product")]
        public int ProductId { get; set; }
        public virtual Product Product { get; set; } // Navigation property

        // Số lượng sản phẩm trong giỏ hàng
        public int Quantity { get; set; }

        // Thời gian sản phẩm được thêm vào giỏ hàng (tùy chọn)
        public DateTime DateCreated { get; set; } = DateTime.UtcNow;
        
        public string? SelectedFlavor { get; set; }
    }
}
