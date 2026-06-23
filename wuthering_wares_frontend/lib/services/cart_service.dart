import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/equipment.dart';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _cartKey = 'shopping_cart';
  
  List<CartItemModel> _items = [];
  
  List<CartItemModel> get items => _items;

  List<CartItemModel> get selectedItems => _items.where((item) => item.isSelected).toList();

  double get selectedTotalPrice {
    return selectedItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  int get selectedQuantity {
    return selectedItems.fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> loadCart() async {
    final cartData = await _storage.read(key: _cartKey);
    if (cartData != null) {
      try {
        final List<dynamic> decoded = json.decode(cartData);
        _items = decoded.map((item) {
          return CartItemModel(
            id: item['id'],
            equipment: Equipment.fromJson(item['equipment']),
            quantity: item['quantity'],
            isSelected: item['isSelected'] ?? true,
          );
        }).toList();
      } catch (e) {
        debugPrint('Error loading cart: $e');
        _items = [];
      }
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final cartData = json.encode(_items.map((item) {
      return {
        'id': item.id,
        'equipment': item.equipment.toJson(),
        'quantity': item.quantity,
        'isSelected': item.isSelected,
      };
    }).toList());
    await _storage.write(key: _cartKey, value: cartData);
    notifyListeners();
  }

  Future<void> addToCart(Equipment equipment, int quantity) async {
    final existingIndex = _items.indexWhere((item) => item.equipment.id == equipment.id);
    
    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItemModel(
        id: DateTime.now().millisecondsSinceEpoch,
        equipment: equipment,
        quantity: quantity,
        isSelected: true,
      ));
    }
    
    await _saveCart();
  }

  Future<void> updateQuantity(int itemId, int newQuantity) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1 && newQuantity >= 1 && newQuantity <= _items[index].equipment.stock) {
      _items[index].quantity = newQuantity;
      await _saveCart();
    }
  }

  Future<void> toggleSelection(int itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index].isSelected = !_items[index].isSelected;
      await _saveCart();
    }
  }

  Future<void> selectAll(bool select) async {
    for (var item in _items) {
      item.isSelected = select;
    }
    await _saveCart();
  }

  Future<void> removeItem(int itemId) async {
    _items.removeWhere((item) => item.id == itemId);
    await _saveCart();
  }

  Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
  }

  Future<bool> checkoutSelected() async {
    if (selectedItems.isEmpty) {
      return false;
    }

    _items.removeWhere((item) => item.isSelected);
    await _saveCart();
    
    return true;
  }

Future<void> removeItems(List<int> itemIds) async {
  _items.removeWhere((item) => itemIds.contains(item.id));
  await _saveCart();
}
}