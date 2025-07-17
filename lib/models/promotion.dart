// Cần thiết cho việc so sánh bằng jsonEncode nếu có list/map phức tạp

class Promotion {
  final int? id;
  final String? code;
  final String? description;
  final String? type;
  final double? discountValue;
  final bool? isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  Promotion({
    this.id,
    this.code,
    this.description,
    this.type,
    this.discountValue,
    this.isActive,
    this.startDate,
    this.endDate,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as int?,
      code: json['code'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      discountValue: (json['discountValue'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool?,
      startDate: json['startDate'] != null 
        ? DateTime.tryParse(json['startDate'] as String)
        : null,
      endDate: json['endDate'] != null 
        ? DateTime.tryParse(json['endDate'] as String)
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (code != null) data['code'] = code;
    if (description != null) data['description'] = description;
    if (type != null) data['type'] = type;
    if (discountValue != null) data['discountValue'] = discountValue;
    if (isActive != null) data['isActive'] = isActive;
    if (startDate != null) data['startDate'] = startDate!.toIso8601String();
    if (endDate != null) data['endDate'] = endDate!.toIso8601String();
    return data;
  }

  Promotion copyWith({
    int? id,
    String? code,
    String? description,
    String? type,
    double? discountValue,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Promotion(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      type: type ?? this.type,
      discountValue: discountValue ?? this.discountValue,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}