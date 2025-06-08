// Cần thiết cho việc so sánh bằng jsonEncode nếu có list/map phức tạp

class Promotion {
  final int id;
  final String code;
  final String? description;
  final int? discountPercent; // Giữ nguyên kiểu int? như C# DTO
  final DateTime startDate;
  final DateTime endDate;

  Promotion({
    required this.id,
    required this.code,
    this.description,
    this.discountPercent,
    required this.startDate,
    required this.endDate,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as int? ?? 0, // Thêm ?? 0 để an toàn nếu API có thể trả về null cho trường required
      code: json['code'] as String? ?? '', // Thêm ?? ''
      description: json['description'] as String?,
      discountPercent: json['discountPercent'] as int?,
      // Giả sử startDate và endDate luôn có và đúng định dạng từ API
      // Nếu không, cần xử lý null hoặc dùng DateTime.tryParse
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discountPercent': discountPercent,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  Promotion copyWith({
    int? id,
    String? code,
    String? description,
    int? discountPercent,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Promotion(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountPercent: discountPercent ?? this.discountPercent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  // (Tùy chọn) Getter để kiểm tra xem khuyến mãi có còn hiệu lực không
  bool get isCurrentlyActive {
    final now = DateTime.now();
    // Giả sử không có trường isActive riêng, chỉ dựa vào ngày
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  // (Tùy chọn) Getter để hiển thị phần trăm giảm giá một cách thân thiện
  String? get displayDiscount {
    if (discountPercent == null || discountPercent! <= 0) {
      return null;
    }
    return '$discountPercent%';
  }

  @override
  String toString() {
    return 'Promotion(id: $id, code: $code, description: $description, discountPercent: $discountPercent, startDate: $startDate, endDate: $endDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Promotion &&
        other.id == id &&
        other.code == code &&
        other.description == description &&
        other.discountPercent == discountPercent &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        code.hashCode ^
        description.hashCode ^
        discountPercent.hashCode ^
        startDate.hashCode ^
        endDate.hashCode;
  }
}