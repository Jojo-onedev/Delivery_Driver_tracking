import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user.dart';

class AuthService with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  User? _user;
  String? _token;

  User? get user => _user;
  String? get token => _token;

  bool get isAuthenticated => _token != null;

  AuthService() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      _token = token;
      final userJson = await _storage.read(key: 'user');
      if (userJson != null) {
        _user = User.fromJson(jsonDecode(userJson));
      }
      notifyListeners();
    }
  }

    Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Réponse backend login: ${response.body}');
        
        // Sécurise la récupération du token et de l'utilisateur
        final token = data['token'];
        final userJson = data['user'];

        if (token == null || token is! String || token.isEmpty || userJson == null) {
          // Si le token ou l'utilisateur est absent ou invalide, on échoue proprement
          return false;
        }

        _token = token;
        _user = User.fromJson(userJson);

        await _storage.write(key: 'token', value: _token);
        await _storage.write(key: 'user', value: jsonEncode(_user!.toJson()));

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

Future<bool> register({
  required String name,
  required String email,
  required String password,
  String? phone,
  String? vehicle,
  String? licensePlate,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${dotenv.env['API_BASE_URL']}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
        if (vehicle != null) 'vehicle': vehicle,
        if (licensePlate != null) 'licensePlate': licensePlate,
      }),
    );

    if (response.statusCode == 201) {
      return await login(email, password);
    }
    return false;
  } catch (e) {
    debugPrint('Register error: $e');
    return false;
  }
}

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
    _token = null;
    _user = null;
    notifyListeners();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }

  Future<String?> getUserRole() async {
    if (_user != null) return _user!.role;
    final userJson = await _storage.read(key: 'user');
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
      return _user!.role;
    }
    return null;
  }
}