using System.ComponentModel.DataAnnotations.Schema;

namespace WebFoodAPI.Models
{
    [Table("OrderDetails")]
    public class OrderDetail
    {
        public int Id { get; set; }
        public int OrderId { get; set; }
        public int FoodId { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public Order? Order { get; set; }
        public Food? Food { get; set; }
    }
}