import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ApiService _apiService;

  static const String baseUrl = kIsWeb
      ? 'http://localhost:3000/api'
      : 'http://10.0.2.2:3000/api';

  User? _currentUser;
  String? _token;

  AuthService(this._apiService);

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _token != null;
  
  Future<bool> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveSession(data);
        return true;
      }

      final err = json.decode(response.body);
      throw Exception(err['error'] ?? 'Login failed');
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'username': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await _saveSession(data);
        return true;
      }

      final err = json.decode(response.body);
      throw Exception(err['error'] ?? 'Registration failed');
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  Future<bool> googleLogin(String email, {String? googleId, String? name}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/oauth'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'username': name ?? email.split('@')[0],
              'oauth_provider': 'google',
              'oauth_id': googleId ?? email,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveSession(data);
        return true;
      }

      final err = json.decode(response.body);
      throw Exception(err['error'] ?? 'Google login failed');
    } catch (e) {
      debugPrint('Google login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _apiService.clearAuthToken();
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'user_data');
    notifyListeners();
  }

  Future<void> loadStoredAuth() async {
    final token = await _secureStorage.read(key: 'auth_token');
    final userData = await _secureStorage.read(key: 'user_data');

    if (token != null && userData != null) {
      _token = token;
      _apiService.setAuthToken(token);
      final Map<String, dynamic> userJson = json.decode(userData);
      _currentUser = User.fromJson(userJson);
      notifyListeners();
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    _token = data['token'];
    final userJson = data['user'];

    _currentUser = User(
      id: userJson['id'],
      name: userJson['username'],
      email: userJson['email'],
      isAdmin: userJson['role'] == 'admin',
    );

    _apiService.setAuthToken(_token!);

    await _secureStorage.write(key: 'auth_token', value: _token);
    await _secureStorage.write(
      key: 'user_data',
      value: json.encode({
        'id': _currentUser!.id,
        'name': _currentUser!.name,
        'email': _currentUser!.email,
        'is_admin': _currentUser!.isAdmin,
      }),
    );

    notifyListeners();
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final bool isAdmin;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      isAdmin: json['is_admin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'is_admin': isAdmin,
    };
  }
}
