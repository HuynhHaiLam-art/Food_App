import 'package:flutter/material.dart';
import '../../themes/admin_theme.dart';

class AdminSearchBar extends StatelessWidget {
  final String hint;
  final Function(String) onChanged;
  final TextEditingController? controller;

  const AdminSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AdminTheme.bodyLarge,
      decoration: AdminTheme.inputDecoration(
        hint: hint, // ✅ GIỜ KHÔNG CẦN label
        icon: Icons.search,
      ),
      onChanged: onChanged,
    );
  }
}