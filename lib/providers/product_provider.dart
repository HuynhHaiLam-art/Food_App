import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductApiService _apiService;
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  ProductProvider(this._apiService);

  // Getters
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all products
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _apiService.getProducts();
      _errorMessage = null;
      print('📦 Loaded ${_products.length} products');
    } catch (e) {
      _errorMessage = e.toString();
      _products = [];
      print('❌ Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get products by category
  List<Product> getProductsByCategory(int categoryId) {
    return _products.where((product) => product.categoryId == categoryId).toList();
  }

  // Get product by ID
  Product? getProductById(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search products
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    
    return _products.where((product) {
      final name = product.name?.toLowerCase() ?? '';
      final description = product.description?.toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();
      
      return name.contains(searchQuery) || description.contains(searchQuery);
    }).toList();
  }

  // Refresh products
  Future<void> refreshProducts() async {
    await loadProducts();
  }

  // Add product (for admin)
  Future<void> addProduct(Product product) async {
    try {
      final newProduct = await _apiService.createProduct(product);
      _products.add(newProduct);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update product (for admin)
  Future<void> updateProduct(Product product) async {
    try {
      final updatedProduct = await _apiService.updateProduct(product.id!, product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete product (for admin)
  Future<void> deleteProduct(int productId) async {
    try {
      await _apiService.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}