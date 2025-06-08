import 'package:intl/intl.dart'; // Thêm thư viện intl để định dạng số tốt hơn

// Để sử dụng NumberFormat, bạn cần thêm intl vào pubspec.yaml:
// dependencies:
//   flutter:
//     sdk: flutter
//   intl: ^0.18.0 # Hoặc phiên bản mới nhất

String formatCurrency(num? value, {String locale = 'vi_VN', String symbol = ' VNĐ'}) {
  if (value == null) return '0$symbol';
  
  // Sử dụng NumberFormat để định dạng số theo chuẩn locale
  // Điều này giúp xử lý dấu phân cách hàng nghìn và thập phân đúng chuẩn hơn
  final formatter = NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 0);
  return '${formatter.format(value)}$symbol';
}

// Bạn có thể thêm các hàm formatter khác ở đây nếu cần
// Ví dụ: formatDate, formatTime, v.v.