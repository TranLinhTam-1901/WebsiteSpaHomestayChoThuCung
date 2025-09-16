    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    namespace DoAnCoSo.Models 
    {
        public class ProductReview
        {
       
            [Key]
            public int Id { get; set; }

            [ForeignKey("Product")]
            [Required] 
            public int ProductId { get; set; }

            [ForeignKey("User")] 
            public string? UserId { get; set; }
       
            [Required(ErrorMessage = "Vui lòng chọn số sao đánh giá.")]
            [Range(1, 5, ErrorMessage = "Đánh giá phải là số từ 1 đến 5.")]
            public byte Rating { get; set; }

       
            [MaxLength(1000, ErrorMessage = "Nội dung bình luận không được quá 1000 ký tự.")]
            public string? CommentText { get; set; } 

      
            public DateTime? CreatedDate { get; set; }

            public ApplicationUser? User { get; set; }

        public Product? Product { get; set; }
         public List<ProductReviewImage> Images { get; set; } = new List<ProductReviewImage>();


    }
    }