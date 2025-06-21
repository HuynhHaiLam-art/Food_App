import 'package:flutter/material.dart';

class FavoriteProvider extends ChangeNotifier {
  final List<int> _favoriteProductIds = [];

  List<int> get favoriteProductIds => List.unmodifiable(_favoriteProductIds);

  void toggleFavorite(int productId) {
    if (_favoriteProductIds.contains(productId)) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    notifyListeners();
  }

  bool isFavorite(int productId) {
    return _favoriteProductIds.contains(productId);
  }

  void clearFavorites() {
    _favoriteProductIds.clear();
    notifyListeners();
  }
}