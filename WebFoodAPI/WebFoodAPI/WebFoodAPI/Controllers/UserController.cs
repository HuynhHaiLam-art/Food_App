using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using WebFoodAPI.Models;
using MailKit.Net.Smtp;
using MimeKit;

namespace WebFoodAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserController : ControllerBase
    {
        private readonly DbappFoodContext _context;
        private readonly IConfiguration _configuration;

        // In-memory storage for reset codes (in production, use Redis or database)
        private static readonly Dictionary<string, ResetCodeInfo> _resetCodes = new();

        public UserController(DbappFoodContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        // Helper: Lấy userId từ token (ưu tiên claim là số)
        private int? GetUserIdFromClaims()
        {
            var nameIdClaims = User.Claims
                .Where(c => c.Type == ClaimTypes.NameIdentifier)
                .Select(c => c.Value)
                .ToList();

            string? userIdString = nameIdClaims.FirstOrDefault(v => int.TryParse(v, out _));
            userIdString ??= User.FindFirstValue("nameid");

            if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
            {
                foreach (var claim in User.Claims)
                {
                    Console.WriteLine($"{claim.Type}: {claim.Value}");
                }
                return null;
            }
            return userId;
        }

        // GET: api/User
        [HttpGet]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<UserDTO>>> GetUsers()
        {
            try
            {
                var users = await _context.Users.ToListAsync();
                var usersDto = users.Select(u => UserToDto(u)).ToList();
                return Ok(usersDto);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving users", details = ex.Message });
            }
        }

        // GET: api/User/me
        [HttpGet("me")]
        [Authorize]
        public async Task<ActionResult<UserDTO>> GetCurrentUser()
        {
            var userId = GetUserIdFromClaims();
            if (userId == null)
            {
                return Unauthorized(new { message = "Token không hợp lệ hoặc thiếu thông tin người dùng." });
            }

            var user = await _context.Users.FindAsync(userId.Value);
            if (user == null)
            {
                return NotFound(new { message = "Người dùng không tồn tại." });
            }
            return UserToDto(user);
        }

        // GET: api/User/5
        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<ActionResult<UserDTO>> GetUser(int id)
        {
            try
            {
                var user = await _context.Users.FindAsync(id);
                if (user == null)
                    return NotFound(new { message = "User not found" });

                return Ok(UserToDto(user));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving user", details = ex.Message });
            }
        }

        // POST: api/User
        [HttpPost]
        [AllowAnonymous]
        public async Task<ActionResult<UserDTO>> PostUser(UserCreateDTO userCreateDto)
        {
            try
            {
                if (string.IsNullOrEmpty(userCreateDto.Name) || string.IsNullOrEmpty(userCreateDto.Email) || string.IsNullOrEmpty(userCreateDto.Password))
                {
                    return BadRequest(new { message = "Name, Email và Password là bắt buộc." });
                }

                if (await _context.Users.AnyAsync(u => u.Email == userCreateDto.Email))
                    return BadRequest(new { message = "Email đã tồn tại." });

                var user = new User
                {
                    Name = userCreateDto.Name,
                    Email = userCreateDto.Email,
                    Role = string.IsNullOrEmpty(userCreateDto.Role) ? "User" : userCreateDto.Role,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(userCreateDto.Password)
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                var userDto = UserToDto(user);
                return CreatedAtAction(nameof(GetUser), new { id = user.Id }, userDto);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error creating user", details = ex.Message });
            }
        }

        // POST: api/User/register
        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<ActionResult<object>> Register([FromBody] UserCreateDTO userCreateDto)
        {
            try
            {
                if (await _context.Users.AnyAsync(u => u.Email == userCreateDto.Email))
                    return BadRequest(new { message = "Email đã tồn tại." });

                var user = new User
                {
                    Name = userCreateDto.Name,
                    Email = userCreateDto.Email,
                    Role = "User",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(userCreateDto.Password)
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                var tokenString = GenerateJwtToken(user);
                return Ok(new
                {
                    token = tokenString,
                    expiresIn = 3600,
                    user = UserToDto(user)
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error during registration", details = ex.Message });
            }
        }

        // POST: api/User/login
        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<ActionResult<object>> Login([FromBody] LoginDTO loginDto)
        {
            try
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == loginDto.Email);
                if (user == null)
                    return Unauthorized(new { message = "Email không tồn tại!" });

                if (!BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash))
                    return Unauthorized(new { message = "Sai mật khẩu!" });

                var tokenString = GenerateJwtToken(user);
                var expiresInSeconds = 3600;

                return Ok(new
                {
                    token = tokenString,
                    expiresIn = expiresInSeconds,
                    user = UserToDto(user)
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error during login", details = ex.Message });
            }
        }

        // POST: api/User/forgot-password
        [HttpPost("forgot-password")]
        [AllowAnonymous]
        public async Task<ActionResult<object>> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            try
            {
                if (string.IsNullOrEmpty(request.Email))
                {
                    return BadRequest(new { message = "Email là bắt buộc" });
                }

                var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
                if (user == null)
                {
                    return BadRequest(new { message = "Email không tồn tại trong hệ thống" });
                }

                var resetCode = new Random().Next(100000, 999999).ToString();

                var resetCodeInfo = new ResetCodeInfo
                {
                    Code = resetCode,
                    Email = request.Email,
                    ExpiresAt = DateTime.UtcNow.AddMinutes(10)
                };

                _resetCodes[request.Email] = resetCodeInfo;
                CleanupExpiredCodes();

                // Gửi email thực tế
                await SendResetCodeEmail(user.Email, resetCode, user.Name);

                return Ok(new
                {
                    message = "Mã xác nhận đã được gửi đến email của bạn",
                    email = request.Email
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi server: " + ex.Message });
            }
        }

        // Hàm gửi email xác nhận qua Gmail
        private async Task SendResetCodeEmail(string toEmail, string code, string userName)
        {
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress("King Burger", "taicm102@gmail.com")); // Thay bằng Gmail của bạn
            message.To.Add(new MailboxAddress(userName ?? "", toEmail));
            message.Subject = "Mã xác nhận khôi phục mật khẩu";

            message.Body = new TextPart("plain")
            {
                Text = $"Xin chào {userName},\n\nMã xác nhận của bạn là: {code}\n\nMã này có hiệu lực trong 10 phút.\n\nKing Burger"
            };

            // ...existing code...
            using var client = new SmtpClient();
            await client.ConnectAsync("smtp.gmail.com", 587, MailKit.Security.SecureSocketOptions.StartTls);
            await client.AuthenticateAsync("taicm102@gmail.com", "cste ahhc jzwc qzlt"); // Thay bằng Gmail và mật khẩu ứng dụng
            await client.SendAsync(message);
            await client.DisconnectAsync(true);
            // ...existing code...
        }

        // POST: api/User/verify-reset-code
        [HttpPost("verify-reset-code")]
        [AllowAnonymous]
        public async Task<ActionResult<object>> VerifyResetCode([FromBody] VerifyResetCodeRequest request)
        {
            try
            {
                if (string.IsNullOrEmpty(request.Email) || string.IsNullOrEmpty(request.Code))
                {
                    return BadRequest(new { message = "Email và mã xác nhận là bắt buộc" });
                }

                if (request.Code.Length != 6 || !request.Code.All(char.IsDigit))
                {
                    return BadRequest(new { message = "Mã xác nhận phải là 6 chữ số" });
                }

                if (!_resetCodes.TryGetValue(request.Email, out var resetCodeInfo))
                {
                    return BadRequest(new { message = "Mã xác nhận không tồn tại hoặc đã hết hạn" });
                }

                if (resetCodeInfo.ExpiresAt < DateTime.UtcNow)
                {
                    _resetCodes.Remove(request.Email);
                    return BadRequest(new { message = "Mã xác nhận đã hết hạn" });
                }

                if (resetCodeInfo.Code != request.Code)
                {
                    return BadRequest(new { message = "Mã xác nhận không đúng" });
                }

                var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
                if (user == null)
                {
                    return BadRequest(new { message = "Email không tồn tại" });
                }

                user.PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456789");
                await _context.SaveChangesAsync();

                _resetCodes.Remove(request.Email);

                return Ok(new
                {
                    message = "Mật khẩu đã được reset thành công! Mật khẩu mới của bạn là: 123456789"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi server: " + ex.Message });
            }
        }

        private void CleanupExpiredCodes()
        {
            var expiredEmails = _resetCodes
                .Where(kvp => kvp.Value.ExpiresAt < DateTime.UtcNow)
                .Select(kvp => kvp.Key)
                .ToList();

            foreach (var email in expiredEmails)
            {
                _resetCodes.Remove(email);
            }
        }

        private string GenerateJwtToken(User user)
        {
            var jwtKey = _configuration["Jwt:Key"];
            if (string.IsNullOrEmpty(jwtKey) || jwtKey.Length < 16)
            {
                throw new InvalidOperationException("Khóa JWT không được cấu hình hoặc quá ngắn (cần ít nhất 16 ký tự).");
            }
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Email),
                new Claim(JwtRegisteredClaimNames.NameId, user.Id.ToString()),
                new Claim("name", user.Name ?? string.Empty),
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.NameIdentifier, user.Email ?? string.Empty),
                new Claim(ClaimTypes.Role, user.Role ?? "User"),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddHours(1),
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        // PUT: api/User/5
        [HttpPut("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> PutUser(int id, UserUpdateDTO userUpdateDto)
        {
            try
            {
                var user = await _context.Users.FindAsync(id);
                if (user == null)
                    return NotFound(new { message = "Người dùng không tồn tại." });

                if (!string.IsNullOrEmpty(userUpdateDto.Email) && user.Email != userUpdateDto.Email)
                {
                    if (await _context.Users.AnyAsync(u => u.Email == userUpdateDto.Email && u.Id != id))
                    {
                        return BadRequest(new { message = "Email mới đã được sử dụng bởi tài khoản khác." });
                    }
                }

                if (!string.IsNullOrEmpty(userUpdateDto.Name))
                {
                    user.Name = userUpdateDto.Name;
                }
                if (!string.IsNullOrEmpty(userUpdateDto.Email))
                {
                    user.Email = userUpdateDto.Email;
                }
                if (!string.IsNullOrEmpty(userUpdateDto.Role))
                {
                    user.Role = userUpdateDto.Role;
                }

                if (!string.IsNullOrEmpty(userUpdateDto.NewPassword))
                {
                    if (string.IsNullOrEmpty(userUpdateDto.OldPassword))
                    {
                        return BadRequest(new { message = "Cần cung cấp mật khẩu cũ để đổi mật khẩu mới." });
                    }
                    if (!BCrypt.Net.BCrypt.Verify(userUpdateDto.OldPassword, user.PasswordHash))
                        return BadRequest(new { message = "Mật khẩu cũ không đúng!" });

                    user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(userUpdateDto.NewPassword);
                }

                _context.Entry(user).State = EntityState.Modified;
                await _context.SaveChangesAsync();

                return NoContent();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!UserExists(id))
                    return NotFound();
                else
                    throw;
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Đã xảy ra lỗi khi cập nhật thông tin người dùng.", details = ex.Message });
            }
        }

        // DELETE: api/User/5
        [HttpDelete("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> DeleteUser(int id)
        {
            try
            {
                var user = await _context.Users.FindAsync(id);
                if (user == null)
                    return NotFound(new { message = "Người dùng không tồn tại." });

                _context.Users.Remove(user);
                await _context.SaveChangesAsync();

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error deleting user", details = ex.Message });
            }
        }

        private bool UserExists(int id) =>
            _context.Users.Any(e => e.Id == id);

        private static UserDTO UserToDto(User user) =>
            new UserDTO
            {
                Id = user.Id,
                Name = user.Name,
                Email = user.Email,
                Role = user.Role
            };
    }

    public class ForgotPasswordRequest
    {
        public string Email { get; set; } = string.Empty;
    }

    public class VerifyResetCodeRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
    }

    public class ResetCodeInfo
    {
        public string Code { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
    }
}