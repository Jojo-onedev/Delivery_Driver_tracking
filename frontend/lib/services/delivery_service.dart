import 'dart:convert' show json, jsonDecode;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../config/constants.dart';
import '../models/delivery.dart';

class DeliveryService with ChangeNotifier {
  List<Delivery> _deliveries = [];
  bool _isLoading = false;
  String? _error;

  // Pour le suivi de localisation en temps réel
  StreamSubscription<Position>? _positionStream;
  final Map<String, Position> _driverPositions = {};

  List<Delivery> get deliveries => List.unmodifiable(_deliveries);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Obtenir les statistiques de livraison
  Map<String, int> getDeliveryStats() {
    final stats = <String, int>{
      'total': _deliveries.length,
      'pending': 0,
      'in_progress': 0,
      'delivered': 0,
      'cancelled': 0,
    };

    for (final delivery in _deliveries) {
      switch (delivery.status) {
        case 'pending':
          stats['pending'] = (stats['pending'] ?? 0) + 1;
          break;
        case 'in_progress':
        case 'assigned':
          stats['in_progress'] = (stats['in_progress'] ?? 0) + 1;
          break;
        case 'delivered':
          stats['delivered'] = (stats['delivered'] ?? 0) + 1;
          break;
        case 'cancelled':
          stats['cancelled'] = (stats['cancelled'] ?? 0) + 1;
          break;
      }
    }

    return stats;
  }

  // Assigner un chauffeur à une livraison
  Future<Delivery> assignDriver(
    String deliveryId,
    String driverId,
    String driverName,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception(AppConstants.errorUnauthorized);
      }

      final response = await http.patch(
        Uri.parse('${AppConstants.apiUrl}/deliveries/$deliveryId/assign'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'driverId': driverId, 'status': 'assigned'}),
      );

      if (response.statusCode == 200) {
        // Mettre à jour la livraison dans la liste locale
        final updatedDelivery = Delivery.fromJson(json.decode(response.body));
        final index = _deliveries.indexWhere((d) => d.id == deliveryId);
        if (index != -1) {
          _deliveries[index] = updatedDelivery;
        }
        notifyListeners();
        return updatedDelivery;
      } else {
        throw Exception(
          'Échec de l\'assignation du chauffeur: ${response.statusCode}',
        );
      }
    } catch (e) {
      _error = 'Erreur lors de l\'assignation du chauffeur: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Récupérer toutes les livraisons
  Future<void> fetchDeliveries({bool forceRefresh = false, String? driverId}) async {
    
    // Ne pas recharger si déjà en cours de chargement et pas de forçage
    if (_isLoading && !forceRefresh) {
      debugPrint('Chargement déjà en cours, annulation de la requête');
      return;
    }

    _isLoading = true;
    _error = null;

    // Notifier immédiatement pour afficher l'indicateur de chargement
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception(AppConstants.errorUnauthorized);
      }

      debugPrint('Récupération des livraisons...');
      Uri uri;
      if (driverId != null && driverId.isNotEmpty) {
        uri = Uri.parse('${AppConstants.apiUrl}/deliveries?driver=$driverId');
      } else {
        uri = Uri.parse('${AppConstants.apiUrl}/deliveries');
      }
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Réponse reçue: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          debugPrint('Réponse brute de l\'API: ${response.body}');

          if (responseData is List) {
            debugPrint('${responseData.length} livraisons reçues');

            // Afficher la structure complète de la première livraison
            if (responseData.isNotEmpty) {
              debugPrint(
                '📝 Structure de la première livraison: ${responseData[0]}',
              );
              debugPrint(
                '📝 Clés disponibles: ${(responseData[0] as Map).keys.toList()}',
              );
            }

            // Traiter les livraisons avec gestion des erreurs individuelles
            final List<Delivery> loadedDeliveries = [];

            for (var i = 0; i < responseData.length; i++) {
              try {
                final deliveryJson = Map<String, dynamic>.from(responseData[i]);

                // Afficher les clés disponibles pour le débogage
                debugPrint(
                  '📝 Livraison #$i - Clés: ${deliveryJson.keys.join(', ')}',
                );

                // Valider les champs requis
                final requiredFields = [
                  '_id',
                  'orderId',
                  'customerName',
                  'address',
                  'status',
                ];
                bool isValid = true;

                for (final field in requiredFields) {
                  if (!deliveryJson.containsKey(field) ||
                      deliveryJson[field] == null) {
                    debugPrint(
                      '⚠️ [Livraison #$i] Champ manquant ou null: $field',
                    );
                    debugPrint(
                      '⚠️ Valeurs disponibles: ${deliveryJson.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                    );
                    isValid = false;
                  }
                }

                if (!isValid) {
                  continue; // Passe à la livraison suivante
                }

                // Créer un objet avec des valeurs par défaut
                final deliveryData = Map<String, dynamic>.from(deliveryJson);

                // Appliquer des valeurs par défaut pour les champs optionnels
                deliveryData['phone'] ??= '';
                deliveryData['notes'] ??= '';

                // Convertir les dates si nécessaire
                final dateFields = [
                  'createdAt',
                  'updatedAt',
                  'pickedAt',
                  'deliveredAt',
                  'assignedAt',
                ];
                for (final field in dateFields) {
                  if (deliveryData[field] != null &&
                      deliveryData[field] is String) {
                    try {
                      deliveryData[field] = DateTime.parse(deliveryData[field]);
                    } catch (e) {
                      debugPrint(
                        '⚠️ Erreur de conversion de date pour $field: ${deliveryData[field]}',
                      );
                      deliveryData[field] = null;
                    }
                  }
                }

                final delivery = Delivery.fromJson(deliveryData);
                loadedDeliveries.add(delivery);
              } catch (e) {
                debugPrint(
                  '❌ Erreur lors du traitement de la livraison #$i: $e',
                );
                // Continuer avec les autres livraisons même si une échoue
              }
            }

            _deliveries = loadedDeliveries;
            debugPrint(
              '✅ ${_deliveries.length} livraisons chargées avec succès',
            );
            // Notifier après la mise à jour des livraisons pour rafraîchir les statistiques
            notifyListeners();
          } else {
            throw Exception(
              'Format de réponse inattendu: ${responseData.runtimeType}',
            );
          }
        } catch (e) {
          debugPrint('❌ Erreur lors du traitement de la réponse: $e');
          throw Exception('Erreur de traitement des données: $e');
        }
      } else {
        final errorMsg =
            jsonDecode(response.body)?['message'] ?? 'Erreur inconnue';
        throw Exception(
          'Échec du chargement: $errorMsg (${response.statusCode})',
        );
      }
    } on TimeoutException {
      _error = 'La requête a expiré. Vérifiez votre connexion internet.';
      debugPrint('⏱️ Timeout lors de la récupération des livraisons');
      rethrow;
    } on http.ClientException catch (e) {
      _error = 'Erreur de connexion: ${e.message}';
      debugPrint('🌐 Erreur réseau: ${e.toString()}');
      rethrow;
    } catch (e) {
      _error = 'Erreur inattendue: ${e.toString()}';
      debugPrint('❌ Erreur inattendue: ${e.toString()}');
      rethrow;
    } finally {
      _isLoading = false;
      // Notifier après la mise à jour complète
      notifyListeners();
    }
  }

  // Créer une nouvelle livraison
  Future<Delivery> createDelivery(Map<String, dynamic> deliveryData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception(AppConstants.errorUnauthorized);
      }

      // Valider les champs requis
      final requiredFields = {
        'orderId': 'Numéro de commande',
        'customerName': 'Nom du client',
        'address': 'Adresse de livraison',
        'phone': 'Téléphone',
      };

      final missingFields = <String>[];
      for (final entry in requiredFields.entries) {
        if (deliveryData[entry.key] == null ||
            deliveryData[entry.key].toString().trim().isEmpty) {
          missingFields.add(entry.value);
        }
      }

      if (missingFields.isNotEmpty) {
        throw Exception('Champs manquants : ${missingFields.join(', ')}');
      }

      // Préparer les données avec des valeurs par défaut
      final requestData = Map<String, dynamic>.from(deliveryData);

      // Nettoyer les données
      requestData.forEach((key, value) {
        if (value is String) {
          requestData[key] = value.trim();
        }
      });

      // Définir le statut par défaut
      requestData['status'] = 'pending';

      debugPrint('📤 Envoi des données de création : $requestData');

      final response = await http
          .post(
            Uri.parse('${AppConstants.apiUrl}/deliveries'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '✅ Réponse de l\'API (${response.statusCode}): ${response.body}',
      );

      if (response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          debugPrint('📦 Données de la réponse : $responseData');

          final newDelivery = Delivery.fromJson(responseData);
          _deliveries.add(newDelivery);

          // Notifier les écouteurs après la mise à jour
          scheduleMicrotask(() {
            notifyListeners();
          });

          return newDelivery;
        } catch (e) {
          debugPrint('❌ Erreur lors de la désérialisation de la réponse : $e');
          throw Exception('Format de réponse invalide de l\'API');
        }
      } else {
        String errorMsg = 'Erreur inconnue';
        try {
          final errorResponse = jsonDecode(response.body);
          errorMsg = errorResponse['message'] ?? errorResponse.toString();
        } catch (e) {
          errorMsg = 'Erreur ${response.statusCode}: ${response.body}';
        }
        throw Exception('Échec de la création de la livraison: $errorMsg');
      }
    } catch (e) {
      _error = 'Erreur lors de la création de la livraison: ${e.toString()}';
      debugPrint(_error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour une livraison
  Future<Delivery> updateDelivery(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception(AppConstants.errorUnauthorized);
      }

      final response = await http.patch(
        Uri.parse('${AppConstants.apiUrl}/deliveries/$id/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': updates['status']}),
      );

      if (response.statusCode == 200) {
        final updatedDelivery = Delivery.fromJson(json.decode(response.body));
        final index = _deliveries.indexWhere((d) => d.id == id);
        if (index != -1) {
          _deliveries[index] = updatedDelivery;
          notifyListeners();
        }
        return updatedDelivery;
      } else {
        throw Exception(
          'Échec de la mise à jour de la livraison: ${response.statusCode}',
        );
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Supprimer une livraison
  Future<void> deleteDelivery(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception(AppConstants.errorUnauthorized);
      }

      final response = await http.delete(
        Uri.parse('${AppConstants.apiUrl}/deliveries/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _deliveries.removeWhere((d) => d.id == id);
        notifyListeners();
      } else {
        throw Exception(
          'Échec de la suppression de la livraison: ${response.statusCode}',
        );
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Obtenir une livraison par son ID
  Delivery? getDeliveryById(String id) {
    try {
      return _deliveries.firstWhere((delivery) => delivery.id == id);
    } catch (e) {
      return null;
    }
  }

  // La méthode getDeliveryStats() est déjà définie plus haut dans le fichier

  // Mettre à jour le statut d'une livraison
  Future<Delivery> updateDeliveryStatus(
    String deliveryId,
    String newStatus, {
    String? notes,
  }) async {
    try {
      // Convertir le statut en format attendu par l'API
      String apiStatus = newStatus;
      if (newStatus == 'in_progress') {
        apiStatus = 'in_transit';
      }

      final updates = {'status': apiStatus};
      if (notes != null) {
        updates['notes'] = notes;
      }

      if (apiStatus == 'delivered') {
        updates['deliveredAt'] = DateTime.now().toIso8601String();
      }

      return await updateDelivery(deliveryId, updates);
    } catch (e) {
      _error = 'Erreur lors de la mise à jour du statut: ${e.toString()}';
      rethrow;
    }
  }

  // Marquer une livraison comme en cours
  Future<Delivery> startDelivery(
    String deliveryId, {
    required String driverId,
    required String driverName,
  }) async {
    return await updateDeliveryStatus(
      deliveryId,
      'in_progress',
      notes: 'Livraison démarrée par $driverName',
    );
  }

  // Marquer une livraison comme terminée
  Future<Delivery> completeDelivery(
    String deliveryId, {
    String? signature,
    String? notes,
  }) async {
    final updates = {
      'status': 'delivered',
      'deliveredAt': DateTime.now().toIso8601String(),
      if (signature != null) 'signature': signature,
      if (notes != null) 'notes': notes,
    };

    return await updateDelivery(deliveryId, updates);
  }

  // Annuler une livraison
  Future<Delivery> cancelDelivery(
    String deliveryId, {
    required String reason,
  }) async {
    return await updateDeliveryStatus(
      deliveryId,
      'cancelled',
      notes: 'Annulée: $reason',
    );
  }

  // Filtrer les livraisons par statut
  List<Delivery> getDeliveriesByStatus(String status) {
    return _deliveries.where((d) => d.status == status).toList();
  }

  // Obtenir les livraisons en cours pour un chauffeur
  List<Delivery> getActiveDeliveriesForDriver(String driverId) {
    return _deliveries
        .where(
          (d) =>
              d.driverId == driverId &&
              (d.status == 'in_progress' || d.status == 'assigned'),
        )
        .toList();
  }

  // Démarrer le suivi de position en temps réel
  void startLocationTracking(String driverId) async {
    // Vérifier les permissions de localisation
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Les services de localisation sont désactivés');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Les permissions de localisation sont refusées');
      }
    }

    // Configurer les paramètres de suivi
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // en mètres
    );

    // Démarrer le suivi
    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
            _driverPositions[driverId] = position;
            await updateDriverLocation(driverId, position);
          },
        );
  }

  // Arrêter le suivi de position
  void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  // Mettre à jour la position du chauffeur sur le serveur
  Future<void> updateDriverLocation(String driverId, Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception('Non authentifié');
      }

      await http.post(
        Uri.parse('${AppConstants.apiUrl}/drivers/$driverId/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('Erreur de mise à jour de la position: $e');
    }
  }

  // Télécharger une preuve de livraison
  Future<void> uploadDeliveryProof(
    String deliveryId, {
    required String filePath,
    required String fileType, // 'photo', 'signature', etc.
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);

      if (token == null) {
        throw Exception('Non authentifié');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiUrl}/deliveries/$deliveryId/proof'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      request.fields['type'] = fileType;

      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception('Échec du téléchargement de la preuve');
      }
    } catch (e) {
      _error = 'Erreur lors du téléchargement de la preuve: ${e.toString()}';
      rethrow;
    }
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}
