namespace WebFoodAPI.Models
{
    public class UserDTO
    {
        public required int Id { get; set; }
        public required string Name { get; set; }
        public required string Email { get; set; }
        public required string Role { get; set; }
    }

    public class UserCreateDTO
    {
        public required string Name { get; set; }
        public required string Email { get; set; }
        public required string Password { get; set; }
        public string Role { get; set; } = "User";
    }

    public class UserUpdateDTO
    {
        public string Name { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string Role { get; set; } = null!;
        public string? OldPassword { get; set; }
        public string? NewPassword { get; set; }
    }
}
