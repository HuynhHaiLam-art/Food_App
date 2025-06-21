import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';
import '../models/orderdetail.dart';
import '../services/order_api_service.dart';
import '../utils/formatters.dart';
import '../widgets/home/background_widget.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum PaymentMethod { cod, vnpay, momo }

class _CheckoutScreenState extends State<CheckoutScreen> {
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cod;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    addressController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    final reg = RegExp(r'^[0-9]{9,}$');
    return reg.hasMatch(phone);
  }

  Future<void> _submitOrder(BuildContext context) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (addressController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Vui lòng nhập địa chỉ giao hàng!';
      });
      return;
    }
    if (phoneController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Vui lòng nhập số điện thoại!';
      });
      return;
    }
    if (!_isValidPhone(phoneController.text.trim())) {
      setState(() {
        errorMessage = 'Số điện thoại không hợp lệ!';
      });
      return;
    }
    if (cartProvider.items.isEmpty) {
      setState(() {
        errorMessage = 'Giỏ hàng của bạn đang trống!';
      });
      return;
    }
    if (user == null) {
      setState(() {
        errorMessage = 'Bạn cần đăng nhập để đặt hàng!';
      });
      return;
    }

    // Nếu chọn VNPay hoặc Momo thì chuyển sang trang thanh toán
    if (_paymentMethod == PaymentMethod.vnpay) {
      Navigator.of(context).pushNamed('/vnpay_payment');
      return;
    }
    if (_paymentMethod == PaymentMethod.momo) {
      Navigator.of(context).pushNamed('/momo_payment');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final orderDetails = cartProvider.items
          .map((item) => OrderDetail(
                foodId: item.foodId,
                quantity: item.quantity,
                unitPrice: item.price,
              ))
          .toList();

      final order = Order(
        userId: user.id,
        address: addressController.text.trim(),
        totalAmount: cartProvider.totalPrice,
        status: "Pending",
        orderDetails: orderDetails,
      );

      final orderApi = OrderApiService();
      await orderApi.createOrder(order);

      cartProvider.clearCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt hàng thành công!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().contains('CHECK constraint')
            ? 'Trạng thái đơn hàng không hợp lệ!'
            : 'Đặt hàng thất bại. Vui lòng thử lại!';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.items;
    final total = cartProvider.totalPrice;

    return BackgroundWidget(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Xác nhận đơn hàng'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text('Địa chỉ giao hàng:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nhập địa chỉ nhận hàng...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white10,
                ),
                onChanged: (_) {
                  if (errorMessage != null) setState(() => errorMessage = null);
                },
              ),
              const SizedBox(height: 16),
              const Text('Số điện thoại:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nhập số điện thoại...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white10,
                ),
                onChanged: (_) {
                  if (errorMessage != null) setState(() => errorMessage = null);
                },
              ),
              const SizedBox(height: 16),
              const Text('Hình thức thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Column(
                children: [
                  RadioListTile<PaymentMethod>(
                    value: PaymentMethod.cod,
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() => _paymentMethod = value!);
                    },
                    title: const Text('Thanh toán khi nhận hàng', style: TextStyle(color: Colors.white)),
                    activeColor: Colors.white,
                  ),
                  RadioListTile<PaymentMethod>(
                    value: PaymentMethod.vnpay,
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() => _paymentMethod = value!);
                    },
                    title: const Text('VNPay', style: TextStyle(color: Colors.white)),
                    activeColor: Colors.white,
                  ),
                  RadioListTile<PaymentMethod>(
                    value: PaymentMethod.momo,
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() => _paymentMethod = value!);
                    },
                    title: const Text('Momo', style: TextStyle(color: Colors.white)),
                    activeColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Danh sách món:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              if (cartItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Giỏ hàng của bạn đang trống!',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                )
              else
                ...cartItems.map((item) => Card(
                      color: Colors.white.withOpacity(0.08),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: item.food?.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.food!.imageUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.fastfood, color: Colors.white54),
                                ),
                              )
                            : const Icon(Icons.fastfood, color: Colors.white54),
                        title: Text(
                          item.food?.name ?? 'Món ăn',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Số lượng: ${item.quantity}', style: const TextStyle(color: Colors.white70)),
                        trailing: Text(
                          formatCurrency((item.price ?? 0) * (item.quantity ?? 1)),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  Text(
                    formatCurrency(total),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: isLoading ? null : () => _submitOrder(context),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Đặt hàng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}