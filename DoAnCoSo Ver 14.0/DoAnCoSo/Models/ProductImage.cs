namespace DoAnCoSo.Models
{
    public class ProductImage
    {
        public int Id { get; set; } 
        public string Url { get; set; }

        //Khóa ngoại trỏ đến sản phẩm 
        public int ProductId { get; set; }  
        public Product? Product { get; set; }

 
    }
}
