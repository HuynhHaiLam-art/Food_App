using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebFoodAPI.Models
{
    [Table("Orders")]
    public class Order
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Address { get; set; } = string.Empty;
        public decimal TotalAmount { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime OrderDate { get; set; }
        public int? PromotionId { get; set; }
        public Promotion? Promotion { get; set; }
        public User? User { get; set; }
        public List<OrderDetail> OrderDetails { get; set; } = new();
    }
}