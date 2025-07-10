import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết đơn hàng #${order.id}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF181A20),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Ngày đặt',
              value: order.orderDate?.toLocal().toString().split(' ')[0] ?? 'N/A',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.info_outline,
              label: 'Trạng thái',
              value: order.status ?? 'N/A',
              valueColor: order.status == 'Pending'
                  ? Colors.orange
                  : order.status == 'Completed'
                      ? Colors.green
                      : Colors.redAccent,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.attach_money,
              label: 'Tổng tiền',
              value: '${order.totalAmount?.toStringAsFixed(0) ?? '0'} VNĐ',
              valueColor: Colors.amber,
            ),
            const SizedBox(height: 18),
            const Text(
              'Danh sách món',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                color: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: order.orderDetails?.length ?? 0,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white24, height: 1),
                  itemBuilder: (context, index) {
                    final detail = order.orderDetails![index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.withOpacity(0.8),
                        child: const Icon(Icons.fastfood, color: Colors.white),
                      ),
                      title: Text(
                        detail.foodName ?? 'Món ăn',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Số lượng: ${detail.quantity}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Text(
                        '${detail.unitPrice?.toStringAsFixed(0) ?? '0'} VNĐ',
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}