import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user.dart';

class AuthService with ChangeNotifier {
  final SharedPreferences sharedPreferences;
  User? _user;
  String? _token;

  User? get user => _user;
  String? get token => _token;

  bool get isAuthenticated => _token != null;

  AuthService({required this.sharedPreferences}) {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _token = sharedPreferences.getString(AppConstants.storageTokenKey);
    if (_token != null) {
      final userJson = sharedPreferences.getString(AppConstants.storageUserKey);
      if (userJson != null) {
        try {
          _user = User.fromJson(jsonDecode(userJson));
        } catch (e) {
          debugPrint('Erreur lors du chargement des données utilisateur: $e');
          await _clearUserData();
        }
      }
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Réponse backend login: ${response.body}');

        // Sécurise la récupération du token et de l'utilisateur
        final token = data['token'];
        final userJson = data['user'];

        if (token == null || userJson == null) {
          throw Exception('Réponse du serveur invalide');
        }

        if (token == null ||
            token is! String ||
            token.isEmpty ||
            userJson == null) {
          // Si le token ou l'utilisateur est absent ou invalide, on échoue proprement
          return false;
        }

        await _saveUserData(token, userJson);

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> _saveUserData(
    String token,
    Map<String, dynamic> userData,
  ) async {
    _token = token;
    _user = User.fromJson(userData);

    await sharedPreferences.setString(AppConstants.storageTokenKey, token);
    await sharedPreferences.setString(
      AppConstants.storageUserKey,
      jsonEncode(userData),
    );

    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? vehicule,
    String? licensePlate,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
        if (vehicule != null) 'vehicule': vehicule,
        if (licensePlate != null) 'licensePlate': licensePlate,
      };

      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        return await login(email, password);
      } else {
        final error =
            jsonDecode(response.body)['message'] ??
            'Erreur lors de l\'inscription';
        throw Exception(error);
      }
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  Future<void> _clearUserData() async {
    await sharedPreferences.remove(AppConstants.storageTokenKey);
    await sharedPreferences.remove(AppConstants.storageUserKey);
    _token = null;
    _user = null;
  }

  Future<void> logout() async {
    try {
      final token = sharedPreferences.getString(AppConstants.storageTokenKey);
      if (token != null) {
        try {
          // Essayer de se déconnecter du serveur
          final response = await http.post(
            Uri.parse('${AppConstants.apiUrl}/auth/logout'),
            headers: {'Authorization': 'Bearer $token'},
          );
          
          // Si le point de terminaison n'existe pas (404), on continue quand même
          if (response.statusCode == 404) {
            debugPrint('Le point de terminaison /auth/logout n\'existe pas, nettoyage local uniquement');
          } else if (response.statusCode != 200) {
            debugPrint('Erreur lors de la déconnexion: ${response.statusCode} - ${response.body}');
          }
        } catch (e) {
          // En cas d'erreur réseau ou autre, on continue avec le nettoyage local
          debugPrint('Erreur lors de l\'appel API de déconnexion: $e');
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
    } finally {
      // Dans tous les cas, on nettoie les données locales
      await _clearUserData();
      notifyListeners();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = sharedPreferences.getString('token');
    return token != null;
  }

  Future<String?> getUserRole() async {
    if (_user != null) return _user!.role;
    final userJson = sharedPreferences.getString('user');
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
      return _user!.role;
    }
    return null;
  }
}
