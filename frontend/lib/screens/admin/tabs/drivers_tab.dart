import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../models/driver.dart';
import '../../../services/driver_service.dart';
import '../../../widgets/driver_list_item.dart';
import 'add_driver_dialog.dart';
import 'driver_filters_dialog.dart';
import 'edit_driver_dialog.dart';

class DriversTab extends StatefulWidget {
  const DriversTab({super.key});

  @override
  State<DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends State<DriversTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  late Map<String, bool> _statusFilters = {
    'online': true,
    'offline': true,
    'on_delivery': true,
  };

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    if (!mounted) return;

    // Ne pas mettre à jour l'état pendant la construction initiale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isLoading = true);
    });

    try {
      // Désactiver les notifications pendant le chargement initial
      await Provider.of<DriverService>(
        context,
        listen: false,
      ).fetchDrivers(notify: false);

      // Mettre à jour l'état après le chargement
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        // Afficher l'erreur après la construction
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors du chargement des chauffeurs: $e'),
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un chauffeur...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              suffixIcon: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => DriverFiltersDialog(
                      statusFilters: _statusFilters,
                      onFiltersChanged: (filters) {
                        setState(() {
                          _statusFilters = filters;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            onChanged: (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            }),
          ),
        ),

        // Liste des chauffeurs
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildDriversList(),
        ),

        // Bouton d'ajout
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FloatingActionButton.extended(
            onPressed: _showAddDriverDialog,
            icon: const Icon(Icons.person_add, size: 20),
            label: const Text('Nouveau chauffeur'),
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriversList() {
    return Consumer<DriverService>(
      builder: (context, driverService, _) {
      debugPrint('🔍 Nombre total de chauffeurs dans le service: ${driverService.drivers.length}');

        final drivers = driverService.drivers.where((driver) {
          debugPrint('🔍 Vérification du chauffeur: ${driver.name} (${driver.status})');

          // Filtre par recherche
          final searchTerm = _searchController.text.toLowerCase();
          if (searchTerm.isNotEmpty) {
            final searchIn =
                '${driver.name} ${driver.email} ${driver.phone} ${driver.vehiculeType ?? ''}'
                    .toLowerCase();
            if (!searchIn.contains(searchTerm)) return false;
          }

          // Filtre par statut
          final isStatusVisible = _statusFilters[driver.status] ?? false;
          if (!isStatusVisible) return false;

          return true;
        }).toList();

        if (drivers.isEmpty) {
          return const Center(child: Text('Aucun chauffeur trouvé'));
        }

        return ListView.builder(
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = drivers[index];
            return DriverListItem(
              driver: driver,
              onTap: () => _showDriverDetails(driver),
            );
          },
        );
      },
    );
  }

  void _showAddDriverDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddDriverDialog(),
    ).then((_) => _loadDrivers());
  }

  void _showDriverDetails(Driver driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: driver.isOnline ? Colors.green : Colors.grey,
                  radius: 5,
                ),
                const SizedBox(width: 8),
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Statut', driver.statusText),
            _buildDetailRow('Email', driver.email),
            _buildDetailRow('Téléphone', driver.phone),
            if (driver.vehiculeType != null)
              _buildDetailRow(
                'Véhicule',
                '${driver.vehiculeType} ${driver.licensePlate ?? ''}',
              ),
            if (driver.createdAt != null)
              _buildDetailRow(
                'Inscrit le',
                '${driver.createdAt!.day}/${driver.createdAt!.month}/${driver.createdAt!.year}',
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditDriverDialog(driver);
                    },
                    child: const Text('Modifier'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDeleteDriver(driver);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDriverDialog(Driver driver) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditDriverDialog(driver: driver),
    );

    if (result == true && mounted) {
      await _loadDrivers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chauffeur mis à jour avec succès')),
        );
      }
    }
  }

  void _confirmDeleteDriver(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le chauffeur ${driver.name} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final driverService = Provider.of<DriverService>(
                context,
                listen: false,
              );

              navigator.pop();
              try {
                await driverService.deleteDriver(driver.id);
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Chauffeur supprimé avec succès'),
                    ),
                  );
                  await _loadDrivers();
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la suppression: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
