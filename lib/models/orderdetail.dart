class OrderDetail {
  int? id;
  int? orderId;
  int? foodId;
  String? foodName;
  int? quantity;
  double? unitPrice;
  String? addOns; // <-- thêm dòng này

  OrderDetail({
    this.id,
    this.orderId,
    this.foodId,
    this.foodName,
    this.quantity,
    this.unitPrice,
    this.addOns,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] as int?,
      orderId: json['orderId'] as int?,
      foodId: json['foodId'] as int?,
      foodName: json['foodName'] as String?,
      quantity: json['quantity'] as int?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      addOns: json['addOns'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (orderId != null) data['orderId'] = orderId;
    if (foodId != null) data['foodId'] = foodId;
    if (foodName != null) data['foodName'] = foodName;
    if (quantity != null) data['quantity'] = quantity;
    if (unitPrice != null) data['unitPrice'] = unitPrice;
    if (addOns != null) data['addOns'] = addOns;
    return data;
  }
}