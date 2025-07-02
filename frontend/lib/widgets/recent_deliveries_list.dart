import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/delivery_service.dart';
import 'delivery_list_item.dart';

class RecentDeliveriesList extends StatelessWidget {
  final int limit;

  const RecentDeliveriesList({
    super.key,
    this.limit = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryService>(
      builder: (context, deliveryService, _) {
        if (deliveryService.isLoading && deliveryService.deliveries.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (deliveryService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement des livraisons',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  deliveryService.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => deliveryService.fetchDeliveries(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final deliveries = deliveryService.deliveries.take(limit).toList();

        if (deliveries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Aucune livraison récente'),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: deliveries.length,
          itemBuilder: (context, index) {
            final delivery = deliveries[index];
            return DeliveryListItem(
              delivery: delivery,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/delivery-details',
                  arguments: {'deliveryId': delivery.id},
                );
              },
            );
          },
        );
      },
    );
  }
}
