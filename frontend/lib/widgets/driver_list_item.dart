import 'package:flutter/material.dart';
import '../models/driver.dart';

class DriverListItem extends StatelessWidget {
  final Driver driver;
  final VoidCallback? onTap;
  final bool showStatus;

  const DriverListItem({
    super.key,
    required this.driver,
    this.onTap,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar avec statut
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).primaryColor.withAlpha(26), // ~10% d'opacité
                    child: Text(
                      driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  if (showStatus)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: driver.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Détails du chauffeur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Ligne du type de véhicule
                    if (driver.vehiculeType != null && driver.vehiculeType!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              _getvehiculeIcon(driver.vehiculeType!),
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatvehiculeType(driver.vehiculeType!)}${driver.licensePlate != null && driver.licensePlate!.isNotEmpty ? ' • ${driver.licensePlate}' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (driver.licensePlate != null && driver.licensePlate!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.confirmation_number,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              driver.licensePlate!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Ligne du téléphone
                    if (driver.phone != null && driver.phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              driver.phone!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Statut et note
              if (showStatus)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: driver.isOnline
                            ? Colors.green[100]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        driver.statusText,
                        style: TextStyle(
                          color: driver.isOnline
                              ? Colors.green[800]
                              : Colors.grey[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (driver.rating != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                            driver.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Retourne l'icône correspondant au type de véhicule
  IconData _getvehiculeIcon(String vehiculeType) {
    // Convertir en minuscules pour la comparaison insensible à la casse
    final type = vehiculeType.toLowerCase();
    
    switch (type) {
      case 'car':
      case 'voiture':
        return Icons.directions_car;
      case 'motorbike':
      case 'moto':
        return Icons.motorcycle;
      default:
        return Icons.directions_car; // Icône par défaut
    }
  }

  /// Formate le type de véhicule pour l'affichage
  String _formatvehiculeType(String vehiculeType) {
    // Convertir en minuscules pour la comparaison insensible à la casse
    final type = vehiculeType.toLowerCase();
    
    switch (type) {
      case 'car':
      case 'voiture':
        return 'Voiture';
      case 'motorbike':
      case 'moto':
        return 'Moto';
      default:
        // Si le type n'est pas reconnu, on le retourne tel quel
        return vehiculeType;
    }
  }
}
