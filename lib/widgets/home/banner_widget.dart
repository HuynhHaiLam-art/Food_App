import 'package:flutter/material.dart';

class BannerWidget extends StatelessWidget {
  const BannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
                // Hiển thị ảnh banner, fallback nếu lỗi
                Image.asset(
                  bannerImagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.deepOrange[100],
                  ),
                ),
                // Lớp phủ màu tối nhẹ lên ảnh để chữ nổi bật hơn
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
                // Phần Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
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