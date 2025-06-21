import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/cartitem.dart';

class CartItemApiService {
  static const String _baseUrl = 'http://localhost:5062/api/CartItem';
  static const Duration _timeoutDuration = Duration(seconds: 10);

  Map<String, String> _getHeaders({String? token}) {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Lấy danh sách CartItem theo userId
  Future<List<CartItem>> getCartItems(int userId, {String? token}) async {
    final uri = Uri.parse('$_baseUrl/user/$userId');
    try {
      final response = await http
          .get(uri, headers: _getHeaders(token: token))
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          return data.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
        } on FormatException catch (e) {
          print('Error parsing cart items JSON: $e');
          throw Exception('Dữ liệu giỏ hàng trả về không hợp lệ.');
        }
      } else {
        print('Failed to load cart items: ${response.statusCode}, body: ${response.body}');
        throw Exception('Lỗi tải giỏ hàng (mã: ${response.statusCode}).');
      }
    } on SocketException {
      print('No Internet connection for getCartItems');
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      print('Request to getCartItems timed out');
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      print('Unexpected error in getCartItems: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn khi tải giỏ hàng.');
    }
  }

  /// Thêm sản phẩm vào giỏ hàng
  Future<CartItem> addCartItem(CartItem item, {String? token}) async {
    final uri = Uri.parse(_baseUrl);
    try {
      final response = await http
          .post(
            uri,
            headers: _getHeaders(token: token),
            body: json.encode(item.toJson()),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          return CartItem.fromJson(json.decode(response.body) as Map<String, dynamic>);
        } on FormatException catch (e) {
          print('Error parsing added cart item JSON: $e');
          throw Exception('Dữ liệu sản phẩm thêm vào giỏ hàng không hợp lệ.');
        }
      } else {
        print('Failed to add cart item: ${response.statusCode}, body: ${response.body}');
        throw Exception('Thêm sản phẩm vào giỏ hàng thất bại (mã: ${response.statusCode}).');
      }
    } on SocketException {
      print('No Internet connection for addCartItem');
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      print('Request to addCartItem timed out');
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      print('Unexpected error in addCartItem: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn khi thêm sản phẩm.');
    }
  }

  /// Cập nhật sản phẩm trong giỏ hàng
  Future<void> updateCartItem(CartItem item, {String? token}) async {
    if (item.id == null) {
      throw ArgumentError('CartItem ID cannot be null for update.');
    }
    final uri = Uri.parse('$_baseUrl/${item.id}');
    try {
      final response = await http
          .put(
            uri,
            headers: _getHeaders(token: token),
            body: json.encode(item.toJson()),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode != 204 && response.statusCode != 200) {
        print('Failed to update cart item: ${response.statusCode}, body: ${response.body}');
        throw Exception('Cập nhật giỏ hàng thất bại (mã: ${response.statusCode}).');
      }
    } on SocketException {
      print('No Internet connection for updateCartItem');
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      print('Request to updateCartItem timed out');
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      print('Unexpected error in updateCartItem: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn khi cập nhật giỏ hàng.');
    }
  }

  /// Xóa sản phẩm khỏi giỏ hàng
  Future<void> deleteCartItem(int cartItemId, {String? token}) async {
    final uri = Uri.parse('$_baseUrl/$cartItemId');
    try {
      final response = await http
          .delete(uri, headers: _getHeaders(token: token))
          .timeout(_timeoutDuration);

      if (response.statusCode != 204 && response.statusCode != 200) {
        print('Failed to delete cart item: ${response.statusCode}, body: ${response.body}');
        throw Exception('Xóa sản phẩm khỏi giỏ hàng thất bại (mã: ${response.statusCode}).');
      }
    } on SocketException {
      print('No Internet connection for deleteCartItem');
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      print('Request to deleteCartItem timed out');
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      print('Unexpected error in deleteCartItem: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn khi xóa sản phẩm.');
    }
  }

  /// Xóa toàn bộ giỏ hàng của user (nếu backend hỗ trợ endpoint này)
  Future<void> clearUserCart(int userId, {String? token}) async {
    final uri = Uri.parse('$_baseUrl/user/$userId');
    try {
      final response = await http
          .delete(uri, headers: _getHeaders(token: token))
          .timeout(_timeoutDuration);

      if (response.statusCode != 204 && response.statusCode != 200) {
        print('Failed to clear user cart: ${response.statusCode}, body: ${response.body}');
        throw Exception('Xóa toàn bộ giỏ hàng thất bại (mã: ${response.statusCode}).');
      }
    } on SocketException {
      print('No Internet connection for clearUserCart');
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      print('Request to clearUserCart timed out');
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      print('Unexpected error in clearUserCart: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn khi xóa toàn bộ giỏ hàng.');
    }
  }
}