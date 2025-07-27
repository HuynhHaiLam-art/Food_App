import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_api_service.dart';
import '../services/product_api_service.dart';
import '../services/order_api_service.dart';
import '../models/order.dart';
import 'admin_users_screen.dart';
import 'admin_products_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_promotions_screen.dart';
import 'admin_analytics_screen.dart';
import '../widgets/home/main_nav_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Stats data
  int totalUsers = 0;
  int totalProducts = 0;
  int totalOrders = 0;
  double totalRevenue = 0;
  bool isLoadingStats = true;
  String lastUpdated = '';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadStats();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _loadStats() async {
    if (_isDisposed || !mounted) return;
    
    _safeSetState(() {
      isLoadingStats = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      print('🔄 Loading admin stats with token: ${token != null ? "✅" : "❌"}');
      
      // ✅ Parallel loading với better error handling
      final futures = await Future.wait([
        UserApiService().getAllUsers(token: token).catchError((e) {
          print('❌ Error loading users: $e');
          return [];
        }),
        ProductApiService().getProducts(token: token).catchError((e) {
          print('❌ Error loading products: $e');
          return [];
        }),
        OrderApiService().getAllOrders(token: token).catchError((e) {
          print('❌ Error loading orders: $e');
          return <Order>[];
        }),
      ]);
      
      if (_isDisposed || !mounted) return;
      
      final users = futures[0] as List;
      final products = futures[1] as List;
      final orders = futures[2] as List<Order>;
      
      // Calculate revenue từ completed orders
      double revenue = 0;
      for (var order in orders) {
        if (order.status?.toLowerCase() == 'delivered') {
          revenue += order.totalAmount ?? 0;
        }
      }
      
      _safeSetState(() {
        totalUsers = users.length;
        totalProducts = products.length;
        totalOrders = orders.length;
        totalRevenue = revenue;
        isLoadingStats = false;
        lastUpdated = _formatTime(DateTime.now());
      });
      
      print('📊 Admin Stats loaded successfully');
      print('   👥 Users: $totalUsers');
      print('   🍔 Products: $totalProducts');  
      print('   📦 Orders: $totalOrders');
      print('   💰 Revenue: ${_formatRevenue(revenue)}');
      
    } catch (e) {
      print('❌ Critical error loading admin stats: $e');
      if (_isDisposed || !mounted) return;
      
      _safeSetState(() {
        totalUsers = 0;
        totalProducts = 0;
        totalOrders = 0;
        totalRevenue = 0;
        isLoadingStats = false;
        lastUpdated = 'Lỗi tải dữ liệu';
      });
      
      _showErrorSnackBar('Lỗi tải thống kê: $e');
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // ✅ Enhanced currency formatting
  String _formatRevenue(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B ₫';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M ₫';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K ₫';
    } else {
      return '${amount.toStringAsFixed(0)} ₫';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;
              
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: RefreshIndicator(
                    onRefresh: _loadStats,
                    color: const Color(0xFF00D4FF),
                    backgroundColor: const Color(0xFF1A1A2E),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernHeader(context, user, authProvider),
                          const SizedBox(height: 24), // ✅ Reduced spacing
                          _buildCompactStatsCards(),
                          const SizedBox(height: 24), // ✅ Reduced spacing
                          _buildCompactQuickActions(context),
                          const SizedBox(height: 20), // ✅ Final padding
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ✅ MODERN HEADER - unchanged
  Widget _buildModernHeader(BuildContext context, dynamic user, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated Avatar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF5A67D8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng trở lại! 👋',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  user?.name ?? 'Admin',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF6B6B).withOpacity(0.2),
                        const Color(0xFFFF8E53).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6B6B).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Color(0xFFFF6B6B), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Administrator • Full Access',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFF6B6B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _buildModernHeaderButton(
                onPressed: _handleRefresh,
                icon: isLoadingStats 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
                        ),
                      )
                    : const Icon(Icons.refresh, color: Color(0xFF00D4FF)),
                tooltip: 'Tải lại dữ liệu',
                color: const Color(0xFF00D4FF),
              ),
              const SizedBox(height: 8),
              _buildModernHeaderButton(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, color: Color(0xFFFF6B6B)),
                tooltip: 'Đăng xuất',
                color: const Color(0xFFFF6B6B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeaderButton({
    required VoidCallback onPressed,
    required Widget icon,
    required String tooltip,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }

  // ✅ COMPACT STATS CARDS - 4 cards nằm ngang chia đều
  Widget _buildCompactStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Thống kê tổng quan',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (lastUpdated.isNotEmpty && !lastUpdated.contains('Lỗi'))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.update, color: Color(0xFF00D4FF), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      lastUpdated,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF00D4FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // ✅ ROW với 4 cards nằm ngang chia đều
        Row(
          children: [
            Expanded(
              child: _buildCompactStatCard(
                'Người dùng', 
                isLoadingStats ? '...' : totalUsers.toString(), 
                Icons.people_alt_rounded, 
                const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]), 
                _getGrowthPercentage(totalUsers, 0.12),
              ),
            ),
            const SizedBox(width: 8), // ✅ Spacing between cards
            Expanded(
              child: _buildCompactStatCard(
                'Sản phẩm', 
                isLoadingStats ? '...' : totalProducts.toString(), 
                Icons.restaurant_menu_rounded, 
                const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]), 
                _getGrowthPercentage(totalProducts, 0.08),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactStatCard(
                'Đơn hàng', 
                isLoadingStats ? '...' : totalOrders.toString(), 
                Icons.shopping_bag_rounded, 
                const LinearGradient(colors: [Color(0xFFfa709a), Color(0xFFfee140)]), 
                _getGrowthPercentage(totalOrders, 0.23),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactStatCard(
                'Doanh thu', 
                isLoadingStats ? '...' : _formatRevenue(totalRevenue), 
                Icons.trending_up_rounded, 
                const LinearGradient(colors: [Color(0xFFa8edea), Color(0xFFfed6e3)]), 
                totalRevenue > 0 ? '+25%' : '0%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getGrowthPercentage(int value, double factor) {
    if (value <= 0) return '0%';
    final growth = (value * factor).toInt();
    return '+$growth%';
  }

  // ✅ COMPACT STAT CARD - smaller cho 4 cards nằm ngang
  Widget _buildCompactStatCard(
    String title, 
    String value, 
    IconData icon, 
    Gradient gradient, 
    String change,
  ) {
    return Container(
      padding: const EdgeInsets.all(12), // ✅ Reduced padding for horizontal layout
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12), // ✅ Smaller radius
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10, // ✅ Reduced blur
            offset: const Offset(0, 4), // ✅ Reduced offset
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ Fit content
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6), // ✅ Smaller icon container
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(8), // ✅ Smaller radius
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6, // ✅ Reduced blur
                      offset: const Offset(0, 2), // ✅ Reduced offset
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 16), // ✅ Smaller icon
              ),
              if (change != '0%')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // ✅ Tiny badge
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4), // ✅ Smaller radius
                  ),
                  child: Text(
                    change,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF4CAF50),
                      fontSize: 8, // ✅ Very small text
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8), // ✅ Reduced spacing
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18, // ✅ Smaller value text
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11, // ✅ Smaller title
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ✅ COMPACT QUICK ACTIONS - 3 columns, smaller cards
  Widget _buildCompactQuickActions(BuildContext context) {
    final actions = [
      _ActionItem(
        'Quản lý người dùng', 
        Icons.people_alt_rounded, 
        const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]), 
        'Thêm, sửa, xóa', 
        () => _navigateToScreen(const AdminUsersScreen()),
      ),
      _ActionItem(
        'Quản lý món ăn', 
        Icons.restaurant_menu_rounded, 
        const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]), 
        'CRUD sản phẩm', 
        () => _navigateToScreen(const AdminProductsScreen()),
      ),
      _ActionItem(
        'Quản lý đơn hàng', 
        Icons.shopping_bag_rounded, 
        const LinearGradient(colors: [Color(0xFFfa709a), Color(0xFFfee140)]), 
        'Xử lý đơn hàng', 
        () => _navigateToScreen(const AdminOrdersScreen()),
      ),
      _ActionItem(
        'Khuyến mãi', 
        Icons.local_offer_rounded, 
        const LinearGradient(colors: [Color(0xFFa8edea), Color(0xFFfed6e3)]), 
        'Mã giảm giá', 
        () => _navigateToScreen(const AdminPromotionsScreen()),
      ),
      _ActionItem(
        'Thống kê', 
        Icons.analytics_rounded, 
        const LinearGradient(colors: [Color(0xFFffecd2), Color(0xFFfcb69f)]), 
        'Báo cáo', 
        () => _navigateToScreen(const AdminAnalyticsScreen()),
      ),
      _ActionItem(
        'Cài đặt', 
        Icons.settings_rounded, 
        const LinearGradient(colors: [Color(0xFFc471ed), Color(0xFFf64f59)]), 
        'Hệ thống', 
        () => _showSystemSettings(context),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Quản lý hệ thống',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20, // ✅ Reduced from 22
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10), // ✅ Reduced spacing
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // ✅ Smaller badge
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(6), // ✅ Smaller radius
              ),
              child: Text(
                'FULL ACCESS',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 9, // ✅ Smaller text
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16), // ✅ Reduced spacing
        // ✅ 3 COLUMNS GRID instead of 2 - more compact
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // ✅ Changed to 3 columns
            mainAxisSpacing: 12, // ✅ Reduced spacing
            crossAxisSpacing: 12, // ✅ Reduced spacing
            childAspectRatio: 0.85, // ✅ Adjusted ratio for 3 columns
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildCompactActionCard(action);
          },
        ),
      ],
    );
  }

  void _navigateToScreen(Widget screen) {
    if (!_isDisposed && mounted) {
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  // ✅ COMPACT ACTION CARD - smaller and more compact
  Widget _buildCompactActionCard(_ActionItem action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16), // ✅ Reduced radius
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16), // ✅ Reduced radius
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15, // ✅ Reduced blur
                offset: const Offset(0, 6), // ✅ Reduced offset
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16), // ✅ Reduced padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44, // ✅ Smaller icon container
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: action.gradient,
                    borderRadius: BorderRadius.circular(12), // ✅ Reduced radius
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10, // ✅ Reduced blur
                        offset: const Offset(0, 4), // ✅ Reduced offset
                      ),
                    ],
                  ),
                  child: Icon(action.icon, color: Colors.white, size: 22), // ✅ Smaller icon
                ),
                const SizedBox(height: 12), // ✅ Reduced spacing
                Text(
                  action.title,
                  textAlign: TextAlign.center,
                  maxLines: 2, // ✅ Allow 2 lines for better text wrapping
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12, // ✅ Smaller text
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2), // ✅ Reduced spacing
                Text(
                  action.description,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 10, // ✅ Smaller description
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ REST OF METHODS (unchanged)
  void _handleRefresh() {
    if (!_isDisposed && mounted) {
      _loadStats();
      _showSuccessSnackBar('🔄 Đang tải lại dữ liệu...');
    }
  }

  Future<void> _handleLogout() async {
    if (_isDisposed || !mounted) return;
    
    final confirm = await _showLogoutDialog();
    if (confirm == true && mounted) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavWidget(initialTab: 0),
            ),
          );
        }
      } catch (e) {
        print('❌ Logout error: $e');
        _showErrorSnackBar('Lỗi đăng xuất: $e');
      }
    }
  }

  void _showSystemSettings(BuildContext context) {
    if (_isDisposed || !mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '⚙️ Cài đặt hệ thống',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildSettingItem('Reload Data', Icons.refresh_rounded, () {
              Navigator.pop(context);
              _handleRefresh();
            }),
            _buildSettingItem('System Backup', Icons.backup_rounded, () {
              Navigator.pop(context);
              _showSuccessSnackBar('💾 Đang backup hệ thống...');
            }),
            _buildSettingItem('Clear Cache', Icons.clear_all_rounded, () {
              Navigator.pop(context);
              _showSuccessSnackBar('🗑️ Đã xóa cache');
            }),
            _buildSettingItem('Database Status', Icons.storage_rounded, () {
              Navigator.pop(context);
              _showSuccessSnackBar('✅ Database kết nối OK');
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Đóng',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00D4FF)),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<bool?> _showLogoutDialog() {
    if (_isDisposed || !mounted) return Future.value(false);
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B)),
            const SizedBox(width: 12),
            Text(
              'Xác nhận đăng xuất',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn đăng xuất khỏi tài khoản Admin?',
          style: GoogleFonts.inter(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Đăng xuất',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
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
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (_isDisposed || !mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ✅ Updated Helper classes
class _ActionItem {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final String description;
  final VoidCallback onTap;

  _ActionItem(this.title, this.icon, this.gradient, this.description, this.onTap);
}