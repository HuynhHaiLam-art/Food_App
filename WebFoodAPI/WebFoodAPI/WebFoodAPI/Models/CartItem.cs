using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebFoodAPI.Models;
[Table("CartItems")]
public partial class CartItem
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public int FoodId { get; set; }

    public int Quantity { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual Food Food { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
