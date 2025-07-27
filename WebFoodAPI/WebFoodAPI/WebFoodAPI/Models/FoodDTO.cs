namespace WebFoodAPI.Models
{
    public class FoodDTO
    {
        public int Id { get; set; }

        public string Name { get; set; } = null!;

        public string? Description { get; set; }

        public decimal Price { get; set; }

        public string? ImageUrl { get; set; }

        public int CategoryId { get; set; }

        // Nếu muốn, bạn có thể thêm tên category để trả về cho client, không phải ID thôi
        public string? CategoryName { get; set; }
    }
}
