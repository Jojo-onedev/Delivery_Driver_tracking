import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'tabs/overview_tab.dart';
import 'tabs/deliveries_tab.dart';
import 'tabs/drivers_tab.dart';
import '../../widgets/loading_indicator.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  final List<Widget> _tabs = const [
    OverviewTab(),
    DeliveriesTab(),
    DriversTab(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Charger les données initiales ici
      await Future.delayed(const Duration(milliseconds: 500)); // Simulation de chargement
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des données: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleTabSelection() {
    // La méthode est conservée pour écouter les changements d'onglet
    // mais nous n'avons plus besoin de stocker l'index manuellement
  }

  Future<void> _handleRefresh() async {
    await _loadInitialData();
  }

  Future<void> _handleLogout() async {
    try {
      final authService = context.read<AuthService>();
      await authService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord administrateur'),
        centerTitle: true,
        actions: [
          // Bouton de rafraîchissement
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: 'Rafraîchir',
          ),
          // Menu utilisateur
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  _handleLogout();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: const [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Déconnexion'),
                    ],
                  ),
                ),
              ],
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user?.name.split(' ').first ?? 'Admin',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Aperçu'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Livraisons'),
            Tab(icon: Icon(Icons.people), text: 'Chauffeurs'),
          ],
          labelColor: Theme.of(context).primaryColor,
          indicatorColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : TabBarView(
              controller: _tabController,
              children: _tabs,
            ),
    );
  }
}