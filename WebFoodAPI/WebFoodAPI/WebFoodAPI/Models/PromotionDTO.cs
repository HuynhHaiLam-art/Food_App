namespace WebFoodAPI.Models
{
    public class PromotionDTO
    {
        public int Id { get; set; }

        public string Code { get; set; } = string.Empty;

        public string? Description { get; set; }

        public int? DiscountPercent { get; set; }

        public DateTime StartDate { get; set; }

        public DateTime EndDate { get; set; }
    }
}
