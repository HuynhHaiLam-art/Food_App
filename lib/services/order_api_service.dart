import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../models/orderdetail.dart';

class OrderApiService {
  static const String _baseUrl = 'http://localhost:5062/api/Order';
  static const Duration _timeoutDuration = Duration(seconds: 10);

  Map<String, String> _getHeaders({String? token}) {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<Order>> getOrders(int userId, {String? token}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl?userId=$userId'), // Đảm bảo có userId trên URL
      headers: _getHeaders(token: token),
    ).timeout(_timeoutDuration);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Đã xảy ra lỗi không mong muốn khi tải đơn hàng.');
    }
  }

  Future<Order> createOrder(Order order, {String? token}) async {
    final uri = Uri.parse(_baseUrl);

    // Kiểm tra dữ liệu đầu vào
    if (order.userId == null) {
      throw Exception('userId không được để trống khi tạo đơn hàng.');
    }
    if (order.status == null) {
      throw Exception('status không được để trống khi tạo đơn hàng.');
    }

    try {
      final jsonBody = order.toJson();
      print('Order gửi lên: ${json.encode(jsonBody)}');
      final response = await http
          .post(
            uri,
            headers: _getHeaders(token: token),
            body: json.encode(jsonBody),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Order.fromJson(json.decode(response.body) as Map<String, dynamic>);
      } else {
        print('OrderApiService.createOrder error: ${response.statusCode} - ${response.body}');
        throw Exception('Tạo đơn hàng thất bại (mã: ${response.statusCode}).\n${response.body}');
      }
    } on SocketException {
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      print('OrderApiService.createOrder unexpected error: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn khi tạo đơn hàng.\n$e');
    }
  }

  Future<Order> getOrderById(int orderId, {String? token}) async {
    final uri = Uri.parse('$_baseUrl/$orderId');
    try {
      final response = await http
          .get(uri, headers: _getHeaders(token: token))
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return Order.fromJson(json.decode(response.body) as Map<String, dynamic>);
      } else {
        print('OrderApiService.getOrderById error: ${response.statusCode} - ${response.body}');
        throw Exception('Không tìm thấy đơn hàng (mã: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      print('OrderApiService.getOrderById unexpected error: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn khi lấy đơn hàng.');
    }
  }

  Future<List<OrderDetail>> getOrderDetails(int orderId, {String? token}) async {
    final uri = Uri.parse('$_baseUrl/$orderId/details');
    try {
      final response = await http
          .get(uri, headers: _getHeaders(token: token))
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => OrderDetail.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        print('OrderApiService.getOrderDetails error: ${response.statusCode} - ${response.body}');
        throw Exception('Lỗi tải chi tiết đơn hàng (mã: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      print('OrderApiService.getOrderDetails unexpected error: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn khi tải chi tiết đơn hàng.');
    }
  }
}