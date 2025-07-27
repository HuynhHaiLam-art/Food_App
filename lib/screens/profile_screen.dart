import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_update.dart';
import '../models/user.dart';
import '../widgets/home/background_widget.dart';
import 'login_screen.dart';
import '../services/order_api_service.dart';
import '../models/order.dart';
import 'order_detail_screen.dart';
import 'admin_dashboard_screen.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import 'checkout_screen.dart'; // ✅ THÊM IMPORT NÀY

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  Future<List<Order>>? _ordersFuture;
  int? _userId;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Load orders after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user?.id != null && user!.id != _userId) {
      _userId = user.id!;
      _loadOrders();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _nameController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // ✅ Load orders với token authentication
  void _loadOrders() {
    if (_isDisposed) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final token = authProvider.token;
    
    if (user?.id == null) {
      print('❌ Cannot load orders: user is null or has no ID');
      return;
    }

    print('🔄 Loading orders for user ${user!.id} with token: ${token != null ? "✅" : "❌"}');
    
    if (mounted) {
      setState(() {
        _ordersFuture = _loadOrdersFromApi(user.id!, token);
      });
    }
  }

  // ✅ Separate method để load orders từ API
  Future<List<Order>> _loadOrdersFromApi(int userId, String? token) async {
    try {
      print('📞 Calling OrderApiService.getOrders(userId: $userId)');
      final orders = await OrderApiService().getOrders(userId, token: token);
      print('✅ Successfully loaded ${orders.length} orders for user $userId');
      return orders;
    } catch (e) {
      print('❌ Error loading orders: $e');
      rethrow;
    }
  }

  // ✅ Edit Profile method (không thay đổi)
  Future<void> _editProfile(BuildContext context, User currentUser) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = currentUser.name ?? '';
    _oldPassController.clear();
    _newPassController.clear();
    _confirmPassController.clear();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withAlpha((0.7 * 255).round()),
      barrierDismissible: false,
      builder: (dialogContext) {
        String? localErrorMessage;
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) => Center(
            child: SingleChildScrollView(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.09 * 255).round()),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: Color(0xFF7C5CFC),
                          child: Icon(Icons.person, size: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chỉnh sửa thông tin',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withAlpha((0.10 * 255).round()),
                            labelText: 'Tên mới',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            prefixIcon: const Icon(Icons.person, color: Colors.white54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: Colors.white, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty ? 'Vui lòng nhập tên' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _oldPassController,
                          obscureText: true,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withAlpha((0.10 * 255).round()),
                            labelText: 'Mật khẩu cũ (bỏ qua nếu chỉ đổi tên)',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: Colors.white, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newPassController,
                          obscureText: true,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withAlpha((0.10 * 255).round()),
                            labelText: 'Mật khẩu mới',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: const Icon(Icons.lock_reset, color: Colors.white54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: Colors.white, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          ),
                          validator: (value) {
                            if (_oldPassController.text.isNotEmpty && (value == null || value.length < 6)) {
                              return 'Mật khẩu mới tối thiểu 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPassController,
                          obscureText: true,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withAlpha((0.10 * 255).round()),
                            labelText: 'Nhập lại mật khẩu mới',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: Colors.white, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          ),
                          validator: (value) {
                            if (_oldPassController.text.isNotEmpty && (value == null || value.isEmpty)) {
                              return 'Vui lòng nhập lại mật khẩu mới';
                            }
                            if (_oldPassController.text.isNotEmpty &&
                                value != _newPassController.text) {
                              return 'Mật khẩu không khớp';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        if (localErrorMessage?.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              localErrorMessage ?? '',
                              style: GoogleFonts.poppins(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isLoading ? null : () => Navigator.pop(dialogContext, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(
                                  'Hủy',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        if (formKey.currentState!.validate()) {
                                          setStateDialog(() {
                                            localErrorMessage = null;
                                          });

                                          final userUpdateData = UserUpdate(
                                            name: _nameController.text.trim(),
                                          );

                                          setStateDialog(() {
                                            isLoading = true;
                                          });

                                          final success = await authProvider.updateUserProfile(
                                            userUpdateData,
                                            oldPassword: _oldPassController.text.isEmpty ? null : _oldPassController.text,
                                            newPassword: _newPassController.text.isEmpty ? null : _newPassController.text,
                                          );

                                          if (success) {
                                            if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                                          } else {
                                            setStateDialog(() {
                                              localErrorMessage = authProvider.lastErrorMessage ?? 'Có lỗi xảy ra';
                                              isLoading = false;
                                            });
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: Colors.white, width: 1.5),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        'Lưu',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).refreshCurrentUser();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cập nhật thông tin thành công!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    }
  }

  // ✅ Logout method (không thay đổi)
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.orange),
            SizedBox(width: 8),
            Text('Xác nhận đăng xuất', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
        
        print('🚀 User logged out successfully');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Đã đăng xuất thành công'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        print('❌ Logout error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Lỗi đăng xuất: $e')),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ✅ Sửa lại method _reorderItems - Fix price parsing
  Future<void> _reorderItems(Order order) async {
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      // Hiển thị loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Đang chuẩn bị đơn hàng...',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // ✅ Xóa giỏ hàng hiện tại trước khi thêm đơn mới
      cartProvider.clearCart();

      // Lấy chi tiết đơn hàng và thêm vào cart
      int addedCount = 0;
      int failedCount = 0;
      
      if (order.orderDetails != null && order.orderDetails!.isNotEmpty) {
        for (final detailData in order.orderDetails!) {
          try {
            // ✅ Parse detail data với proper type casting và debugging
            String productName;
            int? productId;
            double price = 0.0; // Default giá
            int quantity;
            
            if (detailData is Map<String, dynamic>) {
              productName = detailData['productName']?.toString() ?? 
                           detailData['name']?.toString() ?? 
                           'Sản phẩm';
            
              final rawProductId = detailData['productId'] ?? detailData['id'];
              if (rawProductId is int) {
                productId = rawProductId;
              } else if (rawProductId is String) {
                productId = int.tryParse(rawProductId);
              } else {
                productId = null;
              }
            
              // ✅ Enhanced price parsing với debugging
              final rawPrice = detailData['price'] ?? detailData['unitPrice'] ?? detailData['productPrice'];
              print('🔍 Raw price data: $rawPrice (type: ${rawPrice.runtimeType})');
            
              if (rawPrice is num) {
                price = rawPrice.toDouble();
              } else if (rawPrice is String) {
                price = double.tryParse(rawPrice) ?? 0.0;
              } else {
                // ✅ Fallback: tính từ totalAmount nếu có
                if (order.totalAmount != null && order.orderDetails!.isNotEmpty) {
                  price = order.totalAmount! / order.orderDetails!.length;
                  print('🔄 Using fallback price from totalAmount: $price');
                } else {
                  price = 50000.0; // Default price nếu không có gì
                  print('⚠️ Using default price: $price');
                }
              }
            
              final rawQuantity = detailData['quantity'];
              if (rawQuantity is int) {
                quantity = rawQuantity;
              } else if (rawQuantity is num) {
                quantity = rawQuantity.round();
              } else if (rawQuantity is String) {
                quantity = int.tryParse(rawQuantity) ?? 1;
              } else {
                quantity = 1;
              }
            } else {
              // Object parsing
              productName = detailData.productName ?? 'Sản phẩm';
              productId = detailData.productId;
            
              // ✅ Enhanced price parsing for objects
              final rawPrice = detailData.price ?? detailData.unitPrice ?? detailData.productPrice;
              print('🔍 Object price data: $rawPrice (type: ${rawPrice.runtimeType})');
            
              if (rawPrice is num) {
                price = rawPrice.toDouble();
              } else if (rawPrice is String) {
                price = double.tryParse(rawPrice) ?? 0.0;
              } else {
                // Fallback logic
                if (order.totalAmount != null && order.orderDetails!.isNotEmpty) {
                  price = order.totalAmount! / order.orderDetails!.length;
                } else {
                  price = 50000.0; // Default price
                }
              }
            
              final rawQuantity = detailData.quantity;
              if (rawQuantity is int) {
                quantity = rawQuantity;
              } else if (rawQuantity is num) {
                quantity = rawQuantity.round();
              } else {
                quantity = 1;
              }
            }
            
            // ✅ Debug logging
            print('🔍 Processing item: $productName');
            print('   - ID: $productId');
            print('   - Price: $price');
            print('   - Quantity: $quantity');
            print('   - DetailData: $detailData');
            
            // ✅ Validate price trước khi tạo Product
            if (price <= 0) {
              print('⚠️ Invalid price detected, using fallback');
              if (order.totalAmount != null && order.totalAmount! > 0) {
                price = order.totalAmount! / (order.orderDetails?.length ?? 1);
              } else {
                price = 50000.0; // Default reasonable price
              }
            }
            
            // ✅ Tạo Product object từ parsed data
            final product = Product(
              id: productId,
              name: productName,
              price: price,
              description: 'Đặt lại từ đơn hàng #${order.id}',
              imageUrl: '', // Default empty
              categoryId: 1, // Default category
            );
            
            print('✅ Created product: ${product.name} - Price: ${product.price}');
            
            // ✅ Thêm vào cart với số lượng đúng
            for (int i = 0; i < quantity; i++) {
              cartProvider.addToCart(product);
            }
            
            print('✅ Added $quantity x $productName to cart');
            addedCount++;
            
          } catch (e) {
            print('❌ Lỗi thêm sản phẩm: $e');
            print('❌ Detail data type: ${detailData.runtimeType}');
            print('❌ Detail data: $detailData');
            failedCount++;
          }
        }
      }

      // Đóng loading dialog
      if (mounted) Navigator.of(context).pop();

      if (addedCount > 0) {
        // ✅ Chuyển đến màn hình checkout
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CheckoutScreen(),
          ),
        );
        
        // Hiển thị thông báo ngắn
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Đã thêm $addedCount món từ đơn hàng #${order.id}',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Không thể thêm món vào giỏ hàng. Vui lòng thử lại.',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      // Đóng loading dialog nếu còn mở
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      print('❌ Lỗi đặt lại đơn hàng: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Lỗi: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Sửa method _showReorderConfirmDialog - Fix type casting
  Future<void> _showReorderConfirmDialog(Order order) async {
    // Tính toán itemCount
    int itemCount = 0;
    if (order.orderDetails != null) {
      for (final detail in order.orderDetails!) {
        if (detail is Map<String, dynamic>) {
          final rawQuantity = detail['quantity'];
          if (rawQuantity is int) {
            itemCount += rawQuantity;
          } else if (rawQuantity is num) {
            itemCount += rawQuantity.round();
          } else if (rawQuantity is String) {
            itemCount += int.tryParse(rawQuantity) ?? 1;
          } else {
            itemCount += 1;
          }
        } else {
          final rawQuantity = detail.quantity;
          if (rawQuantity is int) {
            itemCount += rawQuantity;
          } else if (rawQuantity is num) {
            itemCount += rawQuantity.round();
          } else {
            itemCount += 1;
          }
        }
      }
    }
    
    final formattedAmount = order.totalAmount != null 
        ? '${order.totalAmount!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫'
        : '0 ₫';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.replay, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đặt lại đơn hàng',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đặt lại đơn hàng #${order.id} và chuyển đến thanh toán?',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$itemCount món ăn',
                        style: GoogleFonts.poppins(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Tổng tiền gốc: $formattedAmount',
                        style: GoogleFonts.poppins(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ✅ Thêm thông báo về việc xóa giỏ hàng hiện tại
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.yellow.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.yellow, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Giỏ hàng hiện tại sẽ được thay thế',
                      style: GoogleFonts.poppins(
                        color: Colors.yellow,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn sẽ được chuyển đến màn hình thanh toán để xác nhận đơn hàng.',
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.payment, size: 18),
            label: Text(
              'Đặt lại & Thanh toán',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _reorderItems(order);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return BackgroundWidget(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Vui lòng đăng nhập để xem thông tin.', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text('Đăng nhập'),
                )
              ],
            ),
          ),
        ),
      );
    }

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Thông tin cá nhân'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại đơn hàng',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Section
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.2 * 255).round()),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const CircleAvatar(
                        radius: 48,
                        backgroundColor: Color(0xFF7C5CFC),
                        child: Icon(Icons.person, size: 48, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentUser.name ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentUser.email ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              _ProfileButton(
                icon: Icons.edit,
                label: 'Chỉnh sửa thông tin',
                onPressed: () => _editProfile(context, currentUser),
              ),
              const SizedBox(height: 18),
              _ProfileButton(
                icon: Icons.logout,
                label: 'Đăng xuất',
                onPressed: _logout,
                color: Colors.red,
                border: false,
              ),
              
              // Admin Dashboard Button
              if (authProvider.isAdmin) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                    label: const Text(
                      'Quản lý Admin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              
              // ✅ Orders Section - ĐÃ LOẠI BỎ PHẦN TEST
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lịch sử đơn hàng',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: _loadOrders,
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      tooltip: 'Tải lại đơn hàng',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // ✅ CLEANED FutureBuilder - Loại bỏ tất cả phần test
              FutureBuilder<List<Order>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  // Loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      child: const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Colors.orange),
                            SizedBox(height: 16),
                            Text(
                              'Đang tải đơn hàng...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  // Error state - ✅ BỎ BUTTON TẠO TEST ORDER
                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 8),
                          const Text(
                            'Lỗi tải đơn hàng',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _loadOrders,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Success state
                  final allOrders = snapshot.data ?? [];
                  final userOrders = allOrders.where((order) => order.userId == currentUser.id).toList();

                  // Sort by date (newest first)
                  userOrders.sort((a, b) {
                    if (a.orderDate == null && b.orderDate == null) return 0;
                    if (a.orderDate == null) return 1;
                    if (b.orderDate == null) return -1;
                    return b.orderDate!.compareTo(a.orderDate!);
                  });

                  // ✅ Empty state - BỎ DEBUG INFO VÀ TEST BUTTON
                  if (userOrders.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.shopping_cart_outlined, color: Colors.white54, size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'Bạn chưa có đơn hàng nào.',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadOrders,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tải lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Orders list với enhanced UI
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: userOrders.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white24),
                    itemBuilder: (context, index) {
                      final order = userOrders[index];
                      
                      // Format currency
                      final formattedAmount = order.totalAmount != null 
                          ? '${order.totalAmount!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫'
                          : '0 ₫';
                      
                      // Format date
                      final formattedDate = order.orderDate != null 
                          ? '${order.orderDate!.day.toString().padLeft(2, '0')}/${order.orderDate!.month.toString().padLeft(2, '0')}/${order.orderDate!.year}'
                          : 'N/A';

                      // ✅ Kiểm tra xem có thể đặt lại không
                      final canReorder = order.status?.toLowerCase() == 'completed' || 
                                        order.status?.toLowerCase() == 'delivered' || 
                                        order.status?.toLowerCase() == 'cancelled';

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getStatusColor(order.status).withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              leading: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getStatusColor(order.status),
                                      _getStatusColor(order.status).withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: const Icon(Icons.receipt_long, size: 28, color: Colors.white),
                              ),
                              title: Text(
                                'Đơn hàng #${order.id}',
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ngày: $formattedDate',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getStatusText(order.status),
                                      style: TextStyle(
                                        color: _getStatusColor(order.status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (order.address?.isNotEmpty == true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '📍 ${order.address}',
                                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formattedAmount,
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order.orderDetails?.length ?? 0} món',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => OrderDetailScreen(order: order),
                                  ),
                                );
                              },
                            ),
                            
                            // ✅ Action buttons row
                            if (canReorder || true) // Luôn hiển thị để có button "Xem chi tiết"
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    // ✅ Button "Xem chi tiết"
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => OrderDetailScreen(order: order),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.visibility, size: 16),
                                        label: Text(
                                          'Xem chi tiết',
                                          style: GoogleFonts.poppins(fontSize: 12),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white70,
                                          side: const BorderSide(color: Colors.white30),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // ✅ Button "Đặt lại" - chỉ hiển thị cho đơn completed, delivered, cancelled
                                    if (canReorder) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _showReorderConfirmDialog(order),
                                          icon: const Icon(Icons.replay, size: 16),
                                          label: Text(
                                            'Đặt lại',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Helper methods for status handling
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
        return 'Chờ xử lý';
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
}

// ✅ ProfileButton widget không thay đổi
class _ProfileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final bool border;

  const _ProfileButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.white.withAlpha((0.08 * 255).round()),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: border
                ? const BorderSide(color: Colors.white, width: 1.5)
                : BorderSide.none,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}