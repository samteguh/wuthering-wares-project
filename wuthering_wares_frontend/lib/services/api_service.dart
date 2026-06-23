import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/equipment.dart';
import '../models/cart_item.dart';

class ApiService {
  static const String baseUrl = kIsWeb
      ? 'http://localhost:3000/api'
      : 'http://10.0.2.2:3000/api';

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<List<Equipment>> getEquipments() async {
    final response = await http
        .get(Uri.parse('$baseUrl/equipments'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Equipment.fromJson(json)).toList();
    }
    throw Exception('Failed to load equipments: ${response.body}');
  }

  Future<Equipment> getEquipment(int id) async {
    final response = await http
        .get(Uri.parse('$baseUrl/equipments/$id'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return Equipment.fromJson(json.decode(response.body));
    }
    throw Exception('Equipment not found');
  }

  Future<Equipment> createEquipment(Map<String, dynamic> equipmentData) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/equipments'),
          headers: _headers,
          body: json.encode(equipmentData),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Equipment.fromJson(data['equipment']);
    }
    final err = json.decode(response.body);
    throw Exception(err['error'] ?? 'Failed to create equipment');
  }

  Future<Equipment> updateEquipment(
      int id, Map<String, dynamic> equipmentData) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/equipments/$id'),
          headers: _headers,
          body: json.encode(equipmentData),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Equipment.fromJson(data['equipment']);
    }
    final err = json.decode(response.body);
    throw Exception(err['error'] ?? 'Failed to update equipment');
  }

  Future<void> deleteEquipment(int id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/equipments/$id'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final err = json.decode(response.body);
      throw Exception(err['error'] ?? 'Failed to delete equipment');
    }
  }

  Future<bool> purchaseEquipment(int equipmentId, int quantity) async {
    debugPrint('🛒 Attempting purchase: equipmentId=$equipmentId, quantity=$quantity');
    debugPrint('🔑 Has token: ${_authToken != null}');
    
    final response = await http
        .post(
          Uri.parse('$baseUrl/orders'),
          headers: _headers,
          body: json.encode({
            'equipment_id': equipmentId,
            'quantity': quantity,
          }),
        )
        .timeout(const Duration(seconds: 10));

    debugPrint('📡 Response status: ${response.statusCode}');
    debugPrint('📡 Response body: ${response.body}');

    if (response.statusCode == 201) {
      debugPrint('✅ Purchase successful! Stock should be reduced.');
      return true;
    }
    
    try {
      final err = json.decode(response.body);
      throw Exception(err['error'] ?? 'Order failed');
    } catch (e) {
      throw Exception('Purchase failed: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final response = await http
        .get(Uri.parse('$baseUrl/orders'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load orders');
  }

  Future<List<CartItemModel>> getCart() async => [];
  Future<void> updateCartItem(int cartItemId, int quantity) async {}
  Future<void> removeCartItem(int cartItemId) async {}
  Future<bool> checkout() async => true;
}