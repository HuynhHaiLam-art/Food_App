import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  // Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color secondaryIndigo = Color(0xFF3F51B5);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningRed = Color(0xFFF44336);
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color cardBackground = Color(0xFF161B22);
  static const Color surfaceColor = Color(0xFF21262D);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A237E),
      Color(0xFF3949AB),
      Color(0xFF5C6BC0),
    ],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1AFFFFFF),
      Color(0x0DFFFFFF),
    ],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [successGreen, Color(0xFF66BB6A)],
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [warningRed, Color(0xFFEF5350)],
  );

  // Text Styles
  static TextStyle get displayLarge => GoogleFonts.roboto(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  static TextStyle get displayMedium => GoogleFonts.roboto(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static TextStyle get headlineLarge => GoogleFonts.roboto(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static TextStyle get headingStyle => GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.roboto(
    fontSize: 16,
    color: Colors.white,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.roboto(
    fontSize: 14,
    color: Colors.white70,
  );

  static TextStyle get bodySmall => GoogleFonts.roboto(
    fontSize: 12,
    color: Colors.white60,
  );

  // Component Decorations
  static BoxDecoration get adminCardDecoration => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withOpacity(0.1),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  static BoxDecoration adminButtonDecoration({
    Color? color,
    Gradient? gradient,
  }) => BoxDecoration(
    color: color,
    gradient: gradient,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: (color ?? primaryBlue).withOpacity(0.3),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    String? label, // ✅ SỬA: không bắt buộc
    String? hint,
    IconData? icon,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon ?? (icon != null ? Icon(icon, color: Colors.white70) : null),
    suffixIcon: suffixIcon,
    labelStyle: GoogleFonts.roboto(color: Colors.white70),
    hintStyle: GoogleFonts.roboto(color: Colors.white54),
    filled: true,
    fillColor: surfaceColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: warningRed, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: warningRed, width: 2),
    ),
  );

  // Admin Input Decoration (để tương thích với code cũ)
  static InputDecoration adminInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) => inputDecoration(
    label: label,
    hint: hint,
    icon: icon,
  );

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
  
  static ButtonStyle get successButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: successGreen,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
  
  static ButtonStyle get warningButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: warningRed,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  // Additional Utility Methods
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return accentOrange;
      case 'processing': return primaryBlue;
      case 'completed': return successGreen;
      case 'cancelled': return warningRed;
      case 'active': return successGreen;
      case 'inactive': return warningRed;
      default: return Colors.white54;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.schedule;
      case 'processing': return Icons.sync;
      case 'completed': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      case 'active': return Icons.check_circle;
      case 'inactive': return Icons.cancel;
      default: return Icons.help;
    }
  }

  // Container Decorations
  static BoxDecoration get searchBarDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
  );

  static BoxDecoration get headerCardDecoration => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Spacing Constants
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Border Radius
  static const double borderRadius8 = 8.0;
  static const double borderRadius12 = 12.0;
  static const double borderRadius16 = 16.0;
  static const double borderRadius20 = 20.0;
}