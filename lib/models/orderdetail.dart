class OrderDetail {
  int? foodId;
  String? foodName; // Thêm dòng này
  int? quantity;
  double? unitPrice;

  OrderDetail({this.foodId, this.foodName, this.quantity, this.unitPrice});

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      foodId: json['foodId'] as int?,
      foodName: json['foodName'] as String?, // Thêm dòng này
      quantity: json['quantity'] as int?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (foodId != null) data['foodId'] = foodId;
    if (foodName != null) data['foodName'] = foodName; // Thêm dòng này
    if (quantity != null) data['quantity'] = quantity;
    if (unitPrice != null) data['unitPrice'] = unitPrice;
    return data;
  }
}