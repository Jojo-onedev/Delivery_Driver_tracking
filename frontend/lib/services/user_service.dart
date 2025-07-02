import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/constants.dart';
import 'api_service.dart';
import '../models/user.dart';

class UserService with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService(baseUrl: AppConstants.apiUrl);

  // Récupérer les informations du profil utilisateur
  Future<User?> fetchUserProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!await _checkConnectivity()) {
        throw Exception('Pas de connexion Internet');
      }

      final response = await _apiService.get('/users/me');
      
      if (response != null) {
        _currentUser = User.fromJson(response);
        notifyListeners();
        return _currentUser;
      }
      return null;
    } catch (e) {
      _error = 'Erreur lors de la récupération du profil: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour les informations du profil
  Future<User?> updateProfile(Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!await _checkConnectivity()) {
        throw Exception('Pas de connexion Internet');
      }

      final response = await _apiService.put(
        '/users/me',
        body: updates,
      );
      
      if (response != null) {
        _currentUser = User.fromJson(response);
        notifyListeners();
        return _currentUser;
      }
      return null;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour du profil: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Changer le mot de passe
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!await _checkConnectivity()) {
        throw Exception('Pas de connexion Internet');
      }

      await _apiService.post(
        '/users/change-password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      
      return true;
    } catch (e) {
      _error = 'Erreur lors du changement de mot de passe: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour la photo de profil
  Future<User?> updateProfilePicture(File imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!await _checkConnectivity()) {
        throw Exception('Pas de connexion Internet');
      }

      final response = await _apiService.uploadFile(
        '/users/me/avatar',
        imageFile,
        fileField: 'avatar',
      );
      
      if (response != null) {
        _currentUser = User.fromJson(response);
        notifyListeners();
        return _currentUser;
      }
      return null;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour de la photo de profil: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour les préférences utilisateur
  Future<User?> updatePreferences(Map<String, dynamic> preferences) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!await _checkConnectivity()) {
        throw Exception('Pas de connexion Internet');
      }

      final response = await _apiService.put(
        '/users/me/preferences',
        body: {'preferences': preferences},
      );
      
      if (response != null) {
        _currentUser = User.fromJson(response);
        notifyListeners();
        return _currentUser;
      }
      return null;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour des préférences: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Déconnecter l'utilisateur
  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // Vérifier la connectivité réseau
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      _error = 'Erreur de vérification de la connectivité: ${e.toString()}';
      return false;
    }
  }
}
