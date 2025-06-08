import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController? controller; // Để quản lý text trong ô tìm kiếm
  final ValueChanged<String> onChanged;   // Hàm callback khi text thay đổi
  final VoidCallback? onClear;            // Hàm callback khi nhấn nút xóa (tùy chọn)

  const SearchBarWidget({
    super.key,
    this.controller,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12), // Màu nền của thanh tìm kiếm
        borderRadius: BorderRadius.circular(18), // Bo góc
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white), // Màu chữ khi nhập
        decoration: InputDecoration(
          hintText: 'Tìm kiếm món ăn...', // Chữ gợi ý
          hintStyle: const TextStyle(color: Colors.white54), // Màu chữ gợi ý
          prefixIcon: const Icon(Icons.search, color: Colors.white), // Icon tìm kiếm ở đầu
          suffixIcon: (controller != null && controller!.text.isNotEmpty && onClear != null)
              ? IconButton( // Icon xóa ở cuối (chỉ hiện khi có text và có hàm onClear)
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none, // Bỏ đường viền mặc định của TextField
          contentPadding: const EdgeInsets.symmetric(vertical: 14), // Padding bên trong
        ),
        onChanged: onChanged, // Gọi hàm callback khi người dùng nhập liệu
      ),
    );
  }
}