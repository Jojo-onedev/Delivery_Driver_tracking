import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery.dart';
import '../../services/delivery_service.dart';

import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  DriverHomeScreenState createState() => DriverHomeScreenState();
}

class DriverHomeScreenState extends State<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      // Accueil (Dashboard)
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDeliveries,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      _buildStatCard(
                        'En cours',
                        _deliveriesInProgress.toString(),
                        Icons.delivery_dining,
                        Colors.blue.shade100,
                        Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Livrées',
                        _deliveriesCompleted.toString(),
                        Icons.check_circle,
                        Colors.green.shade100,
                        Colors.green.shade700,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'En attente',
                        _deliveriesPending.toString(),
                        Icons.pending,
                        Colors.orange.shade100,
                        Colors.orange.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.blue.shade700,
                    labelColor: Colors.blue.shade700,
                    unselectedLabelColor: Colors.grey.shade600,
                    tabs: const [
                      Tab(text: 'En cours'),
                      Tab(text: 'En attente'),
                      Tab(text: 'Livrées'),
                    ],
                  ),
                  SizedBox(
                    height: 420,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDeliveryList(
                          _deliveries
                              .where((d) => d.status == 'assigned')
                              .toList(),
                        ),
                        _buildDeliveryList(
                          _deliveries
                              .where((d) => d.status == 'pending')
                              .toList(),
                        ),
                        _buildDeliveryList(
                          _deliveries
                              .where((d) => d.status == 'delivered')
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      // Livraisons (toutes)
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDeliveryList(_deliveries),
      // Historique (livraisons terminées)
      _buildHistoryList(
        _deliveries.where((d) => d.status == 'delivered').toList(),
      ),
      // Profil
      _buildProfileCard(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: _loadDeliveries,
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Livraisons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  int _currentIndex = 0;
  DeliveryService? _deliveryService;
  List<Delivery> _deliveries = [];
  bool _isLoading = true;
  late TabController _tabController;

  // Statistiques
  int _deliveriesInProgress = 0;
  int _deliveriesCompleted = 0;
  int _deliveriesPending = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Diffère la récupération des livraisons pour garantir que le Provider est prêt
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = Provider.of<AuthService>(context, listen: false).user;
      debugPrint('DEBUG user: $user');
      debugPrint('DEBUG user?.id: ${user?.id}');
      if (user?.id == null) {
        debugPrint('Erreur : ID du chauffeur non trouvé');
        // Affiche un message ou attends le chargement
        return;
      }
      await _deliveryService!.fetchDeliveries(driverId: user!.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deliveryService = Provider.of<DeliveryService>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDeliveries();
    });
  }

  Future<void> _loadDeliveries() async {
    if (_deliveryService == null) return;

    setState(() => _isLoading = true);

    try {
      // Récupère l'ID du chauffeur connecté au début de la fonction
      final driverId = Provider.of<AuthService>(context, listen: false).user?.id;
      await _deliveryService!.fetchDeliveries(forceRefresh: true, driverId: driverId);

      if (mounted) {
        setState(() {
          _deliveries = _deliveryService!.deliveries;
          _updateDeliveryStats();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateDeliveryStats() {
    _deliveriesInProgress = _deliveries
        .where((d) => d.status == 'assigned')
        .length;
    _deliveriesCompleted = _deliveries
        .where((d) => d.status == 'delivered')
        .length;
    _deliveriesPending = _deliveries.where((d) => d.status == 'pending').length;
  }

  // Widget pour les cartes de statistiques
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour la liste des livraisons
  Widget _buildDeliveryList(List<Delivery> deliveries) {
    if (deliveries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Aucune livraison',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        final delivery = deliveries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showDeliveryDetails(delivery),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icône de statut
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        delivery.status,
                      ).withAlpha((0.1 * 255).toInt()),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(delivery.status),
                      color: _getStatusColor(delivery.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Détails de la livraison
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande #${delivery.orderId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          delivery.customerName,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          delivery.address,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Badge de statut
                  _buildStatusChip(delivery.status),
                  const SizedBox(width: 8),
                  // Icône de flèche
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helpers pour le statut
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'assigned':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'assigned':
        color = Colors.blue;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(
        _getStatusText(status),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'assigned':
        return 'En cours';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  // Affichage du détail d'une livraison dans un bottom sheet
  void _showDeliveryDetails(Delivery delivery) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poignée de glissement
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // En-tête avec titre et statut
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Détails de la commande',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                        ),
                        _buildStatusChip(delivery.status),
                      ],
                    ),
                  ),
                  // Contenu défilable
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildDetailRow('N° Commande', delivery.orderId),
                        _buildDetailRow('Client', delivery.customerName),
                        _buildDetailRow(
                          'Téléphone',
                          delivery.phone ?? 'Non renseigné',
                        ),
                        _buildDetailRow('Adresse', delivery.address),
                        if (delivery.notes?.isNotEmpty ?? false)
                          _buildDetailRow('Notes', delivery.notes!),
                        // Informations de statut
                        const SizedBox(height: 24),
                        _buildStatusInfo(delivery),
                      ],
                    ),
                  ),
                  // Boutons d'action
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildActionButtons(delivery),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(Delivery delivery) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statut de la livraison',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusStep(
            'Commande reçue',
            Icons.check_circle,
            true,
            Colors.green,
          ),
          _buildStatusStep(
            'En préparation',
            Icons.check_circle,
            delivery.status != 'pending',
            delivery.status != 'pending' ? Colors.green : Colors.grey.shade300,
          ),
          _buildStatusStep(
            'En cours de livraison',
            delivery.status == 'assigned'
                ? Icons.directions_car
                : Icons.check_circle,
            delivery.status == 'assigned' || delivery.status == 'delivered',
            delivery.status == 'assigned'
                ? Colors.blue
                : delivery.status == 'delivered'
                ? Colors.green
                : Colors.grey.shade300,
            isCurrent: delivery.status == 'assigned',
          ),
          _buildStatusStep(
            'Livrée',
            Icons.check_circle,
            delivery.status == 'delivered',
            delivery.status == 'delivered'
                ? Colors.green
                : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(
    String label,
    IconData icon,
    bool isCompleted,
    Color color, {
    bool isCurrent = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isCurrent
                  ? color.withAlpha((0.1 * 255).toInt())
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isCompleted ? color : Colors.grey.shade300,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isCompleted ? Colors.black87 : Colors.grey.shade500,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Delivery delivery) {
    return Row(
      children: [
        if (delivery.status == 'pending') ...[
          _buildActionButton(
            'Démarrer la livraison',
            Icons.delivery_dining,
            () => _updateDeliveryStatus(delivery.id, 'assigned'),
            color: Colors.blue,
          ),
        ] else if (delivery.status == 'assigned') ...[
          Expanded(
            child: _buildActionButton(
              'Marquer comme livrée',
              Icons.check_circle,
              () => _updateDeliveryStatus(delivery.id, 'delivered'),
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'Signaler un problème',
              Icons.report_problem,
              () => _showProblemDialog(delivery.id),
              color: Colors.orange,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    VoidCallback onPressed, {
    Color color = Colors.blue,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _updateDeliveryStatus(String deliveryId, String status) async {
    try {
      Delivery? updatedDelivery;
      if (status == 'assigned') {
        updatedDelivery = await _deliveryService!.updateDeliveryStatus(
          deliveryId,
          'assigned',
        );
      } else if (status == 'delivered') {
        updatedDelivery = await _deliveryService!.updateDeliveryStatus(
          deliveryId,
          'delivered',
        );
      }
      if (mounted && updatedDelivery != null) {
        Navigator.pop(context);
        _showDeliveryDetails(updatedDelivery);
        _loadDeliveries();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: ${_getStatusText(status)}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
        );
      }
    }
  }

  void _showProblemDialog(String deliveryId) {
    final TextEditingController problemController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.report_problem, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  const Text(
                    'Signaler un problème',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Décrivez le problème rencontré lors de la livraison :',
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: problemController,
                        decoration: InputDecoration(
                          hintText: 'Décrivez le problème en détail...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez décrire le problème';
                          }
                          if (value.trim().length < 10) {
                            return 'La description est trop courte (min. 10 caractères)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Notre équipe sera notifiée et vous contactera si nécessaire.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('ANNULER'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            setState(() => isSubmitting = true);
                            try {
                              // Simuler un appel API
                              await Future.delayed(const Duration(seconds: 1));
                              if (context.mounted &&
                                  Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Votre signalement a été envoyé avec succès',
                                      ),
                                      backgroundColor: Colors.green.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => isSubmitting = false);
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('ENVOYER'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Liste des livraisons terminées (Historique)
  Widget _buildHistoryList(List<Delivery> deliveries) {
    if (deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Aucune livraison terminée',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: deliveries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final delivery = deliveries[index];
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 20),
              child: child,
            ),
          ),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.check_circle, color: Colors.green.shade700),
              ),
              title: Text(
                'Commande #${delivery.orderId}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivery.customerName,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  Text(
                    delivery.address,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  if (delivery.deliveredAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            delivery.deliveredAt != null
                                ? DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(delivery.deliveredAt!)
                                : '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => _showDeliveryDetails(delivery),
            ),
          ),
        );
      },
    );
  }

  // Carte profil chauffeur
  Widget _buildProfileCard() {
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user == null) {
      return const Center(child: Text('Aucun profil trouvé'));
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue.shade100,
            child: Icon(Icons.person, size: 40, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            user.vehicule ?? 'Type de véhicule inconnu',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Confirmer la déconnexion'),
                    content: const Text(
                      'Voulez-vous vraiment vous déconnecter ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Se déconnecter'),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  // Utilise un Builder pour garantir un contexte local sûr après await
                  //ignore: use_build_context_synchronously
                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );
                  try {
                    await authService.logout();
                    if (!mounted) return;
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la déconnexion: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
