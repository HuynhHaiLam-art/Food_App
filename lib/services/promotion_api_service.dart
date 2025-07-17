import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/promotion.dart';

class PromotionApiService {
  static const String _baseUrl = 'http://localhost:5062/api/Promotion';
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

  // ✅ Get active promotions for customers
  Future<List<Promotion>> getActivePromotions({String? token}) async {
    try {
      print('🔗 Getting active promotions...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/active'),
        headers: _getHeaders(token: token),
      ).timeout(_timeoutDuration);

      print('📥 Active Promotions Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final promotions = data.map((json) => Promotion.fromJson(json)).toList();
        print('✅ Loaded ${promotions.length} active promotions');
        return promotions;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Lỗi tải khuyến mãi: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ GetActivePromotions Error: $e');
      rethrow;
    }
  }

  // ✅ Validate promotion code
  Future<Promotion?> validatePromotionCode(String code, {String? token}) async {
    try {
      print('🔗 Validating promotion code: $code');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/validate/$code'),
        headers: _getHeaders(token: token),
      ).timeout(_timeoutDuration);

      print('📥 Validate Promotion Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final promotion = Promotion.fromJson(data);
        print('✅ Promotion code validated successfully');
        return promotion;
      } else if (response.statusCode == 404) {
        print('❌ Invalid promotion code');
        return null;
      } else {
        throw Exception('Lỗi xác thực mã: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ValidatePromotionCode Error: $e');
      rethrow;
    }
  }

  Future<List<Promotion>> getAllPromotions({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token: token),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Promotion.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi tải khuyến mãi: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ GetPromotions Error: $e');
      rethrow;
    }
  }

  Future<Promotion> createPromotion(Promotion promotion, {String? token}) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token: token),
        body: json.encode(promotion.toJson()),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Promotion.fromJson(json.decode(response.body));
      } else {
        throw Exception('Tạo khuyến mãi thất bại: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ CreatePromotion Error: $e');
      rethrow;
    }
  }

  Future<Promotion> updatePromotion(int id, Promotion promotion, {String? token}) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$id'),
        headers: _getHeaders(token: token),
        body: json.encode(promotion.toJson()),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.statusCode == 204 || response.body.isEmpty) {
          return promotion.copyWith(id: id);
        } else {
          return Promotion.fromJson(json.decode(response.body));
        }
      } else {
        throw Exception('Cập nhật khuyến mãi thất bại: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ UpdatePromotion Error: $e');
      rethrow;
    }
  }

  Future<void> deletePromotion(int id, {String? token}) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: _getHeaders(token: token),
      ).timeout(_timeoutDuration);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Xóa khuyến mãi thất bại: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ DeletePromotion Error: $e');
      rethrow;
    }
  }
}