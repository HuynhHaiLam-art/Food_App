import 'package:intl/intl.dart'; // Thư viện định dạng số, ngày tháng

/// Định dạng số thành tiền tệ Việt Nam, ví dụ: 1.000.000 VNĐ
String formatCurrency(num? value, {String locale = 'vi_VN', String symbol = ' VNĐ'}) {
  if (value == null) return '0$symbol';
  final formatter = NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 0);
  return '${formatter.format(value)}$symbol';
}

/// Định dạng ngày theo chuẩn Việt Nam, ví dụ: 10/06/2025
String formatDate(DateTime? date, {String pattern = 'dd/MM/yyyy'}) {
  if (date == null) return '';
  return DateFormat(pattern).format(date);
}

/// Định dạng giờ phút, ví dụ: 14:30
String formatTime(DateTime? date, {String pattern = 'HH:mm'}) {
  if (date == null) return '';
  return DateFormat(pattern).format(date);
}

// Bạn có thể thêm các hàm formatter khác ở đây nếu cần