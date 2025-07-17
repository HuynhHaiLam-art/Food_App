import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_api_service.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../themes/admin_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<User>> _usersFuture;
  String _searchQuery = '';
  String _selectedRole = 'All';
  final List<String> _roles = ['All', 'User', 'Admin'];
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _loadUsers() {
    if (_isDisposed) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    print('🔄 Loading users with token: ${token?.substring(0, 20)}...');
    _usersFuture = UserApiService().getAllUsers(token: token);
  }

  Future<void> _deleteUser(int userId) async {
    if (_isDisposed) return;
    
    final confirm = await _showDeleteDialog('người dùng');
    if (confirm == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;
        
        await UserApiService().deleteUser(userId, token: token);
        
        if (!_isDisposed && mounted) {
          _loadUsers();
          setState(() {});
          _showSuccessSnackBar('✅ Đã xóa người dùng khỏi database');
        }
      } catch (e) {
        if (!_isDisposed && mounted) {
          _showErrorSnackBar('❌ Lỗi xóa người dùng: $e');
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
              Expanded(child: _buildUsersList()),
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
                Text('👥 Quản lý người dùng', style: AdminTheme.displayMedium),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminTheme.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'CRUD Database with Auth',
                    style: GoogleFonts.roboto(
                      color: AdminTheme.primaryBlue, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: AdminTheme.adminButtonDecoration(color: AdminTheme.successGreen),
            child: ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm user'),
              style: AdminTheme.successButtonStyle,
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
                  hintText: 'Tìm kiếm người dùng...',
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
                value: _selectedRole,
                dropdownColor: AdminTheme.cardBackground,
                style: AdminTheme.bodyLarge,
                underline: Container(),
                isExpanded: true,
                items: _roles.map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(role),
                )).toList(),
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return FutureBuilder<List<User>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AdminTheme.primaryBlue),
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
                  'Lỗi: ${snapshot.error}',
                  style: AdminTheme.bodyLarge.copyWith(color: AdminTheme.warningRed),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (!_isDisposed) {
                      _loadUsers();
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

        var users = snapshot.data ?? [];
        
        // Filter users
        if (_searchQuery.isNotEmpty) {
          users = users.where((user) => 
            (user.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (user.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
          ).toList();
        }
        if (_selectedRole != 'All') {
          users = users.where((user) => user.role == _selectedRole).toList();
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (!_isDisposed) {
              _loadUsers();
              setState(() {});
            }
          },
          color: AdminTheme.primaryBlue,
          backgroundColor: AdminTheme.cardBackground,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserCard(user);
            },
          ),
        );
      },
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AdminTheme.adminCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: user.role == 'Admin' 
                    ? [AdminTheme.warningRed, AdminTheme.accentOrange]
                    : [AdminTheme.primaryBlue, AdminTheme.secondaryIndigo],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: (user.role == 'Admin' ? AdminTheme.warningRed : AdminTheme.primaryBlue).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                user.role == 'Admin' ? Icons.admin_panel_settings : Icons.person,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name ?? 'N/A',
                        style: AdminTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.role == 'Admin' 
                            ? AdminTheme.warningRed.withOpacity(0.2)
                            : AdminTheme.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.role ?? 'User',
                          style: GoogleFonts.roboto(
                            color: user.role == 'Admin' ? AdminTheme.warningRed : AdminTheme.primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? 'No email',
                    style: AdminTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${user.id}',
                    style: AdminTheme.bodyMedium.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AdminTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _showEditUserDialog(user),
                    icon: const Icon(Icons.edit, color: AdminTheme.primaryBlue),
                    tooltip: 'Sửa',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AdminTheme.warningRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _deleteUser(user.id!),
                    icon: const Icon(Icons.delete, color: AdminTheme.warningRed),
                    tooltip: 'Xóa',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    _showUserDialog();
  }

  void _showEditUserDialog(User user) {
    _showUserDialog(user: user);
  }

  void _showUserDialog({User? user}) {
    if (_isDisposed) return;
    
    final isEdit = user != null;
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController();
    
    // ✅ FIX: Ensure selectedRole is always valid
    String selectedRole = user?.role ?? 'User';
    // Validate role value
    if (!['User', 'Admin'].contains(selectedRole)) {
      selectedRole = 'User'; // Default to User if invalid
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AdminTheme.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit : Icons.add, 
                color: isEdit ? AdminTheme.primaryBlue : AdminTheme.successGreen,
              ),
              const SizedBox(width: 8),
              Text(
                isEdit ? 'Sửa người dùng' : 'Thêm người dùng mới',
                style: AdminTheme.headlineLarge,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(nameController, 'Tên người dùng', Icons.person),
                const SizedBox(height: 16),
                _buildDialogTextField(emailController, 'Email', Icons.email),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  passwordController, 
                  isEdit ? 'Mật khẩu mới (để trống nếu không đổi)' : 'Mật khẩu', 
                  Icons.lock, 
                  isPassword: true,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedRole,
                    dropdownColor: AdminTheme.cardBackground,
                    style: AdminTheme.bodyLarge,
                    underline: Container(),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                    // ✅ FIX: Use explicit list instead of mapping
                    items: [
                      DropdownMenuItem<String>(
                        value: 'User',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person,
                              color: AdminTheme.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text('User', style: AdminTheme.bodyLarge),
                          ],
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Admin',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              color: AdminTheme.warningRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text('Admin', style: AdminTheme.bodyLarge),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null && ['User', 'Admin'].contains(value)) {
                        setDialogState(() => selectedRole = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: AdminTheme.bodyMedium),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || emailController.text.isEmpty) {
                  _showErrorSnackBar('Vui lòng điền đầy đủ thông tin');
                  return;
                }

                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final token = authProvider.token;

                  if (isEdit) {
                    final updatedUser = User(
                      id: user!.id,
                      name: nameController.text,
                      email: emailController.text,
                      role: selectedRole,
                    );
                    await UserApiService().updateUser(user.id!, updatedUser, token: token);
                    _showSuccessSnackBar('✅ Đã cập nhật người dùng trong database');
                  } else {
                    if (passwordController.text.isEmpty) {
                      _showErrorSnackBar('Mật khẩu không được để trống');
                      return;
                    }
                    final newUser = User(
                      name: nameController.text,
                      email: emailController.text,
                      role: selectedRole,
                    );
                    await UserApiService().createUser(newUser, passwordController.text, token: token);
                    _showSuccessSnackBar('✅ Đã thêm người dùng vào database');
                  }
                  
                  if (!_isDisposed && mounted) {
                    _loadUsers();
                    setState(() {});
                    Navigator.pop(context);
                  }
                } catch (e) {
                  _showErrorSnackBar('❌ Lỗi: $e');
                }
              },
              style: isEdit ? AdminTheme.primaryButtonStyle : AdminTheme.successButtonStyle,
              child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {bool isPassword = false}
  ) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: AdminTheme.bodyLarge,
      decoration: AdminTheme.adminInputDecoration(
        label: label,
        icon: icon,
      ),
    );
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
          'Bạn có chắc muốn xóa $itemName này?\n\nDữ liệu sẽ bị xóa vĩnh viễn khỏi database!',
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
            Text(message),
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