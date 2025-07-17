import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/order.dart';

class OrderApiService {
  static const String _baseUrl = 'http://localhost:5062/api/Order';
  static const Duration _timeoutDuration = Duration(seconds: 10);

  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ✅ Get status options from API
  Future<List<Map<String, dynamic>>> getStatusOptions({String? token}) async {
    try {
      print('🔗 Getting status options...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/status-options'),
        headers: _getHeaders(token: token),
      ).timeout(_timeoutDuration);

      print('📥 Status Options Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> options = data['statusOptions'] ?? [];
        return options.cast<Map<String, dynamic>>();
      } else {
        // Return default options if API fails
        return _getDefaultStatusOptions();
      }
    } catch (e) {
      print('❌ GetStatusOptions Error: $e');
      return _getDefaultStatusOptions();
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

  // ✅ Get user orders
  Future<List<Order>> getOrders(int userId, {String? token}) async {
    print('🔗 Loading orders for user $userId');
    
    try {
      // Try user-specific endpoint first
      final response = await http.get(
        Uri.parse('$_baseUrl/user/$userId'),
        headers: _getHeaders(token: token),
      ).timeout(_timeoutDuration);

      print('📥 User Orders Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final orders = jsonList.map((json) => Order.fromJson(json)).toList();
        print('✅ Loaded ${orders.length} orders for user $userId');
        return orders;
      } else if (response.statusCode == 404) {
        print('📭 No orders found for user $userId');
        return [];
      } else {
        throw Exception('Lỗi tải đơn hàng: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ GetOrders Error: $e');
      rethrow;
    }
  }

  // ✅ Get all orders (for admin)
  Future<List<Order>> getAllOrders({String? token}) async {
    print('🔗 Loading all orders (admin)');
    
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token: token),
      ).timeout(_timeoutDuration);

      print('📥 All Orders Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final orders = jsonList.map((json) => Order.fromJson(json)).toList();
        print('✅ Loaded ${orders.length} total orders');
        return orders;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Lỗi tải tất cả đơn hàng: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ GetAllOrders Error: $e');
      rethrow;
    }
  }

  // ✅ FIXED: Update order status with validation
  Future<void> updateOrderStatus(int orderId, String newStatus, {String? token}) async {
    print('🔗 Updating order $orderId status to $newStatus');
    
    try {
      // ✅ Validate status before sending
      final validStatuses = ['Pending', 'Processing', 'Delivered', 'Cancelled'];
      if (!validStatuses.contains(newStatus)) {
        throw Exception('Invalid status: $newStatus. Valid values: ${validStatuses.join(", ")}');
      }
      
      final statusData = {
        'status': newStatus, // ✅ Exact case matching
      };
      
      print('📤 Status update data: $statusData');
      
      final response = await http.put(
        Uri.parse('$_baseUrl/$orderId/status'),
        headers: _getHeaders(token: token),
        body: json.encode(statusData),
      ).timeout(_timeoutDuration);

      print('📥 Update Status Response: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Order status updated successfully');
        return;
      } else {
        throw Exception('Lỗi cập nhật trạng thái: ${response.statusCode} - ${response.body}');
      }
      
    } catch (e) {
      print('❌ UpdateOrderStatus Error: $e');
      rethrow;
    }
  }

  // ✅ Create order
  Future<Order> addOrder(Order order, {String? token}) async {
    print('🔗 Creating new order for user ${order.userId}');
    
    try {
      final orderJson = order.toJson();
      print('📤 Order data: $orderJson');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token: token),
        body: json.encode(orderJson),
      ).timeout(_timeoutDuration);

      print('📥 Create Order Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final createdOrder = Order.fromJson(responseData);
        print('✅ Order created successfully with ID: ${createdOrder.id}');
        return createdOrder;
      } else {
        throw Exception('Lỗi tạo đơn hàng: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ AddOrder Error: $e');
      rethrow;
    }
  }

  // ✅ Delete order
  Future<void> deleteOrder(int orderId, {String? token}) async {
    print('🔗 Deleting order $orderId');
    
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$orderId'),
        headers: _getHeaders(token: token),
      ).timeout(_timeoutDuration);

      print('📥 Delete Order Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 404) {
        print('✅ Order deleted successfully');
      } else {
        throw Exception('Lỗi xóa đơn hàng: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ DeleteOrder Error: $e');
      rethrow;
    }
  }

  // ✅ Quick status update methods
  Future<void> markPending(int orderId, {String? token}) => updateOrderStatus(orderId, 'Pending', token: token);
  Future<void> markProcessing(int orderId, {String? token}) => updateOrderStatus(orderId, 'Processing', token: token);
  Future<void> markDelivered(int orderId, {String? token}) => updateOrderStatus(orderId, 'Delivered', token: token);
  Future<void> markCancelled(int orderId, {String? token}) => updateOrderStatus(orderId, 'Cancelled', token: token);
}