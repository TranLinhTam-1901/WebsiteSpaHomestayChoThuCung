using DoAnCoSo.Models;

namespace DoAnCoSo.ViewModels
{
    public class CheckoutViewModel
    {


        //public ShoppingCart Cart { get; set; }
        public List<CartItem> CartItemsFromDb { get; set; }
        public bool IsBuyNowCheckout { get; set; }
        public Order Order { get; set; }
       
        public int? BuyNowProductId { get; set; }
        public int? BuyNowQuantity { get; set; }
        public string?  BuyNowFlavor { get; set; }

        public List<int> SelectedCartItemIds { get; set; } = new List<int>();

        public decimal CartTotal { get ; set; }
        public CheckoutViewModel()
        {
            
            CartItemsFromDb = new List<CartItem>(); 
            Order = new Order(); 
            SelectedCartItemIds = new List<int>(); 
        }
    }
}
