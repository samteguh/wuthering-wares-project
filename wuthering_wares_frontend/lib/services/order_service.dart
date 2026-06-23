import 'package:flutter/foundation.dart';
import '../models/equipment.dart';

class OrderService extends ChangeNotifier {
  List<Order> _orders = [];
  
  List<Order> get orders => _orders;
  
  void addOrder(Order order) {
    _orders.insert(0, order);
    notifyListeners();
  }
  
  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }
}

class Order {
  final int id;
  final DateTime orderDate;
  final List<OrderItem> items;
  final double totalPrice;
  final String status;
  
  Order({
    required this.id,
    required this.orderDate,
    required this.items,
    required this.totalPrice,
    this.status = 'completed',
  });
}

class OrderItem {
  final Equipment equipment;
  final int quantity;
  final double subtotal;
  
  OrderItem({
    required this.equipment,
    required this.quantity,
    required this.subtotal,
  });
}