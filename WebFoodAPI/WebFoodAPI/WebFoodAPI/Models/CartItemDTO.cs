namespace WebFoodAPI.Models
{
    public class CartItemDTO
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public int FoodId { get; set; }

        public string FoodName { get; set; } = string.Empty;

        public decimal FoodPrice { get; set; }

        public string? FoodImageUrl { get; set; }

        public int Quantity { get; set; }

        public DateTime? CreatedAt { get; set; }
    }
}
