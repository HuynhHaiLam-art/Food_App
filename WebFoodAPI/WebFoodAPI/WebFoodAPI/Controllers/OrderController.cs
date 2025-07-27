using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebFoodAPI.Models;

namespace WebFoodAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OrderController : ControllerBase
    {
        private readonly DbappFoodContext _context;

        public OrderController(DbappFoodContext context)
        {
            _context = context;
        }

        // ✅ GET: api/Order/status-options - Return status menu options
        [HttpGet("status-options")]
        [AllowAnonymous]
        public ActionResult<object> GetStatusOptions()
        {
            var statusOptions = new[]
            {
                new {
                    value = "Pending",
                    label = "Chờ xử lý",
                    color = "#FFA726",
                    icon = "pending",
                    description = "Đơn hàng mới tạo, chờ xử lý"
                },
                new {
                    value = "Processing",
                    label = "Đang xử lý",
                    color = "#42A5F5",
                    icon = "processing",
                    description = "Đang chuẩn bị món ăn"
                },
                new {
                    value = "Delivered",
                    label = "Đã giao",
                    color = "#66BB6A",
                    icon = "delivered",
                    description = "Đã giao thành công"
                },
                new {
                    value = "Cancelled",
                    label = "Đã hủy",
                    color = "#EF5350",
                    icon = "cancelled",
                    description = "Đơn hàng đã bị hủy"
                }
            };

            return Ok(new { statusOptions });
        }

        // GET: api/Order
        [HttpGet]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<OrderDTO>>> GetOrders()
        {
            try
            {
                var orders = await _context.Orders
                    .Include(o => o.OrderDetails)
                    .ThenInclude(od => od.Food)
                    .Include(o => o.Promotion)
                    .OrderByDescending(o => o.OrderDate)
                    .ToListAsync();

                var result = orders.Select(order => new OrderDTO
                {
                    Id = order.Id,
                    UserId = order.UserId,
                    OrderDate = order.OrderDate,
                    TotalAmount = order.TotalAmount,
                    Status = order.Status,
                    Address = order.Address,
                    PromotionId = order.PromotionId,
                    PromotionCode = order.Promotion?.Code,
                    TotalItems = order.OrderDetails?.Sum(od => od.Quantity) ?? 0,
                    OrderDetails = order.OrderDetails?.Select(od => new OrderDetailDTO
                    {
                        FoodId = od.FoodId,
                        FoodName = od.Food?.Name ?? "",
                        FoodImageUrl = od.Food?.ImageUrl,
                        Quantity = od.Quantity,
                        UnitPrice = od.UnitPrice
                    }).ToList() ?? new List<OrderDetailDTO>()
                }).ToList();

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving orders", details = ex.Message });
            }
        }

        // GET: api/Order/5
        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<ActionResult<OrderDTO>> GetOrder(int id)
        {
            try
            {
                var order = await _context.Orders
                    .Include(o => o.OrderDetails)
                    .ThenInclude(od => od.Food)
                    .Include(o => o.Promotion)
                    .FirstOrDefaultAsync(o => o.Id == id);

                if (order == null)
                {
                    return NotFound(new { message = "Order not found" });
                }

                var orderDto = new OrderDTO
                {
                    Id = order.Id,
                    UserId = order.UserId,
                    OrderDate = order.OrderDate,
                    TotalAmount = order.TotalAmount,
                    Status = order.Status,
                    Address = order.Address,
                    PromotionId = order.PromotionId,
                    PromotionCode = order.Promotion?.Code,
                    TotalItems = order.OrderDetails?.Sum(od => od.Quantity) ?? 0,
                    OrderDetails = order.OrderDetails?.Select(od => new OrderDetailDTO
                    {
                        FoodId = od.FoodId,
                        FoodName = od.Food?.Name ?? "",
                        FoodImageUrl = od.Food?.ImageUrl,
                        Quantity = od.Quantity,
                        UnitPrice = od.UnitPrice
                    }).ToList() ?? new List<OrderDetailDTO>()
                };

                return Ok(orderDto);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving order", details = ex.Message });
            }
        }

        // ✅ FIXED: PUT: api/Order/5/status - Update order status with validation
        [HttpPut("{id}/status")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateOrderStatus(int id, [FromBody] OrderStatusUpdateDTO dto)
        {
            try
            {
                Console.WriteLine($"🔄 Updating order {id} status to '{dto.Status}'");

                // ✅ Define exact status values matching database constraint
                var validStatuses = new[] { "Pending", "Processing", "Delivered", "Cancelled" };

                // ✅ Validate status first
                if (string.IsNullOrEmpty(dto.Status))
                {
                    Console.WriteLine($"❌ Empty status received");
                    return BadRequest(new
                    {
                        message = "Status is required",
                        validStatuses = validStatuses
                    });
                }

                if (!validStatuses.Contains(dto.Status))
                {
                    Console.WriteLine($"❌ Invalid status: '{dto.Status}'. Valid values: {string.Join(", ", validStatuses)}");
                    return BadRequest(new
                    {
                        message = $"Invalid status: '{dto.Status}'",
                        validStatuses = validStatuses,
                        receivedStatus = dto.Status
                    });
                }

                // ✅ Check if order exists
                var orderExists = await _context.Orders.AnyAsync(o => o.Id == id);
                if (!orderExists)
                {
                    Console.WriteLine($"❌ Order {id} not found");
                    return NotFound(new { message = "Order not found" });
                }

                // ✅ Use direct SQL update to avoid EF tracking issues
                var sql = "UPDATE Orders SET Status = {0} WHERE Id = {1}";
                var rowsAffected = await _context.Database.ExecuteSqlRawAsync(sql, dto.Status, id);

                if (rowsAffected == 0)
                {
                    Console.WriteLine($"❌ No rows updated for order {id}");
                    return NotFound(new { message = "Order not found or no changes made" });
                }

                Console.WriteLine($"✅ Successfully updated order {id} status to '{dto.Status}'. Rows affected: {rowsAffected}");
                return NoContent();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Error updating order {id} status: {ex.Message}");
                Console.WriteLine($"❌ Inner exception: {ex.InnerException?.Message}");

                return StatusCode(500, new
                {
                    message = "Error updating order status",
                    details = ex.Message,
                    innerException = ex.InnerException?.Message,
                    receivedStatus = dto.Status
                });
            }
        }

        // GET: api/Order/user/{userId}
        [HttpGet("user/{userId}")]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<OrderDTO>>> GetOrdersByUser(int userId)
        {
            try
            {
                var orders = await _context.Orders
                    .Where(o => o.UserId == userId)
                    .Include(o => o.OrderDetails)
                    .ThenInclude(od => od.Food)
                    .Include(o => o.Promotion)
                    .OrderByDescending(o => o.OrderDate)
                    .ToListAsync();

                var result = orders.Select(order => new OrderDTO
                {
                    Id = order.Id,
                    UserId = order.UserId,
                    OrderDate = order.OrderDate,
                    TotalAmount = order.TotalAmount,
                    Status = order.Status,
                    Address = order.Address,
                    PromotionId = order.PromotionId,
                    PromotionCode = order.Promotion?.Code,
                    TotalItems = order.OrderDetails?.Sum(od => od.Quantity) ?? 0,
                    OrderDetails = order.OrderDetails?.Select(od => new OrderDetailDTO
                    {
                        FoodId = od.FoodId,
                        FoodName = od.Food?.Name ?? "",
                        FoodImageUrl = od.Food?.ImageUrl,
                        Quantity = od.Quantity,
                        UnitPrice = od.UnitPrice
                    }).ToList() ?? new List<OrderDetailDTO>()
                }).ToList();

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving user orders", details = ex.Message });
            }
        }

        // POST: api/Order
        [HttpPost]
        [AllowAnonymous]
        public async Task<ActionResult<OrderDTO>> PostOrder([FromBody] OrderCreateDTO dto)
        {
            try
            {
                var user = await _context.Users.FindAsync(dto.UserId);
                if (user == null)
                    return BadRequest(new { message = "User not found" });

                if (dto.OrderDetails == null || !dto.OrderDetails.Any())
                    return BadRequest(new { message = "Order must have at least one item" });

                // ✅ Ensure status is valid
                var finalStatus = "Pending"; // Default
                if (!string.IsNullOrEmpty(dto.Status))
                {
                    var validStatuses = new[] { "Pending", "Processing", "Delivered", "Cancelled" };
                    if (validStatuses.Contains(dto.Status))
                    {
                        finalStatus = dto.Status;
                    }
                }

                var order = new Order
                {
                    UserId = dto.UserId,
                    Address = dto.Address ?? "",
                    TotalAmount = dto.TotalAmount,
                    Status = finalStatus,
                    OrderDate = DateTime.Now,
                    PromotionId = dto.PromotionId,
                    OrderDetails = dto.OrderDetails?.Select(od => new OrderDetail
                    {
                        FoodId = od.FoodId,
                        Quantity = od.Quantity,
                        UnitPrice = od.UnitPrice
                    }).ToList() ?? new List<OrderDetail>()
                };

                _context.Orders.Add(order);
                await _context.SaveChangesAsync();

                var createdOrder = await _context.Orders
                    .Include(o => o.OrderDetails)
                    .ThenInclude(od => od.Food)
                    .Include(o => o.Promotion)
                    .FirstOrDefaultAsync(o => o.Id == order.Id);

                if (createdOrder == null)
                {
                    return StatusCode(500, new { message = "Order created but could not retrieve details" });
                }

                var orderDto = new OrderDTO
                {
                    Id = createdOrder.Id,
                    UserId = createdOrder.UserId,
                    OrderDate = createdOrder.OrderDate,
                    TotalAmount = createdOrder.TotalAmount,
                    Status = createdOrder.Status,
                    Address = createdOrder.Address,
                    PromotionId = createdOrder.PromotionId,
                    PromotionCode = createdOrder.Promotion?.Code,
                    TotalItems = createdOrder.OrderDetails?.Sum(od => od.Quantity) ?? 0,
                    OrderDetails = createdOrder.OrderDetails?.Select(od => new OrderDetailDTO
                    {
                        FoodId = od.FoodId,
                        FoodName = od.Food?.Name ?? "",
                        FoodImageUrl = od.Food?.ImageUrl,
                        Quantity = od.Quantity,
                        UnitPrice = od.UnitPrice
                    }).ToList() ?? new List<OrderDetailDTO>()
                };

                return CreatedAtAction("GetOrder", new { id = order.Id }, orderDto);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error creating order", details = ex.Message });
            }
        }

        // PUT: api/Order/5
        [HttpPut("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> PutOrder(int id, [FromBody] OrderUpdateDTO dto)
        {
            try
            {
                var order = await _context.Orders.FindAsync(id);
                if (order == null)
                {
                    return NotFound(new { message = "Order not found" });
                }

                if (!string.IsNullOrEmpty(dto.Status))
                {
                    var validStatuses = new[] { "Pending", "Processing", "Delivered", "Cancelled" };
                    if (validStatuses.Contains(dto.Status))
                    {
                        order.Status = dto.Status;
                    }
                }

                if (!string.IsNullOrEmpty(dto.Address))
                    order.Address = dto.Address;

                if (dto.TotalAmount.HasValue)
                    order.TotalAmount = dto.TotalAmount.Value;

                if (dto.PromotionId.HasValue)
                    order.PromotionId = dto.PromotionId;

                _context.Entry(order).State = EntityState.Modified;
                await _context.SaveChangesAsync();

                return NoContent();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!OrderExists(id))
                {
                    return NotFound(new { message = "Order not found" });
                }
                else
                {
                    throw;
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error updating order", details = ex.Message });
            }
        }

        // DELETE: api/Order/5
        [HttpDelete("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> DeleteOrder(int id)
        {
            try
            {
                var order = await _context.Orders
                    .Include(o => o.OrderDetails)
                    .FirstOrDefaultAsync(o => o.Id == id);

                if (order == null)
                {
                    return NotFound(new { message = "Order not found" });
                }

                _context.Orders.Remove(order);
                await _context.SaveChangesAsync();

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error deleting order", details = ex.Message });
            }
        }

        // GET: api/Order/status/{status}
        [HttpGet("status/{status}")]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<OrderDTO>>> GetOrdersByStatus(string status)
        {
            try
            {
                var orders = await _context.Orders
                    .Where(o => o.Status == status)
                    .Include(o => o.OrderDetails)
                    .ThenInclude(od => od.Food)
                    .Include(o => o.Promotion)
                    .OrderByDescending(o => o.OrderDate)
                    .ToListAsync();

                var result = orders.Select(order => new OrderDTO
                {
                    Id = order.Id,
                    UserId = order.UserId,
                    OrderDate = order.OrderDate,
                    TotalAmount = order.TotalAmount,
                    Status = order.Status,
                    Address = order.Address,
                    PromotionId = order.PromotionId,
                    PromotionCode = order.Promotion?.Code,
                    TotalItems = order.OrderDetails?.Sum(od => od.Quantity) ?? 0,
                    OrderDetails = order.OrderDetails?.Select(od => new OrderDetailDTO
                    {
                        FoodId = od.FoodId,
                        FoodName = od.Food?.Name ?? "",
                        FoodImageUrl = od.Food?.ImageUrl,
                        Quantity = od.Quantity,
                        UnitPrice = od.UnitPrice
                    }).ToList() ?? new List<OrderDetailDTO>()
                }).ToList();

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving orders by status", details = ex.Message });
            }
        }

        private bool OrderExists(int id)
        {
            return _context.Orders.Any(e => e.Id == id);
        }
    }

    // ✅ DTOs
    public class OrderStatusUpdateDTO
    {
        public string Status { get; set; } = string.Empty;
    }

    public class OrderUpdateDTO
    {
        public string? Status { get; set; }
        public string? Address { get; set; }
        public decimal? TotalAmount { get; set; }
        public int? PromotionId { get; set; }
    }

    public class OrderDTO
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public DateTime OrderDate { get; set; }
        public decimal TotalAmount { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? Address { get; set; }
        public int? PromotionId { get; set; }
        public string? PromotionCode { get; set; }
        public int TotalItems { get; set; }
        public List<OrderDetailDTO> OrderDetails { get; set; } = new();
    }

    public class OrderDetailDTO
    {
        public int FoodId { get; set; }
        public string FoodName { get; set; } = string.Empty;
        public string? FoodImageUrl { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
    }

    public class OrderCreateDTO
    {
        public int UserId { get; set; }
        public string? Address { get; set; }
        public decimal TotalAmount { get; set; }
        public string? Status { get; set; }
        public int? PromotionId { get; set; }
        public List<OrderDetailCreateDTO>? OrderDetails { get; set; }
    }

    public class OrderDetailCreateDTO
    {
        public int FoodId { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
    }
}