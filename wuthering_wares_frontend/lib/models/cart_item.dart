import 'equipment.dart';

class CartItemModel {
  final int id;
  final Equipment equipment;
  int quantity;
  bool isSelected;

  CartItemModel({
    required this.id,
    required this.equipment,
    this.quantity = 1,
    this.isSelected = true,
  });

  double get totalPrice => equipment.price * quantity;
}