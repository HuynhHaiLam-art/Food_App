namespace WebFoodAPI.Models
{
    public class OrderDetailDTO
    {
        public int FoodId { get; set; }
        public string FoodName { get; set; } = string.Empty;
        public string? FoodImageUrl { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal Total => Quantity * UnitPrice;
    }
}
