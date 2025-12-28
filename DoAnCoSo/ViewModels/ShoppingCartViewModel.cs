using DoAnCoSo.Models;

namespace DoAnCoSo.ViewModels
{
    public class ShoppingCartViewModel
    {
        public List<CartItem> CartItemsFromDb { get; set; } = new List<CartItem>();


        public decimal CartTotal { get; set; }
    }
}
