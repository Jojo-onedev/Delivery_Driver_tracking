import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/delivery_service.dart';
import '../../../widgets/stats_card.dart';
import '../../../widgets/recent_deliveries_list.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final deliveryService = Provider.of<DeliveryService>(
        context,
        listen: false,
      );
      
      await deliveryService.fetchDeliveries(forceRefresh: !_isInitialized);
      _isInitialized = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryService>(
      builder: (context, deliveryService, _) {
        final stats = deliveryService.getDeliveryStats();
        
        return RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête de bienvenue
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Bienvenue sur votre tableau de bord',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (_isLoading && !_isInitialized)
                  const Center(child: CircularProgressIndicator())
                else
                  ..._buildContent(stats),
              ],
            ),
          ),
        );
      },
    );
  }
  
  List<Widget> _buildContent(Map<String, int> stats) {
    return [
      // Cartes de statistiques
      const Text(
        'Aperçu des livraisons',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      _buildStatsGrid(context, stats),
      
      // Dernières livraisons
      const SizedBox(height: 24),
      const Text(
        'Dernières livraisons',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      const RecentDeliveriesList(limit: 5),
    ];
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, int> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        StatsCard(
          title: 'Total',
          value: '${stats['total'] ?? 0}',
          icon: Icons.local_shipping,
          color: Colors.blue,
        ),
        StatsCard(
          title: 'En attente',
          value: '${stats['pending'] ?? 0}',
          icon: Icons.schedule,
          color: Colors.orange,
        ),
        StatsCard(
          title: 'En cours',
          value: '${stats['in_progress'] ?? 0}',
          icon: Icons.directions_bike,
          color: Colors.green,
        ),
        StatsCard(
          title: 'Terminées',
          value: '${stats['delivered'] ?? 0}',
          icon: Icons.check_circle,
          color: Colors.teal,
        ),
      ],
    );
  }
}
