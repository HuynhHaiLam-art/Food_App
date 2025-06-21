import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> get products => _products;

  void setProducts(List<Product> products) {
    _products = products;
    notifyListeners();
  }

  void clear() {
    _products = [];
    notifyListeners();
  }
}