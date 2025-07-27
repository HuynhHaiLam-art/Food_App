using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebFoodAPI.Models;

namespace WebFoodAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FoodController : ControllerBase
    {
        private readonly DbappFoodContext _context;

        public FoodController(DbappFoodContext context)
        {
            _context = context;
        }

        // Map Food -> FoodDTO
        private FoodDTO ToDTO(Food food) => new FoodDTO
        {
            Id = food.Id,
            Name = food.Name,
            Description = food.Description,
            Price = food.Price,
            ImageUrl = food.ImageUrl,
            CategoryId = food.CategoryId,
            CategoryName = food.Category?.Name
        };

        // Map FoodDTO -> Food
        private Food ToEntity(FoodDTO dto) => new Food
        {
            Id = dto.Id,
            Name = dto.Name,
            Description = dto.Description,
            Price = dto.Price,
            ImageUrl = dto.ImageUrl,
            CategoryId = dto.CategoryId
        };

        // Kiểm tra tồn tại Food theo Id
        private bool FoodExists(int id) =>
            _context.Foods.Any(e => e.Id == id);

        // Kiểm tra tồn tại Category theo Id
        private bool CategoryExists(int categoryId) =>
            _context.Categories.Any(c => c.Id == categoryId);

        // GET: api/Food
        [HttpGet]
        public async Task<ActionResult<IEnumerable<FoodDTO>>> GetFoods()
        {
            var foods = await _context.Foods
                .Include(f => f.Category)
                .AsNoTracking()
                .ToListAsync();

            return foods.Select(f => ToDTO(f)).ToList();
        }

        // GET: api/Food/5
        [HttpGet("{id}")]
        public async Task<ActionResult<FoodDTO>> GetFood(int id)
        {
            var food = await _context.Foods
                .Include(f => f.Category)
                .AsNoTracking()
                .FirstOrDefaultAsync(f => f.Id == id);

            if (food == null)
                return NotFound();

            return ToDTO(food);
        }

        // PUT: api/Food/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutFood(int id, FoodDTO foodDTO)
        {
            if (id != foodDTO.Id)
                return BadRequest("Id không khớp.");

            if (!CategoryExists(foodDTO.CategoryId))
                return BadRequest("CategoryId không tồn tại.");

            var food = await _context.Foods.FindAsync(id);
            if (food == null)
                return NotFound();

            // Cập nhật từng trường
            food.Name = foodDTO.Name;
            food.Description = foodDTO.Description;
            food.Price = foodDTO.Price;
            food.ImageUrl = foodDTO.ImageUrl;
            food.CategoryId = foodDTO.CategoryId;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!FoodExists(id))
                    return NotFound();
                else
                    throw;
            }

            return NoContent();
        }

        // POST: api/Food
        [HttpPost]
        public async Task<ActionResult<FoodDTO>> PostFood(FoodDTO foodDTO)
        {
            if (!CategoryExists(foodDTO.CategoryId))
                return BadRequest("CategoryId không tồn tại.");

            var food = ToEntity(foodDTO);
            food.Id = 0; // EF tự tạo Id khi thêm mới

            _context.Foods.Add(food);
            await _context.SaveChangesAsync();

            // Tải lại entity kèm Category để trả về DTO đầy đủ
            await _context.Entry(food).Reference(f => f.Category).LoadAsync();

            return CreatedAtAction(nameof(GetFood), new { id = food.Id }, ToDTO(food));
        }

        // DELETE: api/Food/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteFood(int id)
        {
            var food = await _context.Foods.FindAsync(id);
            if (food == null)
                return NotFound();

            _context.Foods.Remove(food);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
}
