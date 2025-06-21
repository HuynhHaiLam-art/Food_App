import 'orderdetail.dart';

class Order {
  int? id;
  int? userId;
  String? address;
  double? totalAmount;
  String? status;
  DateTime? orderDate;
  List<OrderDetail>? orderDetails;

  Order({
    this.id,
    this.userId,
    this.address,
    this.totalAmount,
    this.status,
    this.orderDate,
    this.orderDetails,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int?,
      userId: json['userId'] as int?,
      address: json['address'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      status: json['status'] as String?,
      orderDate: json['orderDate'] != null
          ? DateTime.tryParse(json['orderDate'])
          : null,
      orderDetails: json['orderDetails'] != null
          ? (json['orderDetails'] as List)
              .map((e) => OrderDetail.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (userId != null) data['userId'] = userId;
    if (address != null) data['address'] = address;
    if (totalAmount != null) data['totalAmount'] = totalAmount;
    if (status != null) data['status'] = status;
    if (orderDetails != null) {
      data['orderDetails'] = orderDetails!.map((e) => e.toJson()).toList();
    }
    data.removeWhere((key, value) => value == null);
    return data;
  }
}