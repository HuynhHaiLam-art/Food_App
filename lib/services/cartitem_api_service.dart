import 'dart:convert';
import 'dart:io'; // For SocketException
import 'dart:async'; // For TimeoutException
import 'package:http/http.dart' as http;
import '../models/cartitem.dart'; // Đảm bảo model Cartitem của bạn được định nghĩa đúng

class CartItemApiService {
  // Nên lấy từ một file config hoặc biến môi trường
  static const String _baseUrl = 'http://localhost:5062/api/CartItem';
  static const Duration _timeoutDuration = Duration(seconds: 10);

  // Helper để tạo headers, có thể thêm token nếu cần
  Map<String, String> _getHeaders({String? token}) {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<Cartitem>> getCartItems(int userId, {String? token}) async {
    final uri = Uri.parse('$_baseUrl/user/$userId');
    try {
      final response = await http
          .get(uri, headers: _getHeaders(token: token))
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          return data.map((e) => Cartitem.fromJson(e as Map<String, dynamic>)).toList();
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

  Future<Cartitem> addCartItem(Cartitem item, {String? token}) async {
    final uri = Uri.parse(_baseUrl);
    try {
      final response = await http
          .post(
            uri,
            headers: _getHeaders(token: token),
            body: json.encode(item.toJson()),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 201 || response.statusCode == 200) { // 201 Created or 200 OK
        try {
          return Cartitem.fromJson(json.decode(response.body) as Map<String, dynamic>);
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

  Future<void> updateCartItem(Cartitem item, {String? token}) async {
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

      // 204 No Content là phổ biến cho PUT thành công không trả về body
      // 200 OK nếu API trả về đối tượng đã cập nhật
      if (response.statusCode != 204 && response.statusCode != 200) {
        print('Failed to update cart item: ${response.statusCode}, body: ${response.body}');
        throw Exception('Cập nhật giỏ hàng thất bại (mã: ${response.statusCode}).');
      }
      // Không cần decode body nếu là 204
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

  Future<void> deleteCartItem(int cartItemId, {String? token}) async {
    final uri = Uri.parse('$_baseUrl/$cartItemId');
    try {
      final response = await http
          .delete(uri, headers: _getHeaders(token: token))
          .timeout(_timeoutDuration);

      // 204 No Content hoặc 200 OK (nếu API trả về thông báo)
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

  // Cân nhắc thêm phương thức xóa toàn bộ giỏ hàng của người dùng nếu API hỗ trợ
  // Future<void> clearUserCart(int userId, {String? token}) async { ... }
}