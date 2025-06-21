class OrderDetail {
  int? foodId;
  int? quantity;
  double? unitPrice;

  OrderDetail({this.foodId, this.quantity, this.unitPrice});

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      foodId: json['foodId'] as int?,
      quantity: json['quantity'] as int?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (foodId != null) data['foodId'] = foodId;
    if (quantity != null) data['quantity'] = quantity;
    if (unitPrice != null) data['unitPrice'] = unitPrice;
    return data;
  }
}