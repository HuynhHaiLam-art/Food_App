import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/order_api_service.dart';
import '../models/order.dart';
import '../themes/admin_theme.dart';
import '../utils/formatters.dart';
import '../providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late Future<List<Order>> _ordersFuture;
  String _selectedStatus = 'All';
  // ✅ FIX: Update status list to match database
  final List<String> _statuses = ['All', 'Pending', 'Processing', 'Delivered', 'Cancelled'];
  String _searchQuery = '';
  bool _isDisposed = false;
  List<Map<String, dynamic>> _statusOptions = [];

  @override
  void initState() {
    super.initState();
    _loadStatusOptions();
    _loadOrders();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // ✅ Load status options from API
  Future<void> _loadStatusOptions() async {
    if (_isDisposed) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      final options = await OrderApiService().getStatusOptions(token: token);
      if (!_isDisposed && mounted) {
        setState(() {
          _statusOptions = options;
        });
      }
    } catch (e) {
      print('❌ Error loading status options: $e');
      // Use default options if API fails
      _statusOptions = _getDefaultStatusOptions();
    }
  }

  List<Map<String, dynamic>> _getDefaultStatusOptions() {
    return [
      {
        'value': 'Pending',
        'label': 'Chờ xử lý',
        'color': '#FFA726',
        'icon': 'pending',
        'description': 'Đơn hàng mới tạo, chờ xử lý'
      },
      {
        'value': 'Processing',
        'label': 'Đang xử lý',
        'color': '#42A5F5',
        'icon': 'processing',
        'description': 'Đang chuẩn bị món ăn'
      },
      {
        'value': 'Delivered',
        'label': 'Đã giao',
        'color': '#66BB6A',
        'icon': 'delivered',
        'description': 'Đã giao thành công'
      },
      {
        'value': 'Cancelled',
        'label': 'Đã hủy',
        'color': '#EF5350',
        'icon': 'cancelled',
        'description': 'Đơn hàng đã bị hủy'
      }
    ];
  }

  void _loadOrders() {
    if (_isDisposed) return;
    print('🔄 Loading orders...');
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    _ordersFuture = OrderApiService().getAllOrders(token: token);
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    if (_isDisposed) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      await OrderApiService().updateOrderStatus(orderId, newStatus, token: token);
      if (!_isDisposed && mounted) {
        _loadOrders();
        setState(() {});
        _showSuccessSnackBar('✅ Đã cập nhật trạng thái đơn hàng #$orderId thành $newStatus');
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        _showErrorSnackBar('❌ Lỗi cập nhật đơn hàng: $e');
      }
    }
  }

  // ✅ NEW: Show status update menu
  void _showStatusUpdateMenu(Order order) {
    if (_isDisposed) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AdminTheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AdminTheme.accentOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: AdminTheme.accentOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cập nhật trạng thái',
                          style: AdminTheme.headlineLarge,
                        ),
                        Text(
                          'Đơn hàng #${order.id}',
                          style: AdminTheme.bodyMedium.copyWith(
                            color: AdminTheme.accentOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Status Options
            ...(_statusOptions.isNotEmpty ? _statusOptions : _getDefaultStatusOptions())
                .map((option) => _buildStatusOption(order, option))
                ,
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(Order order, Map<String, dynamic> option) {
    final String value = option['value'] ?? '';
    final String label = option['label'] ?? value;
    final String colorHex = option['color'] ?? '#666666';
    final String description = option['description'] ?? '';
    
    final Color color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    final bool isCurrentStatus = order.status == value;
    final bool canUpdate = !isCurrentStatus;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentStatus 
          ? color.withOpacity(0.2) 
          : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentStatus 
            ? color.withOpacity(0.5) 
            : Colors.white12,
          width: isCurrentStatus ? 2 : 1,
        ),
      ),
      child: ListTile(
        enabled: canUpdate,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getStatusIconData(value),
            color: color,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              label,
              style: AdminTheme.bodyLarge.copyWith(
                color: canUpdate ? Colors.white : color,
                fontWeight: isCurrentStatus ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (isCurrentStatus) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Hiện tại',
                  style: GoogleFonts.roboto(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          description,
          style: AdminTheme.bodyMedium.copyWith(
            color: canUpdate ? Colors.white70 : color.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        trailing: canUpdate 
          ? Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16)
          : Icon(Icons.check, color: color, size: 20),
        onTap: canUpdate 
          ? () {
              Navigator.pop(context);
              _updateOrderStatus(order.id!, value);
            }
          : null,
      ),
    );
  }

  IconData _getStatusIconData(String status) {
    switch (status) {
      case 'Pending': return Icons.schedule;
      case 'Processing': return Icons.sync;
      case 'Delivered': return Icons.check_circle;
      case 'Cancelled': return Icons.cancel;
      default: return Icons.help;
    }
  }

  Future<void> _deleteOrder(int orderId) async {
    if (_isDisposed) return;
    
    final confirm = await _showDeleteDialog('đơn hàng #$orderId');
    if (confirm == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;
        
        await OrderApiService().deleteOrder(orderId, token: token);
        if (!_isDisposed && mounted) {
          _loadOrders();
          setState(() {});
          _showSuccessSnackBar('✅ Đã xóa đơn hàng #$orderId');
        }
      } catch (e) {
        if (!_isDisposed && mounted) {
          _showErrorSnackBar('❌ Lỗi xóa đơn hàng: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AdminTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchAndFilter(),
              Expanded(child: _buildOrdersList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🛒 Quản lý đơn hàng', style: AdminTheme.displayMedium),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminTheme.accentOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Xử lý & theo dõi đơn hàng thời gian thực',
                    style: GoogleFonts.roboto(
                      color: AdminTheme.accentOrange, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                if (!_isDisposed) {
                  _loadOrders();
                  setState(() {});
                }
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Tải lại',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: TextField(
                style: AdminTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Tìm theo ID đơn hàng...',
                  hintStyle: AdminTheme.bodyMedium,
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: DropdownButton<String>(
                value: _selectedStatus,
                dropdownColor: AdminTheme.cardBackground,
                style: AdminTheme.bodyLarge,
                underline: Container(),
                isExpanded: true,
                items: _statuses.map((status) => DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      _getStatusIcon(status),
                      const SizedBox(width: 8),
                      Text(status),
                    ],
                  ),
                )).toList(),
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return FutureBuilder<List<Order>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AdminTheme.accentOrange),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: AdminTheme.warningRed, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Lỗi tải đơn hàng: ${snapshot.error}',
                  style: AdminTheme.bodyLarge.copyWith(color: AdminTheme.warningRed),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (!_isDisposed) {
                      _loadOrders();
                      setState(() {});
                    }
                  },
                  style: AdminTheme.primaryButtonStyle,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        var orders = snapshot.data ?? [];
        
        // Filter orders
        if (_searchQuery.isNotEmpty) {
          orders = orders.where((order) => 
            order.id.toString().contains(_searchQuery) ||
            (order.userId?.toString().contains(_searchQuery) ?? false)
          ).toList();
        }
        if (_selectedStatus != 'All') {
          orders = orders.where((order) => order.status == _selectedStatus).toList();
        }

        // Sort by date (newest first)
        orders.sort((a, b) => (b.orderDate ?? DateTime.now()).compareTo(a.orderDate ?? DateTime.now()));

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined, color: Colors.white54, size: 64),
                const SizedBox(height: 16),
                Text('Không có đơn hàng nào', style: AdminTheme.headlineLarge),
                const SizedBox(height: 8),
                Text('Thử thay đổi bộ lọc hoặc tải lại dữ liệu', style: AdminTheme.bodyMedium),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (!_isDisposed) {
              _loadOrders();
              setState(() {});
            }
          },
          color: AdminTheme.accentOrange,
          backgroundColor: AdminTheme.cardBackground,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(order);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AdminTheme.adminCardDecoration.copyWith(
        border: Border.all(
          color: _getStatusColor(order.status ?? 'Pending').withOpacity(0.3), 
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AdminTheme.accentOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${order.id}',
                        style: GoogleFonts.roboto(
                          color: AdminTheme.accentOrange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User #${order.userId ?? 'N/A'}',
                          style: AdminTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _formatDate(order.orderDate),
                          style: AdminTheme.bodyMedium.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildStatusChip(order.status ?? 'Pending'),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Order Details
            Row(
              children: [
                Icon(Icons.attach_money, color: AdminTheme.accentOrange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tổng tiền: ${formatCurrency(order.totalAmount ?? 0)}',
                  style: AdminTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.accentOrange,
                  ),
                ),
                const Spacer(),
                Text(
                  '${order.totalAmount ?? 0} món',
                  style: AdminTheme.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            
            if (order.address != null && order.address!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.address!,
                      style: AdminTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // ✅ UPDATED: Action Buttons with Status Menu
            Row(
              children: [
                // Quick action buttons based on current status
                if (order.status == 'Pending') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(order.id!, 'Processing'),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Xử lý'),
                      style: AdminTheme.primaryButtonStyle.copyWith(
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (order.status == 'Processing') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(order.id!, 'Delivered'),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Hoàn thành'),
                      style: AdminTheme.successButtonStyle.copyWith(
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Status update menu button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showStatusUpdateMenu(order),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Thay đổi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryBlue.withOpacity(0.2),
                      foregroundColor: AdminTheme.primaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AdminTheme.primaryBlue.withOpacity(0.3)),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Delete button
                Container(
                  decoration: BoxDecoration(
                    color: AdminTheme.warningRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _deleteOrder(order.id!),
                    icon: const Icon(Icons.delete, color: AdminTheme.warningRed),
                    tooltip: 'Xóa đơn hàng',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getStatusIcon(status, size: 14),
          const SizedBox(width: 6),
          Text(
            _getStatusLabel(status),
            style: GoogleFonts.roboto(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Pending': return 'Chờ xử lý';
      case 'Processing': return 'Đang xử lý';
      case 'Delivered': return 'Đã giao';
      case 'Cancelled': return 'Đã hủy';
      default: return status;
    }
  }

  Widget _getStatusIcon(String status, {double size = 16}) {
    IconData icon;
    Color color;
    
    switch (status) {
      case 'Pending':
        icon = Icons.schedule;
        color = AdminTheme.accentOrange;
        break;
      case 'Processing':
        icon = Icons.sync;
        color = AdminTheme.primaryBlue;
        break;
      case 'Delivered':
        icon = Icons.check_circle;
        color = AdminTheme.successGreen;
        break;
      case 'Cancelled':
        icon = Icons.cancel;
        color = AdminTheme.warningRed;
        break;
      default:
        icon = Icons.help;
        color = Colors.white54;
    }
    
    return Icon(icon, color: color, size: size);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return AdminTheme.accentOrange;
      case 'Processing': return AdminTheme.primaryBlue;
      case 'Delivered': return AdminTheme.successGreen;
      case 'Cancelled': return AdminTheme.warningRed;
      default: return Colors.white54;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<bool?> _showDeleteDialog(String itemName) {
    if (_isDisposed) return Future.value(false);
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: AdminTheme.warningRed),
            const SizedBox(width: 8),
            Text('Xác nhận xóa', style: AdminTheme.headlineLarge),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa $itemName?\n\nDữ liệu sẽ bị xóa vĩnh viễn!',
          style: AdminTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: AdminTheme.bodyLarge),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: AdminTheme.warningButtonStyle,
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (_isDisposed || !mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AdminTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (_isDisposed || !mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AdminTheme.warningRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}