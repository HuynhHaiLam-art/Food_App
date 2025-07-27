using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebFoodAPI.Models;

namespace WebFoodAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PromotionController : ControllerBase
    {
        private readonly DbappFoodContext _context;

        public PromotionController(DbappFoodContext context)
        {
            _context = context;
        }

        // GET: api/Promotion
        [HttpGet]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<PromotionDTO>>> GetPromotions()
        {
            try
            {
                var promotions = await _context.Promotions.ToListAsync();
                var promotionDTOs = promotions.Select(p => new PromotionDTO
                {
                    Id = p.Id,
                    Code = p.Code,
                    Description = p.Description,
                    DiscountPercent = p.DiscountPercent,
                    StartDate = p.StartDate,
                    EndDate = p.EndDate
                }).ToList();

                return Ok(promotionDTOs);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving promotions", details = ex.Message });
            }
        }

        // GET: api/Promotion/5
        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<ActionResult<PromotionDTO>> GetPromotion(int id)
        {
            try
            {
                var promotion = await _context.Promotions.FindAsync(id);

                if (promotion == null)
                {
                    return NotFound(new { message = "Promotion not found" });
                }

                var promotionDTO = new PromotionDTO
                {
                    Id = promotion.Id,
                    Code = promotion.Code,
                    Description = promotion.Description,
                    DiscountPercent = promotion.DiscountPercent,
                    StartDate = promotion.StartDate,
                    EndDate = promotion.EndDate
                };

                return Ok(promotionDTO);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving promotion", details = ex.Message });
            }
        }

        // POST: api/Promotion
        [HttpPost]
        [AllowAnonymous]
        public async Task<ActionResult<PromotionDTO>> PostPromotion([FromBody] PromotionCreateDTO promotionDto)
        {
            try
            {
                // ✅ Validate input
                if (string.IsNullOrEmpty(promotionDto.Code))
                {
                    return BadRequest(new { message = "Promotion code is required" });
                }

                // ✅ Check for duplicate codes
                if (await _context.Promotions.AnyAsync(p => p.Code == promotionDto.Code))
                {
                    return BadRequest(new { message = "Promotion code already exists" });
                }

                // ✅ Validate dates
                if (promotionDto.StartDate.HasValue && promotionDto.EndDate.HasValue &&
                    promotionDto.StartDate.Value > promotionDto.EndDate.Value)
                {
                    return BadRequest(new { message = "Start date cannot be later than end date" });
                }

                // ✅ Validate discount percent
                if (promotionDto.DiscountPercent.HasValue &&
                    (promotionDto.DiscountPercent.Value < 0 || promotionDto.DiscountPercent.Value > 100))
                {
                    return BadRequest(new { message = "Discount percent must be between 0 and 100" });
                }

                var promotion = new Promotion
                {
                    Code = promotionDto.Code,
                    Description = promotionDto.Description,
                    DiscountPercent = promotionDto.DiscountPercent,
                    StartDate = promotionDto.StartDate ?? DateTime.Now,
                    EndDate = promotionDto.EndDate ?? DateTime.Now.AddDays(30) // Default 30 days if not provided
                };

                _context.Promotions.Add(promotion);
                await _context.SaveChangesAsync();

                var createdPromotionDTO = new PromotionDTO
                {
                    Id = promotion.Id,
                    Code = promotion.Code,
                    Description = promotion.Description,
                    DiscountPercent = promotion.DiscountPercent,
                    StartDate = promotion.StartDate,
                    EndDate = promotion.EndDate
                };

                return CreatedAtAction("GetPromotion", new { id = promotion.Id }, createdPromotionDTO);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error creating promotion", details = ex.Message });
            }
        }

        // PUT: api/Promotion/5
        [HttpPut("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> PutPromotion(int id, [FromBody] PromotionUpdateDTO promotionDto)
        {
            try
            {
                var promotion = await _context.Promotions.FindAsync(id);
                if (promotion == null)
                {
                    return NotFound(new { message = "Promotion not found" });
                }

                // ✅ Check for duplicate codes (excluding current promotion)
                if (!string.IsNullOrEmpty(promotionDto.Code) && promotionDto.Code != promotion.Code)
                {
                    if (await _context.Promotions.AnyAsync(p => p.Code == promotionDto.Code && p.Id != id))
                    {
                        return BadRequest(new { message = "Promotion code already exists" });
                    }
                }

                // ✅ Validate dates if both are provided
                if (promotionDto.StartDate.HasValue && promotionDto.EndDate.HasValue &&
                    promotionDto.StartDate.Value > promotionDto.EndDate.Value)
                {
                    return BadRequest(new { message = "Start date cannot be later than end date" });
                }

                // ✅ Validate discount percent
                if (promotionDto.DiscountPercent.HasValue &&
                    (promotionDto.DiscountPercent.Value < 0 || promotionDto.DiscountPercent.Value > 100))
                {
                    return BadRequest(new { message = "Discount percent must be between 0 and 100" });
                }

                // ✅ Update fields only if provided
                if (!string.IsNullOrEmpty(promotionDto.Code))
                    promotion.Code = promotionDto.Code;

                if (!string.IsNullOrEmpty(promotionDto.Description))
                    promotion.Description = promotionDto.Description;

                if (promotionDto.DiscountPercent.HasValue)
                    promotion.DiscountPercent = promotionDto.DiscountPercent.Value;

                if (promotionDto.StartDate.HasValue)
                    promotion.StartDate = promotionDto.StartDate.Value;

                if (promotionDto.EndDate.HasValue)
                    promotion.EndDate = promotionDto.EndDate.Value;

                _context.Entry(promotion).State = EntityState.Modified;
                await _context.SaveChangesAsync();

                return NoContent();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!PromotionExists(id))
                {
                    return NotFound(new { message = "Promotion not found" });
                }
                else
                {
                    throw;
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error updating promotion", details = ex.Message });
            }
        }

        // DELETE: api/Promotion/5
        [HttpDelete("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> DeletePromotion(int id)
        {
            try
            {
                var promotion = await _context.Promotions.FindAsync(id);
                if (promotion == null)
                {
                    return NotFound(new { message = "Promotion not found" });
                }

                // ✅ Check if promotion is being used in any orders
                var isUsedInOrders = await _context.Orders.AnyAsync(o => o.PromotionId == id);
                if (isUsedInOrders)
                {
                    return BadRequest(new { message = "Cannot delete promotion as it is being used in orders. Consider updating the end date instead." });
                }

                _context.Promotions.Remove(promotion);
                await _context.SaveChangesAsync();

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error deleting promotion", details = ex.Message });
            }
        }

        // GET: api/Promotion/validate/{code}
        [HttpGet("validate/{code}")]
        [AllowAnonymous]
        public async Task<ActionResult<object>> ValidatePromotionCode(string code)
        {
            try
            {
                var promotion = await _context.Promotions
                    .FirstOrDefaultAsync(p => p.Code == code);

                if (promotion == null)
                {
                    return NotFound(new { message = "Promotion code not found" });
                }

                var now = DateTime.Now;

                // Check if promotion is within valid date range
                if (promotion.StartDate > now)
                {
                    return BadRequest(new { message = "Promotion code is not yet active" });
                }

                if (promotion.EndDate < now)
                {
                    return BadRequest(new { message = "Promotion code has expired" });
                }

                var promotionDTO = new PromotionDTO
                {
                    Id = promotion.Id,
                    Code = promotion.Code,
                    Description = promotion.Description,
                    DiscountPercent = promotion.DiscountPercent,
                    StartDate = promotion.StartDate,
                    EndDate = promotion.EndDate
                };

                return Ok(new { valid = true, promotion = promotionDTO });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error validating promotion code", details = ex.Message });
            }
        }

        // GET: api/Promotion/active
        [HttpGet("active")]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<PromotionDTO>>> GetActivePromotions()
        {
            try
            {
                var now = DateTime.Now;
                var activePromotions = await _context.Promotions
                    .Where(p => p.StartDate <= now && p.EndDate >= now)
                    .ToListAsync();

                var promotionDTOs = activePromotions.Select(p => new PromotionDTO
                {
                    Id = p.Id,
                    Code = p.Code,
                    Description = p.Description,
                    DiscountPercent = p.DiscountPercent,
                    StartDate = p.StartDate,
                    EndDate = p.EndDate
                }).ToList();

                return Ok(promotionDTOs);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving active promotions", details = ex.Message });
            }
        }

        private bool PromotionExists(int id)
        {
            return _context.Promotions.Any(e => e.Id == id);
        }
    }

    // ✅ DTOs matching actual Promotion model
    public class PromotionCreateDTO
    {
        public string Code { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? DiscountPercent { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }

    public class PromotionUpdateDTO
    {
        public string? Code { get; set; }
        public string? Description { get; set; }
        public int? DiscountPercent { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }
}