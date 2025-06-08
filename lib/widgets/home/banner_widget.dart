import 'package:flutter/material.dart';

class BannerWidget extends StatelessWidget {
  const BannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Giả sử tên file ảnh của bạn là 'logo_banner.png'.
    // Thay đổi '.png' thành phần mở rộng đúng của file ảnh nếu khác (ví dụ: '.jpg', '.jpeg').
    const String bannerImagePath = 'assets/images/logo_banner.jpg';

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: AspectRatio(
        aspectRatio: 16 / 4.5,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.deepOrange.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Hiển thị ảnh banner
                Image.asset(
                  bannerImagePath,
                  fit: BoxFit.cover, // Đảm bảo ảnh che phủ toàn bộ banner, có thể bị cắt xén
                  // Nếu muốn ảnh không bị cắt xén và giữ tỷ lệ, có thể dùng BoxFit.contain
                  // và điều chỉnh màu nền của Container bên ngoài nếu ảnh không che hết.
                ),

                // Lớp phủ màu tối nhẹ lên ảnh để chữ nổi bật hơn (tùy chọn)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3), // Độ mờ ở trên cùng/bên trái
                        Colors.black.withOpacity(0.05), // Độ mờ ở giữa
                        Colors.black.withOpacity(0.3), // Độ mờ ở dưới cùng/bên phải
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.4, 1.0], // Điều chỉnh điểm dừng của gradient
                    ),
                  ),
                ),

                // Phần Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Căn giữa text theo chiều dọc
                    crossAxisAlignment: CrossAxisAlignment.start, // Căn text về bên trái
                    children: const [
                      Text(
                        "King Burger",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
                          ],
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Ưu đãi đặc biệt hôm nay!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                           shadows: [
                            Shadow(color: Colors.black38, blurRadius: 3, offset: Offset(1, 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Có thể thêm các element khác trên banner ở đây, ví dụ nút "Xem ngay"
              ],
            ),
          ),
        ),
      ),
    );
  }
}