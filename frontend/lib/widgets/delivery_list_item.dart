import 'package:flutter/material.dart';
import '../models/delivery.dart';

class DeliveryListItem extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback? onTap;
  final bool showStatus;

  const DeliveryListItem({
    super.key,
    required this.delivery,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Commande #${delivery.orderId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showStatus) _buildStatusChip(context),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.person, 'Client: ${delivery.customerName}'),
              _buildInfoRow(Icons.location_on, 'Adresse: ${delivery.address}'),
              if (delivery.driverId != null)
                _buildInfoRow(Icons.delivery_dining, 'Chauffeur ID: ${delivery.driverId}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Créée le ${_formatDate(delivery.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    delivery.status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(delivery.status),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[800]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'picked':
        return Colors.blueAccent;
      case 'in_transit':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'assigned':
        return 'Assignée';
      case 'picked':
        return 'Récupérée';
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

  Widget _buildStatusChip(BuildContext context) {
    final statusColor = _getStatusColor(delivery.status);

    // Convertir la couleur en valeurs RVB normalisées (0.0-1.0)
    final baseRed = statusColor.r;
    final baseGreen = statusColor.g;
    final baseBlue = statusColor.b;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(
          red: baseRed * 0.1,
          green: baseGreen * 0.1,
          blue: baseBlue * 0.1,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(
            red: baseRed * 0.3,
            green: baseGreen * 0.3,
            blue: baseBlue * 0.3,
          ),
        ),
      ),
      child: Text(
        _getStatusText(delivery.status),
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year.toString().substring(2)}';
  }
}
