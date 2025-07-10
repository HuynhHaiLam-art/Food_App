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

  @override
  void initState() {
    super.initState();
    // Không dùng context ở đây, sẽ lấy userId trong didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null && user.id != null && user.id != _userId) {
      _userId = user.id;
      _ordersFuture = OrderApiService().getOrders(user.id!);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

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
                                            email: currentUser.email,
                                            role: currentUser.role,
                                          );

                                          setStateDialog(() {
                                            isLoading = true;
                                          });

                                          final success = await authProvider.updateUserProfile(
                                            userUpdateData,
                                            oldPassword: _oldPassController.text.isNotEmpty ? _oldPassController.text : null,
                                            newPassword: _newPassController.text.isNotEmpty ? _newPassController.text : null,
                                          );

                                          if (success) {
                                            if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                                          } else {
                                            setStateDialog(() {
                                              isLoading = false;
                                              localErrorMessage = authProvider.lastErrorMessage ?? 'Cập nhật thất bại!';
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

    // Nếu cập nhật thành công, refresh lại user
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              _ProfileButton(
                icon: Icons.edit,
                label: 'Chỉnh sửa thông tin',
                onPressed: () => _editProfile(context, currentUser),
              ),
              const SizedBox(height: 18),
              _ProfileButton(
                icon: Icons.logout,
                label: 'Đăng xuất',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('Xác nhận đăng xuất', style: TextStyle(color: Colors.white)),
                      content: const Text('Bạn có chắc chắn muốn đăng xuất không?', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Hủy', style: TextStyle(color: Colors.white)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext, true);
                          },
                          child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    await authProvider.logout();
                    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                color: Colors.red,
                border: false,
              ),
              const SizedBox(height: 24),
              const Text(
                'Lịch sử đơn hàng',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Order>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Lỗi tải đơn hàng: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    );
                  }
                  final orders = (snapshot.data ?? []).where((order) => order.userId == currentUser.id).toList();
                  if (orders.isEmpty) {
                    return const Text(
                      'Bạn chưa có đơn hàng nào.',
                      style: TextStyle(color: Colors.white70),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white24),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.orange,
                          child: const Icon(Icons.receipt_long, size: 28, color: Colors.white),
                        ),
                        title: Text(
                          'Đơn hàng #${order.id}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          // Đổi order.orderDate thành đúng trường ngày tháng của bạn
                          'Ngày: ${order.orderDate?.toLocal().toString().split(' ')[0] ?? 'N/A'} - Trạng thái: ${order.status ?? 'N/A'}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        trailing: Text(
                          '${order.totalAmount?.toStringAsFixed(0) ?? '0'} VNĐ',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(order: order),
                            ),
                          );
                        },
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
}

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