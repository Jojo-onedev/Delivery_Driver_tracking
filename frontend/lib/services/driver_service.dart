import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/constants.dart';
import '../models/driver.dart';

class DriverService with ChangeNotifier {
  List<Driver> _drivers = [];
  bool _isLoading = false;
  String? _error;

  List<Driver> get drivers => List.unmodifiable(_drivers);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Récupérer tous les chauffeurs
  Future<void> fetchDrivers({bool notify = true}) async {
    _isLoading = true;
    _error = null;
    if (notify) notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception(AppConstants.errorUnauthorized);
      }

      final url = '${AppConstants.apiUrl}/admin/users';
      debugPrint('🔄 Récupération des utilisateurs depuis: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('✅ Réponse reçue - Status: ${response.statusCode}');
      
      // Ne pas logger tout le corps si c'est trop volumineux
      final responseBody = response.body;
      if (responseBody.length < 1000) {
        debugPrint('📦 Corps de la réponse: $responseBody');
      } else {
        debugPrint('📦 Réponse reçue (tronquée): ${responseBody.substring(0, 500)}...');
      }

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          debugPrint('🔍 Nombre total d\'utilisateurs reçus: ${data.length}');

          // Filtrer uniquement les utilisateurs avec le rôle 'driver' et qui ont un ID valide
          final driverData = data.where((user) {
            final role = user['role']?.toString().toLowerCase();
            final id = user['_id']?.toString();
            return role == 'driver' && id != null && id.isNotEmpty;
          }).toList();
          
          debugPrint('🚗 Nombre de chauffeurs trouvés: ${driverData.length}');

          _drivers = driverData.map<Driver?>((json) {
            try {
              // Créer une copie profonde des données pour la manipulation
              final driverJson = Map<String, dynamic>.from(json as Map<String, dynamic>);
              
              // Nettoyer et valider les champs requis
              driverJson['id'] = driverJson['_id'] ?? 'id_manquant';
              driverJson['name'] = _cleanString(driverJson['name'], 'Chauffeur inconnu');
              driverJson['email'] = _cleanString(driverJson['email'], 'email@inconnu.com');
              
              // Gérer le statut avec une valeur par défaut
              driverJson['status'] = _cleanString(driverJson['status'], 'offline')?.toLowerCase() ?? 'offline';
              
              // Gérer le véhicule (vehicule vs vehicle pour la rétrocompatibilité)
              final vehiculeType = driverJson['vehicule'] ?? driverJson['vehicle'];
              if (vehiculeType != null) {
                // Normaliser le type de véhicule en minuscules
                final normalizedType = vehiculeType.toString().toLowerCase();
                
                // Mapper les variations de noms vers les valeurs standardisées
                if (normalizedType == 'moto' || normalizedType == 'motorcycle') {
                  driverJson['vehiculeType'] = 'motorbike';
                  driverJson['vehicule'] = 'motorbike'; // Standardiser aussi le champ vehicule
                } else if (normalizedType == 'voiture' || normalizedType == 'car') {
                  driverJson['vehiculeType'] = 'car';
                  driverJson['vehicule'] = 'car'; // Standardiser aussi le champ vehicule
                } else {
                  // Pour les autres valeurs, les conserver mais en minuscules
                  driverJson['vehiculeType'] = normalizedType;
                  driverJson['vehicule'] = normalizedType;
                }
                
                debugPrint('🔧 Type de véhicule normalisé: ${driverJson['vehiculeType']} (original: $vehiculeType)');
              }
              
              // Gérer la plaque d'immatriculation
              driverJson['licensePlate'] = _cleanString(driverJson['licensePlate'] ?? driverJson['license_plate'], null);
              
              // Gestion des dates
              driverJson['createdAt'] = _parseDate(driverJson['createdAt']) ?? DateTime.now();
              driverJson['lastActiveAt'] = _parseDate(driverJson['lastActiveAt']);
              
              // Convertir la note en double si nécessaire
              if (driverJson['rating'] != null) {
                if (driverJson['rating'] is int) {
                  driverJson['rating'] = (driverJson['rating'] as int).toDouble();
                } else if (driverJson['rating'] is String) {
                  driverJson['rating'] = double.tryParse(driverJson['rating']) ?? 0.0;
                }
              }
              
              // Créer l'instance du chauffeur
              final driver = Driver.fromJson(driverJson);
              
              // Log de débogage pour le premier chauffeur
              if (data.indexOf(json) == 0) {
                debugPrint('📝 Premier chauffeur désérialisé: ${driver.toJson()}');
              }
              
              return driver;
            } catch (e, stackTrace) {
              debugPrint('❌ Erreur lors de la désérialisation d\'un chauffeur: $e');
              debugPrint('Stack trace: $stackTrace');
              debugPrint('Données problématiques: $json');
              return null;
            }
          }).whereType<Driver>().toList();

          debugPrint('✅ ${drivers.length} chauffeurs chargés avec succès');
          _drivers = drivers;
        } catch (e, stackTrace) {
          debugPrint('❌ Erreur lors du traitement de la réponse: $e');
          debugPrint('📌 Stack trace: $stackTrace');
          rethrow;
        }
      } else {
        final errorMsg =
            'Échec du chargement des chauffeurs: ${response.statusCode} - ${response.body}';
        debugPrint('❌ $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e, stackTrace) {
      _error = e.toString();
      debugPrint('❌ Erreur dans fetchDrivers: $e');
      debugPrint('📌 Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      if (notify) {
        notifyListeners();
      }
    }
  }

  // Créer un nouveau chauffeur
  Future<Driver> createDriver(Map<String, dynamic> driverData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception(AppConstants.errorUnauthorized);
      }

      // Créer une copie des données pour les modifier
      final requestData = Map<String, dynamic>.from(driverData);
      
      // Normaliser et valider le type de véhicule
      if (requestData['vehiculeType'] != null) {
        final vehiculeType = requestData['vehiculeType'].toString().toLowerCase();
        
        // Mapper les variations de noms vers les valeurs standardisées
        if (vehiculeType == 'moto' || vehiculeType == 'motorcycle') {
          requestData['vehicule'] = 'motorbike';
          requestData['vehiculeType'] = 'motorbike'; // Pour la cohérence côté client
        } else if (vehiculeType == 'voiture' || vehiculeType == 'car') {
          requestData['vehicule'] = 'car';
          requestData['vehiculeType'] = 'car'; // Pour la cohérence côté client
        } else {
          // Pour les autres valeurs, les conserver mais en minuscules
          requestData['vehicule'] = vehiculeType;
          // Laisser vehiculeType tel quel pour la cohérence côté client
        }
        
        debugPrint('🚗 Type de véhicule normalisé pour la création: ${requestData['vehicule']} (original: ${driverData['vehiculeType']})');
      } else {
        // Si aucun type de véhicule n'est fourni, définir une valeur par défaut
        requestData['vehicule'] = 'car';
        requestData['vehiculeType'] = 'car';
        debugPrint('ℹ️ Aucun type de véhicule fourni, utilisation de la valeur par défaut: car');
      }
      
      // Ne pas envoyer vehiculeType au backend pour éviter la confusion
      requestData.remove('vehiculeType');

      debugPrint('📤 Envoi de la requête de création de chauffeur: ${json.encode(requestData)}');
      
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );
      
      debugPrint('✅ Réponse du serveur (${response.statusCode}): ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        // Préparer les données pour la création du Driver
        final driverJson = responseData['user'] as Map<String, dynamic>;
        
        // S'assurer que vehiculeType est défini (peut être null dans la réponse)
        if (driverJson['vehicule'] != null) {
          driverJson['vehiculeType'] = driverJson['vehicule'];
        } else if (driverData['vehiculeType'] != null) {
          driverJson['vehiculeType'] = driverData['vehiculeType'];
        }
        
        // Créer le chauffeur avec les données formatées
        final newDriver = Driver.fromJson(driverJson);
        _drivers.add(newDriver);
        notifyListeners();
        return newDriver;
      } else {
        throw Exception(
          'Échec de la création du chauffeur: ${response.statusCode}',
        );
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Mettre à jour un chauffeur
  Future<Driver> updateDriver(String id, Map<String, dynamic> updates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception(AppConstants.errorUnauthorized);
      }

      final response = await http.put(
        Uri.parse('${AppConstants.apiUrl}/admin/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final updatedDriver = Driver.fromJson(json.decode(response.body));
        final index = _drivers.indexWhere((d) => d.id == id);
        if (index != -1) {
          _drivers[index] = updatedDriver;
          notifyListeners();
        }
        return updatedDriver;
      } else {
        throw Exception(
          'Échec de la mise à jour du chauffeur: ${response.statusCode}',
        );
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Supprimer un chauffeur
  Future<void> deleteDriver(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception(AppConstants.errorUnauthorized);
      }

      final response = await http.delete(
        Uri.parse('${AppConstants.apiUrl}/admin/users/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _drivers.removeWhere((d) => d.id == id);
        notifyListeners();
      } else {
        throw Exception(
          'Échec de la suppression du chauffeur: ${response.statusCode}',
        );
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Mettre à jour le statut d'un chauffeur
  Future<Driver> updateDriverStatus(String id, String status) async {
    try {
      return await updateDriver(id, {'status': status});
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Obtenir un chauffeur par son ID
  Driver? getDriverById(String id) {
    try {
      return _drivers.firstWhere((driver) => driver.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtenir les chauffeurs disponibles
  List<Driver> getAvailableDrivers() {
    return _drivers.where((driver) => driver.status == 'available').toList();
  }

  // Obtenir les statistiques des chauffeurs
  Map<String, dynamic> getDriverStats() {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    // Statistiques de base
    final stats = <String, dynamic>{
      'total': _drivers.length,
      'available': _drivers.where((d) => d.status == 'available').length,
      'on_delivery': _drivers.where((d) => d.status == 'on_delivery').length,
      'offline': _drivers.where((d) => d.status == 'offline').length,
      'active': _drivers.where((d) => d.isActive).length,
      'inactive': _drivers.where((d) => !d.isActive).length,
      'documents_expired': _drivers
          .where((d) => _hasExpiredDocuments(d))
          .length,
    };

    // Statistiques de performance
    final performanceStats = <String, dynamic>{
      'avg_rating': _calculateAverageRating(),
      'total_deliveries': _calculateTotalDeliveries(),
      'weekly_deliveries': _calculateWeeklyDeliveries(oneWeekAgo),
    };

    return {...stats, ...performanceStats};
  }

  // Vérifier si un chauffeur a des documents expirés
  bool _hasExpiredDocuments(Driver driver) {
    final now = DateTime.now();
    return driver.documents.any(
      (doc) => doc.expiryDate != null && doc.expiryDate!.isBefore(now),
    );
  }

  // Calculer la note moyenne des chauffeurs
  double _calculateAverageRating() {
    if (_drivers.isEmpty) return 0.0;

    final totalRating = _drivers.fold<double>(
      0.0,
      (sum, driver) => sum + (driver.rating ?? 0),
    );

    return totalRating / _drivers.length;
  }

  // Méthode utilitaire pour nettoyer les chaînes de caractères
  String? _cleanString(dynamic value, [String? defaultValue]) {
    if (value == null) return defaultValue;
    final str = value.toString().trim();
    return str.isEmpty ? defaultValue : str;
  }
  
  // Méthode utilitaire pour parser les dates
  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) {
      debugPrint('⚠️ Date nulle reçue');
      return null;
    }
    
    try {
      if (dateValue is DateTime) {
        debugPrint('✅ Date déjà au format DateTime: $dateValue');
        return dateValue;
      }
      
      if (dateValue is String) {
        debugPrint('🔍 Tentative de parsing de la chaîne de date: $dateValue');
        return DateTime.parse(dateValue);
      }
      
      if (dateValue is int) {
        debugPrint('⏱️ Conversion de timestamp int en DateTime: $dateValue');
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }
      
      debugPrint('⚠️ Format de date non reconnu: ${dateValue.runtimeType} - $dateValue');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors du parsing de la date: $dateValue');
      debugPrint('📌 Erreur: $e');
      debugPrint('📌 Stack trace: $stackTrace');
      return null;
    }
  }

  // Calculer le nombre total de livraisons
  int _calculateTotalDeliveries() {
    return _drivers.fold<int>(
      0,
      (sum, driver) => sum + driver.totalDeliveries,
    );
  }

  // Calculer les livraisons de la semaine
  int _calculateWeeklyDeliveries(DateTime startDate) {
    return _drivers.fold<int>(0, (sum, driver) {
      final weeklyDeliveries =
          driver.recentDeliveries
              ?.where(
                (delivery) => delivery.completedAt?.isAfter(startDate) ?? false,
              )
              .length ??
          0;
      return sum + weeklyDeliveries;
    });
  }

  // Télécharger un document pour un chauffeur
  Future<void> uploadDriverDocument(
    String driverId, {
    required String filePath,
    required String documentType,
    DateTime? expiryDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception('Non authentifié');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiUrl}/admin/users/$driverId/documents'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      request.fields['type'] = documentType;

      if (expiryDate != null) {
        request.fields['expiryDate'] = expiryDate.toIso8601String();
      }

      final response = await request.send();

      if (response.statusCode != 201) {
        throw Exception('Échec du téléchargement du document');
      }

      // Mettre à jour les informations du chauffeur
      await fetchDrivers();
    } catch (e) {
      _error = 'Erreur lors du téléchargement du document: ${e.toString()}';
      rethrow;
    }
  }

  // Obtenir la position actuelle d'un chauffeur
  Future<Map<String, dynamic>?> getDriverLocation(String driverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/admin/users/$driverId/location'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      _error = 'Erreur lors de la récupération de la position: ${e.toString()}';
      return null;
    }
  }

  // Activer/désactiver un chauffeur
  Future<Driver> toggleDriverStatus(String driverId, bool isActive) async {
    try {
      return await updateDriver(driverId, {'isActive': isActive});
    } catch (e) {
      _error = 'Erreur lors de la mise à jour du statut: ${e.toString()}';
      rethrow;
    }
  }

  // Obtenir l'historique des livraisons d'un chauffeur
  Future<List<Map<String, dynamic>>> getDriverDeliveryHistory(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception('Non authentifié');
      }

      final params = <String, String>{};
      if (startDate != null) params['startDate'] = startDate.toIso8601String();
      if (endDate != null) params['endDate'] = endDate.toIso8601String();
      if (status != null) params['status'] = status;

      final uri = Uri.parse(
        '${AppConstants.apiUrl}/admin/users/$driverId/deliveries',
      ).replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Échec du chargement de l\'historique des livraisons');
      }
    } catch (e) {
      _error =
          'Erreur lors de la récupération de l\'historique: ${e.toString()}';
      rethrow;
    }
  }

  // Obtenir les statistiques de performance d'un chauffeur
  Future<Map<String, dynamic>> getDriverPerformance(String driverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/drivers/$driverId/performance'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Échec du chargement des statistiques de performance');
      }
    } catch (e) {
      _error =
          'Erreur lors de la récupération des statistiques: ${e.toString()}';
      rethrow;
    }
  }

  // Vérifier la connectivité réseau
  Future<bool> checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      _error = 'Erreur de vérification de la connectivité: ${e.toString()}';
      return false;
    }
  }

  @override
  void dispose() {
    // Nettoyer les ressources si nécessaire
    super.dispose();
  }
}
