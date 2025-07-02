import 'package:flutter/material.dart';
import '../../models/driver.dart';
import '../../services/driver_service.dart';
import '../../services/delivery_service.dart';

class AssignDriverDialog extends StatefulWidget {
  final String deliveryId;
  final String? currentDriverId;
  
  const AssignDriverDialog({
    super.key,
    required this.deliveryId,
    this.currentDriverId,
  });

  @override
  State<AssignDriverDialog> createState() => AssignDriverDialogState();
}

class AssignDriverDialogState extends State<AssignDriverDialog> {
  final DriverService _driverService = DriverService();
  final DeliveryService _deliveryService = DeliveryService();
  List<Driver> _drivers = [];
  bool _isLoading = true;
  String? _selectedDriverId;
  bool _isSubmitting = false;
  String? _error;

  String _getStatusText(String status) {
    switch (status) {
      case 'available':
        return '🟢 Disponible';
      case 'on_delivery':
        return '🟠 En livraison';
      case 'offline':
      default:
        return '⚪ Hors ligne';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'on_delivery':
        return Colors.orange;
      case 'offline':
      default:
        return Colors.grey;
    }
  }

  Widget _getStatusIcon(String status) {
    return Icon(
      status == 'available' 
          ? Icons.check_circle_outline 
          : status == 'on_delivery'
              ? Icons.local_shipping
              : Icons.offline_bolt,
      color: _getStatusColor(status),
    );
  }

  String _formatVehicleType(String type) {
    switch (type.toLowerCase()) {
      case 'car':
        return 'Voiture';
      case 'motorbike':
        return 'Moto';
      default:
        return type;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDrivers();
    _selectedDriverId = widget.currentDriverId;
  }

  Future<void> _loadDrivers() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _driverService.fetchDrivers();
      if (mounted) {
        setState(() {
          _drivers = _driverService.drivers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement des chauffeurs';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _assignDriver() async {
    if (_selectedDriverId == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final selectedDriver = _drivers.firstWhere((d) => d.id == _selectedDriverId);
      await _deliveryService.assignDriver(
        widget.deliveryId,
        _selectedDriverId!,
        selectedDriver.name,
      );
      
      if (mounted) {
        Navigator.of(context).pop(true); // Retourne true pour indiquer le succès
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'assignation du chauffeur: ${e.toString()}';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assigner un chauffeur'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sélectionnez un chauffeur :'),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ..._drivers.map((driver) => RadioListTile<String>(
                      title: Text(driver.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusText(driver.status),
                            style: TextStyle(
                              color: _getStatusColor(driver.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (driver.vehiculeType != null && driver.vehiculeType!.isNotEmpty)
                            Text(
                              'Véhicule: ${_formatVehicleType(driver.vehiculeType!)}\n${driver.licensePlate ?? 'Sans plaque'}' ,
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      value: driver.id,
                      groupValue: _selectedDriverId,
                      onChanged: (value) {
                        setState(() {
                          _selectedDriverId = value;
                        });
                      },
                      secondary: _getStatusIcon(driver.status),
                    )),
              ],
            ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _selectedDriverId == null
              ? null
              : _assignDriver,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirmer'),
        ),
      ],
    );
  }
}
