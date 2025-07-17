import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/orderdetail.dart';
import '../providers/auth_provider.dart';
import '../services/order_api_service.dart';
import '../widgets/home/background_widget.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order currentOrder;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;
  }

  // ✅ Cancel order function
  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận hủy đơn', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy đơn hàng #${currentOrder.id}?\n\nLưu ý: Sau khi hủy sẽ không thể hoàn tác.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;

        await OrderApiService().updateOrderStatus(
          currentOrder.id!,
          'Cancelled',
          token: token,
        );

        // Update current order status
        setState(() {
          currentOrder = currentOrder.copyWith(status: 'Cancelled');
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Đã hủy đơn hàng thành công'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Lỗi hủy đơn hàng: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // ✅ Helper methods for status
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status ?? 'N/A';
    }
  }

  bool _canCancelOrder() {
    return currentOrder.status?.toLowerCase() == 'pending';
  }

  // ✅ FIX: Convert dynamic orderDetails to List<OrderDetail>
  List<OrderDetail> _getOrderDetails() {
    if (currentOrder.orderDetails == null) return [];
    
    return currentOrder.orderDetails!.map((detail) {
      if (detail is OrderDetail) {
        return detail;
      } else if (detail is Map<String, dynamic>) {
        return OrderDetail.fromJson(detail);
      } else {
        // Fallback for unknown format - tạo OrderDetail từ string
        print('⚠️ Unknown detail format: ${detail.runtimeType} - $detail');
        return OrderDetail(
          id: null,
          orderId: currentOrder.id,
          foodId: null,
          foodName: detail.toString(),
          quantity: 1,
          unitPrice: 0,
        );
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Format currency
    final formattedAmount = currentOrder.totalAmount != null
        ? '${currentOrder.totalAmount!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫'
        : '0 ₫';

    // Format date
    final formattedDate = currentOrder.orderDate != null
        ? '${currentOrder.orderDate!.day.toString().padLeft(2, '0')}/${currentOrder.orderDate!.month.toString().padLeft(2, '0')}/${currentOrder.orderDate!.year}'
        : 'N/A';

    final formattedTime = currentOrder.orderDate != null
        ? '${currentOrder.orderDate!.hour.toString().padLeft(2, '0')}:${currentOrder.orderDate!.minute.toString().padLeft(2, '0')}'
        : 'N/A';

    // ✅ FIX: Get properly typed order details
    final orderDetails = _getOrderDetails();

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Chi tiết đơn hàng #${currentOrder.id}'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getStatusColor(currentOrder.status).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Ngày đặt: $formattedDate',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const Spacer(),
                        Text(
                          formattedTime,
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Trạng thái:',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(currentOrder.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(currentOrder.status),
                            style: TextStyle(
                              color: _getStatusColor(currentOrder.status),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Tổng tiền:',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const Spacer(),
                        Text(
                          formattedAmount,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (currentOrder.address?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Địa chỉ: ${currentOrder.address}',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (currentOrder.phone?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'SĐT: ${currentOrder.phone}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                    if (currentOrder.note?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.note, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ghi chú: ${currentOrder.note}',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ✅ Cancel Order Button (chỉ hiện khi pending)
              if (_canCancelOrder()) ...[
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _cancelOrder,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel, color: Colors.white),
                    label: Text(
                      _isLoading ? 'Đang hủy...' : 'Hủy đơn hàng',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Order Items
              const Text(
                'Danh sách món',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // ✅ FIX: Proper order details handling
              if (orderDetails.isNotEmpty) ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orderDetails.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white24),
                  itemBuilder: (context, index) {
                    final item = orderDetails[index];
                    
                    // ✅ FIX: Use correct property names from OrderDetail model
                    final unitPrice = item.unitPrice ?? 0;
                    final quantity = item.quantity ?? 0;
                    final itemTotal = unitPrice * quantity;
                    
                    final formattedUnitPrice = '${unitPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫';
                    final formattedItemTotal = '${itemTotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.fastfood, color: Colors.orange, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.foodName ?? 'N/A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Số lượng: $quantity',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                                Text(
                                  'Đơn giá: $formattedUnitPrice',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formattedItemTotal,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.restaurant_menu, color: Colors.white54, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Không có thông tin chi tiết món ăn',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ FIX: Extension với proper typing - CONVERT orderDetails TO DYNAMIC LIST
extension OrderExtension on Order {
  Order copyWith({
    int? id,
    int? userId,
    DateTime? orderDate,
    double? totalAmount,
    String? status,
    String? address,
    String? phone,
    String? note,
    List<dynamic>? orderDetails, // ✅ Keep as List<dynamic> for flexibility
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderDate: orderDate ?? this.orderDate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      orderDetails: orderDetails ?? this.orderDetails,
    );
  }
}