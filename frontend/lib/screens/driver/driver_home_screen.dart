import 'package:flutter/material.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil Chauffeur'),
      ),
      body: const Center(
        child: Text('Bienvenue sur la page chauffeur !'),
      ),
    );
  }
}