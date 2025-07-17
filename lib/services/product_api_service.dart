import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductApiService {
  static const String _baseUrl = 'http://localhost:5062/api/Food';
  static const Duration _timeoutDuration = Duration(seconds: 30);

  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'accept': 'text/plain',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<Product>> getProducts({String? token}) async {
    try {
      print('🍔 Getting products with token: ${token?.substring(0, 20)}...');
      
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token: token),
      ).timeout(_timeoutDuration);

      print('📦 Products Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi tải sản phẩm: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ GetProducts Error: $e');
      rethrow;
    }
  }

  Future<Product> createProduct(Product product, {String? token}) async {
    try {
      print('➕ Creating product: ${product.toJson()}');
      
      final productData = {
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'categoryId': product.categoryId ?? 2,
      };
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token: token),
        body: json.encode(productData),
      ).timeout(_timeoutDuration);

      print('🆕 Create Product Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw Exception('Tạo sản phẩm thất bại: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ CreateProduct Error: $e');
      rethrow;
    }
  }

  // ✅ SỬA: Update Product - Không dùng copyWith
  Future<Product> updateProduct(int id, Product product, {String? token}) async {
    try {
      print('✏️ Updating product $id: ${product.toJson()}');
      
      final productData = {
        'id': id,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'categoryId': product.categoryId ?? 2,
      };
      
      final response = await http.put(
        Uri.parse('$_baseUrl/$id'),
        headers: _getHeaders(token: token),
        body: json.encode(productData),
      ).timeout(_timeoutDuration);

      print('🔄 Update Product Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.statusCode == 204 || response.body.isEmpty) {
          // ✅ SỬA: Tạo Product object mới thay vì dùng copyWith
          return Product(
            id: id,
            name: product.name,
            description: product.description,
            price: product.price,
            imageUrl: product.imageUrl,
            categoryId: product.categoryId ?? 2,
            categoryName: product.categoryName,
          );
        } else {
          return Product.fromJson(json.decode(response.body));
        }
      } else {
        throw Exception('Cập nhật sản phẩm thất bại: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ UpdateProduct Error: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(int id, {String? token}) async {
    try {
      print('🗑️ Deleting product $id');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: _getHeaders(token: token),
      ).timeout(_timeoutDuration);

      print('❌ Delete Product Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Xóa sản phẩm thất bại: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ DeleteProduct Error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCategories({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5062/api/Category'),
        headers: _getHeaders(token: token),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        return [
          {'id': 1, 'name': 'Pizza'},
          {'id': 2, 'name': 'Burger'},
          {'id': 3, 'name': 'Pasta'},
          {'id': 4, 'name': 'Salad'},
        ];
      }
    } catch (e) {
      return [
        {'id': 1, 'name': 'Pizza'},
        {'id': 2, 'name': 'Burger'},
        {'id': 3, 'name': 'Pasta'},
        {'id': 4, 'name': 'Salad'},
      ];
    }
  }

  Future<List<Product>> fetchProducts({String? token}) async {
    return getProducts(token: token);
  }

  Future<List<Product>> getProductsByCategory(int categoryId, {String? token}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/category/$categoryId'),
      headers: _getHeaders(token: token),
    ).timeout(_timeoutDuration);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi khi tải sản phẩm theo danh mục.');
    }
  }

  Future<Product> getProductById(int id, {String? token}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$id'),
      headers: _getHeaders(token: token),
    ).timeout(_timeoutDuration);

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Lỗi khi lấy chi tiết sản phẩm.');
    }
  }
}