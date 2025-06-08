import 'dart:convert';
import 'dart:io'; // For SocketException
import 'dart:async'; // For TimeoutException
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductApiService {
  // Nên lấy từ một file config hoặc biến môi trường
  static const String _baseUrl = 'http://localhost:5062/api/Food';
  static const Duration _timeoutDuration = Duration(seconds: 10);

  // Helper để tạo headers, có thể thêm token nếu cần cho các CUD operations
  Map<String, String> _getHeaders({String? token, bool isJsonContent = false}) {
    final headers = <String, String>{};
    if (isJsonContent) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<Product>> fetchProducts() async {
    final uri = Uri.parse(_baseUrl);
    try {
      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        try {
          final List<dynamic> body = json.decode(response.body);
          return body.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
        } on FormatException catch (e) {
          print('Error parsing products JSON: $e');
          throw Exception('Dữ liệu sản phẩm trả về không hợp lệ.');
        }
      } else {
        print('Failed to load products: ${response.statusCode}, body: ${response.body}');
        throw Exception('Lỗi tải danh sách sản phẩm (mã: ${response.statusCode}).');
      }
    } on SocketException {
      print('No Internet connection for fetchProducts');
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      print('Request to fetchProducts timed out');
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      print('Unexpected error in fetchProducts: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn khi tải sản phẩm.');
    }
  }

  Future<Product> fetchProductById(int id) async {
    final uri = Uri.parse('$_baseUrl/$id');
    try {
      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        try {
          return Product.fromJson(json.decode(response.body) as Map<String, dynamic>);
        } on FormatException catch (e) {
          print('Error parsing product by ID JSON: $e');
          throw Exception('Dữ liệu sản phẩm trả về không hợp lệ.');
        }
      } else {
        print('Failed to load product by ID $id: ${response.statusCode}, body: ${response.body}');
        throw Exception('Lỗi tải chi tiết sản phẩm (mã: ${response.statusCode}).');
      }
    } on SocketException {
      print('No Internet connection for fetchProductById');
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      print('Request to fetchProductById timed out');
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      print('Unexpected error in fetchProductById for ID $id: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn khi tải chi tiết sản phẩm.');
    }
  }

  // Các hàm create, update, delete có thể yêu cầu token xác thực
  Future<Product> createProduct(Product product, {String? token}) async {
    final uri = Uri.parse(_baseUrl);
    try {
      final response = await http
          .post(
            uri,
            headers: _getHeaders(token: token, isJsonContent: true),
            body: json.encode(product.toJson()),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 201 || response.statusCode == 200) { // 201 Created or 200 OK
        try {
          return Product.fromJson(json.decode(response.body) as Map<String, dynamic>);
        } on FormatException catch (e) {
          print('Error parsing created product JSON: $e');
          throw Exception('Dữ liệu sản phẩm tạo mới không hợp lệ.');
        }
      } else {
        print('Failed to create product: ${response.statusCode}, body: ${response.body}');
        throw Exception('Tạo sản phẩm thất bại (mã: ${response.statusCode}).');
      }
    } on SocketException {
      print('No Internet connection for createProduct');
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      print('Request to createProduct timed out');
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      print('Unexpected error in createProduct: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn khi tạo sản phẩm.');
    }
  }

  Future<Product> updateProduct(Product product, {String? token}) async {
    if (product.id == null) {
      throw ArgumentError('Product ID cannot be null for update.');
    }
    final uri = Uri.parse('$_baseUrl/${product.id}');
    try {
      final response = await http
          .put(
            uri,
            headers: _getHeaders(token: token, isJsonContent: true),
            body: json.encode(product.toJson()),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) { // Hoặc 204 No Content nếu API không trả về body
        try {
          // Nếu API trả về 204, response.body sẽ rỗng và json.decode sẽ lỗi.
          // Cần kiểm tra response.body trước khi decode nếu có khả năng là 204.
          if (response.body.isEmpty && response.statusCode == 204) {
             // Nếu là 204 và không có body, có thể trả về product đã gửi đi
             // hoặc yêu cầu API trả về 200 với body.
             // Ở đây, giả sử API trả về 200 với body.
             throw Exception('Cập nhật thành công nhưng không có nội dung trả về (204).');
          }
          return Product.fromJson(json.decode(response.body) as Map<String, dynamic>);
        } on FormatException catch (e) {
          print('Error parsing updated product JSON: $e');
          throw Exception('Dữ liệu sản phẩm cập nhật không hợp lệ.');
        }
      } else if (response.statusCode == 204) {
        // Xử lý trường hợp 204 No Content (thành công nhưng không có body)
        // Có thể trả về product ban đầu hoặc một giá trị biểu thị thành công
        print('Product updated successfully (204 No Content). Returning original product.');
        return product; // Hoặc ném lỗi/trả về một cách khác tùy logic ứng dụng
      }
      else {
        print('Failed to update product: ${response.statusCode}, body: ${response.body}');
        throw Exception('Cập nhật sản phẩm thất bại (mã: ${response.statusCode}).');
      }
    } on SocketException {
      print('No Internet connection for updateProduct');
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      print('Request to updateProduct timed out');
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      print('Unexpected error in updateProduct for ID ${product.id}: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn khi cập nhật sản phẩm.');
    }
  }

  Future<void> deleteProduct(int id, {String? token}) async {
    final uri = Uri.parse('$_baseUrl/$id');
    try {
      final response = await http
          .delete(uri, headers: _getHeaders(token: token))
          .timeout(_timeoutDuration);

      // 200 OK, 202 Accepted, hoặc 204 No Content đều là thành công
      if (response.statusCode != 200 && response.statusCode != 202 && response.statusCode != 204) {
        print('Failed to delete product $id: ${response.statusCode}, body: ${response.body}');
        throw Exception('Xóa sản phẩm thất bại (mã: ${response.statusCode}).');
      }
      // Thành công, không cần làm gì thêm
    } on SocketException {
      print('No Internet connection for deleteProduct');
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      print('Request to deleteProduct timed out');
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      print('Unexpected error in deleteProduct for ID $id: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn khi xóa sản phẩm.');
    }
  }
}