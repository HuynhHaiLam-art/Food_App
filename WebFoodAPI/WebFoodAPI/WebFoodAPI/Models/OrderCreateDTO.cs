using System.Collections.Generic;

namespace WebFoodAPI.Models
{
    public class OrderCreateDTO
    {
        public int UserId { get; set; }
        public string Address { get; set; } = string.Empty;
        public decimal TotalAmount { get; set; }
        public string Status { get; set; } = string.Empty;
        public int? PromotionId { get; set; }
        public List<OrderDetailCreateDTO> OrderDetails { get; set; } = new();
    }
}