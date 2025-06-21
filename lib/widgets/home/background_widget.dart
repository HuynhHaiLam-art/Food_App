import 'package:flutter/material.dart';

class BackgroundWidget extends StatelessWidget {
  final Widget child;
  final Color overlayColor;
  final String imagePath;

  const BackgroundWidget({
    super.key,
    required this.child,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.45),
    this.imagePath = 'assets/images/background.jpg',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            // Nếu ảnh lỗi, chỉ dùng màu nền
          },
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: overlayColor,
        ),
        child: child,
      ),
    );
  }
}