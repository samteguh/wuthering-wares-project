import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/equipment.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../services/cart_service.dart';
import 'checkout_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Equipment equipment;

  const ProductDetailPage({super.key, required this.equipment});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  bool _isBuying = false;
  bool _isAddingToCart = false;
  
  late int _currentStock;

  @override
  void initState() {
    super.initState();
    _currentStock = widget.equipment.stock;
  }

  void _incrementQuantity() {
    if (_quantity < _currentStock) {
      setState(() => _quantity++);
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  Future<void> _handlePurchase() async {
    debugPrint('BUY BUTTON CLICKED!');
    debugPrint('Equipment: ${widget.equipment.name}');
    debugPrint('Quantity: $_quantity');
    
    if (_quantity > _currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient stock available!'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isBuying = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      debugPrint('User token exists: ${authService.token != null}');
      
      final apiService = ApiService();
      if (authService.token != null) {
        apiService.setAuthToken(authService.token!);
      }
      
      final success = await apiService.purchaseEquipment(
        widget.equipment.id,
        _quantity,
      );
      
      debugPrint('Purchase API success: $success');
      
      if (!success) {
        throw Exception('Purchase failed');
      }
      
      final updatedEquipment = await apiService.getEquipment(widget.equipment.id);
      debugPrint('Old stock: $_currentStock, New stock: ${updatedEquipment.stock}');
      
      setState(() {
        _currentStock = updatedEquipment.stock;
        if (_quantity > _currentStock) {
          _quantity = _currentStock > 0 ? 1 : 0;
        }
      });
      
      final checkoutItems = [
        CheckoutItem(
          equipment: widget.equipment,
          quantity: _quantity,
          subtotal: widget.equipment.price * _quantity,
          isFromCart: false,
        ),
      ];
      
      final totalPrice = widget.equipment.price * _quantity;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully purchased $_quantity x ${widget.equipment.name}!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutPage(
              items: checkoutItems,
              totalPrice: totalPrice,
              totalQuantity: _quantity,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Purchase error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  Future<void> _handleAddToCart() async {
    if (_quantity > _currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient stock available!'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isAddingToCart = true);
  
    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      await cartService.addToCart(widget.equipment, _quantity);
    
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $_quantity x ${widget.equipment.name} to cart!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  String _formatRupiah(double amount) {
    int amountInt = amount.round();
    String formatted = amountInt.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  Widget _buildImage() {
    Widget imageWidget;
    
    if (widget.equipment.image.startsWith('assets/')) {
      imageWidget = Image.asset(
        widget.equipment.image,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading local image: ${widget.equipment.image}');
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Image not found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: widget.equipment.image,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) {
          print('Error loading network image: $url');
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
        fit: BoxFit.contain,
      );
    }
    
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 300,
          child: imageWidget,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAdmin = authService.currentUser?.isAdmin ?? false;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.equipment.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImage(),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.equipment.type,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    widget.equipment.name,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    _formatRupiah(widget.equipment.price),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                        color: _currentStock > 0 
                            ? AppTheme.successColor 
                            : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentStock > 0 
                            ? 'In Stock: $_currentStock units'
                            : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 14,
                          color: _currentStock > 0 
                              ? AppTheme.successColor 
                              : AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.equipment.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (_currentStock > 0 && !isAdmin) ...[
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _decrementQuantity,
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 32,
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_quantity',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _incrementQuantity,
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 32,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Total: ${_formatRupiah(widget.equipment.price * _quantity)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  if (_currentStock > 0 && !isAdmin)
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 140,
                            child: OutlinedButton(
                              onPressed: _isAddingToCart || _isBuying ? null : _handleAddToCart,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: AppTheme.primaryColor),
                              ),
                              child: _isAddingToCart
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.shopping_cart, size: 18),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Cart',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 140,
                            child: ElevatedButton(
                              onPressed: _isBuying || _isAddingToCart ? null : _handlePurchase,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isBuying
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Buy',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_currentStock > 0 && isAdmin)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Admin accounts cannot make purchases',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Out of Stock'),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}