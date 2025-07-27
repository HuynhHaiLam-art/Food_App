import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../services/promotion_api_service.dart';
import '../themes/admin_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  late Future<List<Promotion>> _promotionsFuture;
  String _searchQuery = '';
  String _selectedType = 'All';
  final List<String> _types = ['All', 'Discount', 'Free Shipping', 'Buy One Get One'];
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _loadPromotions() {
    if (_isDisposed) return;
    print('🔄 Loading promotions...');
    _promotionsFuture = PromotionApiService().getAllPromotions();
  }

  Future<void> _deletePromotion(int promotionId) async {
    if (_isDisposed) return;
    
    final confirm = await _showDeleteDialog('khuyến mãi #$promotionId');
    if (confirm == true) {
      try {
        await PromotionApiService().deletePromotion(promotionId);
        if (!_isDisposed && mounted) {
          _loadPromotions();
          setState(() {});
          _showSuccessSnackBar('✅ Đã xóa khuyến mãi #$promotionId');
        }
      } catch (e) {
        if (!_isDisposed && mounted) {
          _showErrorSnackBar('❌ Lỗi xóa khuyến mãi: $e');
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
              Expanded(child: _buildPromotionsList()),
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
                Text('🎯 Quản lý khuyến mãi', style: AdminTheme.displayMedium),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tạo & quản lý mã giảm giá',
                    style: GoogleFonts.roboto(
                      color: const Color(0xFF9C27B0), 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddPromotionDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm mới'),
            style: AdminTheme.successButtonStyle,
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
                  hintText: 'Tìm mã khuyến mãi...',
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
                value: _selectedType,
                dropdownColor: AdminTheme.cardBackground,
                style: AdminTheme.bodyLarge,
                underline: Container(),
                isExpanded: true,
                items: _types.map((type) => DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      _getTypeIcon(type),
                      const SizedBox(width: 8),
                      Text(type),
                    ],
                  ),
                )).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsList() {
    return FutureBuilder<List<Promotion>>(
      future: _promotionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF9C27B0)),
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
                  'Lỗi tải khuyến mãi: ${snapshot.error}',
                  style: AdminTheme.bodyLarge.copyWith(color: AdminTheme.warningRed),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (!_isDisposed) {
                      _loadPromotions();
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

        var promotions = snapshot.data ?? [];
        
        // Filter promotions
        if (_searchQuery.isNotEmpty) {
          promotions = promotions.where((promotion) => 
            (promotion.code?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (promotion.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
          ).toList();
        }
        if (_selectedType != 'All') {
          promotions = promotions.where((promotion) => promotion.type == _selectedType).toList();
        }

        if (promotions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_offer, color: Colors.white54, size: 64),
                const SizedBox(height: 16),
                Text('Chưa có khuyến mãi nào', style: AdminTheme.headlineLarge),
                const SizedBox(height: 8),
                Text('Tạo khuyến mãi đầu tiên để thu hút khách hàng!', style: AdminTheme.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddPromotionDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo khuyến mãi'),
                  style: AdminTheme.successButtonStyle,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (!_isDisposed) {
              _loadPromotions();
              setState(() {});
            }
          },
          color: const Color(0xFF9C27B0),
          backgroundColor: AdminTheme.cardBackground,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final promotion = promotions[index];
              return _buildPromotionCard(promotion);
            },
          ),
        );
      },
    );
  }

  Widget _buildPromotionCard(Promotion promotion) {
    final isActive = promotion.isActive ?? true;
    final isExpired = promotion.endDate != null && promotion.endDate!.isBefore(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AdminTheme.adminCardDecoration.copyWith(
        border: Border.all(
          color: isActive && !isExpired 
            ? AdminTheme.successGreen.withOpacity(0.3)
            : AdminTheme.warningRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Promotion Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_offer, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promotion.code ?? 'N/A',
                          style: AdminTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          promotion.type ?? 'Discount',
                          style: AdminTheme.bodyMedium.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildStatusChip(isActive, isExpired),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Promotion Details
            if (promotion.description != null) ...[
              Text(
                promotion.description!,
                style: AdminTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            
            Row(
              children: [
                if (promotion.discountValue != null) ...[
                  const Icon(Icons.percent, color: Color(0xFF9C27B0), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Giảm ${promotion.discountValue}%',
                    style: AdminTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9C27B0),
                    ),
                  ),
                ],
                const Spacer(),
                if (promotion.endDate != null) ...[
                  const Icon(Icons.schedule, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Đến ${_formatDate(promotion.endDate!)}',
                    style: AdminTheme.bodyMedium.copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditPromotionDialog(promotion),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Sửa'),
                    style: AdminTheme.primaryButtonStyle.copyWith(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AdminTheme.warningRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _deletePromotion(promotion.id!),
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

  Widget _buildStatusChip(bool isActive, bool isExpired) {
    Color color;
    String text;
    IconData icon;
    
    if (isExpired) {
      color = AdminTheme.warningRed;
      text = 'Hết hạn';
      icon = Icons.access_time;
    } else if (isActive) {
      color = AdminTheme.successGreen;
      text = 'Đang hoạt động';
      icon = Icons.check_circle;
    } else {
      color = Colors.orange;
      text = 'Tạm dừng';
      icon = Icons.pause_circle;
    }
    
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
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
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

  Widget _getTypeIcon(String type) {
    IconData icon;
    switch (type) {
      case 'Discount': icon = Icons.percent; break;
      case 'Free Shipping': icon = Icons.local_shipping; break;
      case 'Buy One Get One': icon = Icons.redeem; break;
      default: icon = Icons.local_offer;
    }
    return Icon(icon, color: const Color(0xFF9C27B0), size: 16);
  }

  void _showAddPromotionDialog() {
    _showPromotionDialog();
  }

  void _showEditPromotionDialog(Promotion promotion) {
    _showPromotionDialog(promotion: promotion);
  }

  void _showPromotionDialog({Promotion? promotion}) {
    if (_isDisposed) return;
    
    final isEdit = promotion != null;
    final codeController = TextEditingController(text: promotion?.code ?? '');
    final descriptionController = TextEditingController(text: promotion?.description ?? '');
    final discountController = TextEditingController(text: promotion?.discountValue?.toString() ?? '');
    String selectedType = promotion?.type ?? 'Discount';
    bool isActive = promotion?.isActive ?? true;
    DateTime? endDate = promotion?.endDate;

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
                isEdit ? 'Sửa khuyến mãi' : 'Thêm khuyến mãi mới',
                style: AdminTheme.headlineLarge,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(codeController, 'Mã khuyến mãi', Icons.local_offer),
                  const SizedBox(height: 16),
                  _buildDialogTextField(descriptionController, 'Mô tả', Icons.description),
                  const SizedBox(height: 16),
                  _buildDialogTextField(discountController, 'Giá trị giảm (%)', Icons.percent),
                  const SizedBox(height: 16),
                  
                  // Type Dropdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: selectedType,
                      dropdownColor: AdminTheme.cardBackground,
                      style: AdminTheme.bodyLarge,
                      underline: Container(),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                      items: ['Discount', 'Free Shipping', 'Buy One Get One'].map((type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            _getTypeIcon(type),
                            const SizedBox(width: 8),
                            Text(type),
                          ],
                        ),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedType = value);
                        }
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Active Toggle
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kích hoạt ngay', style: AdminTheme.bodyLarge),
                        Switch(
                          value: isActive,
                          activeColor: AdminTheme.successGreen,
                          onChanged: (value) {
                            setDialogState(() => isActive = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // End Date Picker
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF9C27B0),
                                surface: AdminTheme.cardBackground,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setDialogState(() => endDate = date);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white70),
                          const SizedBox(width: 12),
                          Text(
                            endDate != null 
                              ? 'Hết hạn: ${_formatDate(endDate!)}'
                              : 'Chọn ngày hết hạn',
                            style: AdminTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: AdminTheme.bodyMedium),
            ),
            ElevatedButton(
              onPressed: () async {
                if (codeController.text.isEmpty || descriptionController.text.isEmpty) {
                  _showErrorSnackBar('Vui lòng điền đầy đủ thông tin');
                  return;
                }

                try {
                  final promotionData = Promotion(
                    id: promotion?.id,
                    code: codeController.text,
                    description: descriptionController.text,
                    type: selectedType,
                    discountValue: double.tryParse(discountController.text),
                    isActive: isActive,
                    endDate: endDate,
                  );

                  if (isEdit) {
                    await PromotionApiService().updatePromotion(promotion.id!, promotionData);
                    _showSuccessSnackBar('✅ Đã cập nhật khuyến mãi');
                  } else {
                    await PromotionApiService().createPromotion(promotionData);
                    _showSuccessSnackBar('✅ Đã tạo khuyến mãi mới');
                  }
                  
                  if (!_isDisposed && mounted) {
                    _loadPromotions();
                    setState(() {});
                    Navigator.pop(context);
                  }
                } catch (e) {
                  _showErrorSnackBar('❌ Lỗi: $e');
                }
              },
              style: isEdit ? AdminTheme.primaryButtonStyle : AdminTheme.successButtonStyle,
              child: Text(isEdit ? 'Cập nhật' : 'Tạo mới'),
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
  ) {
    return TextField(
      controller: controller,
      style: AdminTheme.bodyLarge,
      decoration: AdminTheme.adminInputDecoration(
        label: label,
        icon: icon,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
          'Bạn có chắc muốn xóa $itemName?\n\nKhuyến mãi sẽ bị xóa vĩnh viễn!',
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