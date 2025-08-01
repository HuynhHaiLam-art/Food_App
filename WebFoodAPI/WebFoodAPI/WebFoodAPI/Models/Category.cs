﻿using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebFoodAPI.Models;
[Table("Categories")]
public partial class Category
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<Food> Foods { get; set; } = new List<Food>();
}
