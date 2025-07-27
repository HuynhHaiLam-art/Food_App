namespace WebFoodAPI.Models
{
    public class OrderDTO
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public DateTime? OrderDate { get; set; }

        public decimal TotalAmount { get; set; }

        public string Status { get; set; } = string.Empty;

        public int? PromotionId { get; set; }

        public string? PromotionCode { get; set; }

        public int TotalItems { get; set; }
        public List<OrderDetailDTO> OrderDetails { get; set; } = new();
    }
}
