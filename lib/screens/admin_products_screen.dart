import 'package:flutter/material.dart';
import '../services/product_api_service.dart';
import '../models/product.dart';
import '../utils/formatters.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  late Future<List<Product>> _productsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    // ✅ SỬA: Thêm token khi load products
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    print('🔄 Loading products with token: ${token?.substring(0, 20)}...');
    _productsFuture = ProductApiService().getProducts(token: token);
  }

  Future<void> _deleteProduct(int productId) async {
    final confirm = await _showDeleteDialog('sản phẩm');
    if (confirm == true) {
      try {
        // ✅ SỬA: Thêm token khi delete
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;
        
        await ProductApiService().deleteProduct(productId, token: token);
        _loadProducts();
        setState(() {});
        _showSuccessSnackBar('✅ Đã xóa sản phẩm khỏi database');
      } catch (e) {
        _showErrorSnackBar('❌ Lỗi xóa sản phẩm: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade900,
              Colors.purple.shade800,
              Colors.pink.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(child: _buildProductsList()),
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🍔 Quản lý món ăn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'CRUD Database',
                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddProductDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm món'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm món ăn...',
            hintStyle: TextStyle(color: Colors.white54),
            prefixIcon: Icon(Icons.search, color: Colors.white54),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadProducts(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        var products = snapshot.data ?? [];
        
        if (_searchQuery.isNotEmpty) {
          products = products.where((product) => 
            product.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false
          ).toList();
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadProducts();
            setState(() {});
          },
          color: Colors.white,
          backgroundColor: Colors.purple.shade700,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[700],
                        child: const Icon(Icons.fastfood, color: Colors.white54, size: 40),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[700],
                      child: const Icon(Icons.fastfood, color: Colors.white54, size: 40),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(product.price ?? 0),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (product.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description!,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${product.id}',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showEditProductDialog(product),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Sửa',
                ),
                IconButton(
                  onPressed: () => _deleteProduct(product.id!),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Xóa',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    _showProductDialog();
  }

  void _showEditProductDialog(Product product) {
    _showProductDialog(product: product);
  }

  void _showProductDialog({Product? product}) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product?.price?.toString() ?? '');
    final descriptionController = TextEditingController(text: product?.description ?? '');
    final imageUrlController = TextEditingController(text: product?.imageUrl ?? '');
    
    // ✅ THÊM: Category selection
    int selectedCategoryId = product?.categoryId ?? 2; // Default = Burger
    List<Map<String, dynamic>> categories = [
      {'id': 1, 'name': 'Pizza'},
      {'id': 2, 'name': 'Burger'},
      {'id': 3, 'name': 'Pasta'},
      {'id': 4, 'name': 'Salad'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(isEdit ? Icons.edit : Icons.add, color: isEdit ? Colors.blue : Colors.green),
              const SizedBox(width: 8),
              Text(
                isEdit ? 'Sửa món ăn' : 'Thêm món ăn mới',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(nameController, 'Tên món ăn', Icons.restaurant_menu),
                const SizedBox(height: 16),
                _buildDialogTextField(priceController, 'Giá (VNĐ)', Icons.attach_money, isNumber: true),
                const SizedBox(height: 16),
                _buildDialogTextField(descriptionController, 'Mô tả', Icons.description, maxLines: 3),
                const SizedBox(height: 16),
                _buildDialogTextField(imageUrlController, 'URL hình ảnh', Icons.image),
                const SizedBox(height: 16),
                // ✅ THÊM: Category dropdown
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
                    value: selectedCategoryId,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white),
                    underline: Container(),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                    items: categories.map((category) => DropdownMenuItem<int>(
                      value: category['id'],
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category['id']),
                            color: _getCategoryColor(category['id']),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category['name'],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedCategoryId = value);
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
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty) {
                  _showErrorSnackBar('Vui lòng điền tên và giá món ăn');
                  return;
                }

                final price = double.tryParse(priceController.text);
                if (price == null || price <= 0) {
                  _showErrorSnackBar('Giá không hợp lệ');
                  return;
                }

                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final token = authProvider.token;

                  final productData = Product(
                    id: product?.id,
                    name: nameController.text,
                    price: price,
                    description: descriptionController.text.isEmpty ? null : descriptionController.text,
                    imageUrl: imageUrlController.text.isEmpty ? null : imageUrlController.text,
                    categoryId: selectedCategoryId, // ✅ SỬA: Thêm categoryId
                  );

                  if (isEdit) {
                    await ProductApiService().updateProduct(product!.id!, productData, token: token);
                    _showSuccessSnackBar('✅ Đã cập nhật món ăn trong database');
                  } else {
                    await ProductApiService().createProduct(productData, token: token);
                    _showSuccessSnackBar('✅ Đã thêm món ăn vào database');
                  }
                  _loadProducts();
                  setState(() {});
                  Navigator.pop(context);
                } catch (e) {
                  _showErrorSnackBar('❌ Lỗi: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: isEdit ? Colors.blue : Colors.green),
              child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.green),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteDialog(String itemName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa $itemName này?\n\nDữ liệu sẽ bị xóa vĩnh viễn khỏi database!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // ✅ THÊM: Helper methods cho category icons
  IconData _getCategoryIcon(int categoryId) {
    switch (categoryId) {
      case 1: return Icons.local_pizza;
      case 2: return Icons.lunch_dining;
      case 3: return Icons.ramen_dining;
      case 4: return Icons.eco;
      default: return Icons.restaurant_menu;
    }
  }

  Color _getCategoryColor(int categoryId) {
    switch (categoryId) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow;
      case 4: return Colors.green;
      default: return Colors.blue;
    }
  }
}