import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../models/delivery.dart';
import '../../../services/delivery_service.dart';
import '../../../widgets/delivery_list_item.dart';
import '../../../widgets/assign_driver_dialog.dart';
import 'add_delivery_dialog.dart';

class DeliveriesTab extends StatefulWidget {
  const DeliveriesTab({super.key});

  @override
  State<DeliveriesTab> createState() => _DeliveriesTabState();
}

class _DeliveriesTabState extends State<DeliveriesTab> {
  String _selectedStatus = 'all';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Timer? _debounce;

  void debugLog(String message) {
  final now = DateTime.now().toIso8601String();
  debugPrint('[$now] 🔍 $message');
}


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDeliveries());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadDeliveries() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    debugLog('Chargement des livraisons...');
    try {
      await Provider.of<DeliveryService>(context, listen: false).fetchDeliveries(driverId: null); // Pas de driverId pour l'admin, charge toutes les livraisons
      debugLog('Livraisons chargées');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des livraisons: $e')),
      );
      debugLog('Erreur lors du chargement des livraisons: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildDeliveriesList(),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FloatingActionButton.extended(
            onPressed: _showAddDeliveryDialog,
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle livraison'),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une livraison...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                if (mounted) setState(() {});
              });
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('Toutes', 'all'),
                _buildStatusChip('En attente', 'pending'),
                _buildStatusChip('En cours', 'in_progress'),
                _buildStatusChip('Terminées', 'delivered'),
                _buildStatusChip('Annulées', 'cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedStatus = value),
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withAlpha(51),
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDeliveriesList() {
    debugLog('Building deliveries list');
    return Consumer<DeliveryService>(
      builder: (context, deliveryService, _) {
        debugLog('Building deliveries list');
        final deliveries = deliveryService.deliveries.where((delivery) {
          debugLog('Checking delivery ${delivery.id}');
          if (_selectedStatus != 'all' && delivery.status != _selectedStatus) return false;
          final searchTerm = _searchController.text.toLowerCase();
          if (searchTerm.isNotEmpty) {
            final searchIn = '${delivery.orderId} ${delivery.customerName} ${delivery.address}'.toLowerCase();
            if (!searchIn.contains(searchTerm)) return false;
          }
          return true;
        }).toList();

        if (deliveries.isEmpty) {
          debugLog('No deliveries found');
          return const Center(child: Text('Aucune livraison trouvée'));
        }

        return ListView.builder(
          itemCount: deliveries.length,
          itemBuilder: (context, index) {
            final delivery = deliveries[index];
            return DeliveryListItem(
              delivery: delivery,
              onTap: () => _showDeliveryDetails(delivery),
            );
          },
        );
      },
    );
  }

  void _showAddDeliveryDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddDeliveryDialog(),
    ).then((_) => _loadDeliveries());
  }

  void _showDeliveryDetails(Delivery delivery) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commande #${delivery.orderId}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow('Statut', _getStatusText(delivery.status)),
            const SizedBox(height: 12),
            _buildDetailRow('Client', delivery.customerName),
            _buildDetailRow('Adresse', delivery.address),
            if (delivery.driverId != null) _buildDetailRow('ID Chauffeur', delivery.driverId!),
            if (delivery.assignedAt != null) _buildDetailRow('Assigné le', _formatDate(delivery.assignedAt!)),
            if (delivery.pickedAt != null) _buildDetailRow('Récupéré le', _formatDate(delivery.pickedAt!)),
            if (delivery.deliveredAt != null) _buildDetailRow('Livré le', _formatDate(delivery.deliveredAt!)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (!mounted) return;
                  final navigator = Navigator.of(context);
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => AssignDriverDialog(
                      deliveryId: delivery.id,
                      currentDriverId: delivery.driverId,
                    ),
                  );
                  if (result == true && mounted) {
                    await _loadDeliveries();
                    if (mounted) navigator.pop();
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add, size: 20),
                    const SizedBox(width: 8),
                    Text(delivery.driverId == null ? 'Assigner un chauffeur' : 'Changer de chauffeur'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'assigned':
        return 'Assignée';
      case 'in_transit':
        return 'En cours';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
