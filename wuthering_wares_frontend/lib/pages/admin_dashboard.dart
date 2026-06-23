import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/equipment.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import 'login_page.dart';
import '../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Equipment> _equipments = [];
  bool _isLoading = true;
  bool _isAdding = false;
  final _formKey = GlobalKey<FormState>();
  bool _isLoggingOut = false;
  
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageController = TextEditingController();
  final _priceController = TextEditingController();
  
  Equipment? _editingEquipment;

  Future<ApiService> _getApiService() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService();
    if (authService.token != null) {
      apiService.setAuthToken(authService.token!);
    }
    return apiService;
  }

  @override
  void initState() {
    super.initState();
    _loadEquipments();
  }

  Future<void> _loadEquipments() async {
    setState(() => _isLoading = true);
    try {
      final apiService = await _getApiService();
      final equipments = await apiService.getEquipments();
      setState(() => _equipments = equipments);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load equipments: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showLogoutConfirmation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: AppTheme.errorColor, size: 28),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            SizedBox(
              width: 100,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'No',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Yes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.all(16),
        );
      },
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showEquipmentDialog([Equipment? equipment]) {
    _editingEquipment = equipment;
    if (equipment != null) {
      _nameController.text = equipment.name;
      _typeController.text = equipment.type;
      _descriptionController.text = equipment.description;
      _stockController.text = equipment.stock.toString();
      _imageController.text = equipment.image;
      _priceController.text = equipment.price.toString();
    } else {
      _clearForm();
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(equipment == null ? 'Add Equipment' : 'Edit Equipment'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _typeController,
                  decoration: const InputDecoration(labelText: 'Type'),
                  validator: (value) => value?.isEmpty ?? true ? 'Type is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Stock is required';
                    if (int.tryParse(value!) == null) return 'Stock must be a number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  validator: (value) => value?.isEmpty ?? true ? 'Image URL is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Price is required';
                    if (double.tryParse(value!) == null) return 'Price must be a number';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saveEquipment,
            child: Text(equipment == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _typeController.clear();
    _descriptionController.clear();
    _stockController.clear();
    _imageController.clear();
    _priceController.clear();
  }

  Future<void> _saveEquipment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isAdding = true);
      
      final equipmentData = {
        'name': _nameController.text,
        'type': _typeController.text,
        'description': _descriptionController.text,
        'stock': int.parse(_stockController.text),
        'image': _imageController.text,
        'price': double.parse(_priceController.text),
      };
      
      try {
        final apiService = await _getApiService();
        
        if (_editingEquipment == null) {
          await apiService.createEquipment(equipmentData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Equipment added successfully')),
          );
        } else {
          await apiService.updateEquipment(_editingEquipment!.id, equipmentData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Equipment updated successfully')),
          );
        }
        
        Navigator.pop(context);
        await _loadEquipments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save equipment: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _deleteEquipment(Equipment equipment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Equipment'),
        content: Text('Are you sure you want to delete "${equipment.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final apiService = await _getApiService();
        await apiService.deleteEquipment(equipment.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipment deleted successfully')),
        );
        await _loadEquipments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete equipment: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEquipments,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _equipments.isEmpty
              ? const Center(
                  child: Text('No equipment found. Tap + to add equipment.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _equipments.length,
                  itemBuilder: (context, index) {
                    final equipment = _equipments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: equipment.image.startsWith('assets/')
                              ? Image.asset(
                                  equipment.image,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image_not_supported),
                                    );
                                  },
                                )
                              : Image.network(
                                  equipment.image,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image_not_supported),
                                    );
                                  },
                                ),
                        ),
                        title: Text(
                          equipment.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${equipment.type}'),
                            Text('Stock: ${equipment.stock} | Price: ${_formatRupiah(equipment.price)}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEquipmentDialog(equipment),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteEquipment(equipment),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEquipmentDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Add Equipment',
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}