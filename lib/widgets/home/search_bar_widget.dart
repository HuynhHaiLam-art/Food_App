import 'package:flutter/material.dart';
import 'package:food_app/themes/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const SearchBarWidget({
    super.key,
    this.controller,
    required this.onChanged,
    this.onClear,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showClear = widget.controller != null &&
        widget.controller!.text.isNotEmpty &&
        widget.onClear != null;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused
                    ? AppTheme.primaryOrange.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: _isFocused ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isFocused
                      ? AppTheme.primaryOrange.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: _isFocused ? 20 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: widget.controller,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm món ăn yêu thích...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 16,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search_rounded,
                    color: _isFocused ? AppTheme.primaryOrange : Colors.white70,
                    size: 24,
                  ),
                ),
                suffixIcon: showClear
                    ? IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.clear_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                        onPressed: widget.onClear,
                        splashRadius: 20,
                        tooltip: 'Xóa nội dung',
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
              ),
              onChanged: widget.onChanged,
              onTap: () {
                setState(() {
                  _isFocused = true;
                });
                _animationController.forward();
              },
              onSubmitted: (_) {
                setState(() {
                  _isFocused = false;
                });
                _animationController.reverse();
              },
              onEditingComplete: () {
                setState(() {
                  _isFocused = false;
                });
                _animationController.reverse();
              },
            ),
          ),
        );
      },
    );
  }
}