import 'orderdetail.dart';

class Order {
  int? id;
  int? userId;
  DateTime? orderDate;
  double? totalAmount;
  String? status;
  String? address;
  String? phone;
  String? note;
  List<dynamic>? orderDetails; // ✅ KEEP AS List<dynamic> for flexibility

  Order({
    this.id,
    this.userId,
    this.orderDate,
    this.totalAmount,
    this.status,
    this.address,
    this.phone,
    this.note,
    this.orderDetails,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int?,
      userId: json['userId'] as int?,
      orderDate: json['orderDate'] != null 
          ? DateTime.tryParse(json['orderDate'].toString())
          : null,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      status: json['status'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      note: json['note'] as String?,
      orderDetails: json['orderDetails'] as List<dynamic>?, // ✅ Keep as dynamic
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (userId != null) data['userId'] = userId;
    if (orderDate != null) data['orderDate'] = orderDate!.toIso8601String();
    if (totalAmount != null) data['totalAmount'] = totalAmount;
    if (status != null) data['status'] = status;
    if (address != null) data['address'] = address;
    if (phone != null) data['phone'] = phone;
    if (note != null) data['note'] = note;
    if (orderDetails != null) data['orderDetails'] = orderDetails;
    return data;
  }

  Order copyWith({
    int? id,
    int? userId,
    DateTime? orderDate,
    double? totalAmount,
    String? status,
    String? address,    // ✅ THÊM
    String? phone,      // ✅ THÊM
    String? note,       // ✅ THÊM
    List<OrderDetail>? orderDetails,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderDate: orderDate ?? this.orderDate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      address: address ?? this.address,           // ✅ THÊM
      phone: phone ?? this.phone,                 // ✅ THÊM
      note: note ?? this.note,                    // ✅ THÊM
      orderDetails: orderDetails ?? this.orderDetails,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}