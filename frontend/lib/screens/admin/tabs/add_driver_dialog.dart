import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/driver_service.dart';

class AddDriverDialog extends StatefulWidget {
  const AddDriverDialog({super.key});

  @override
  State<AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _licensePlateController = TextEditingController();
  String? _selectedvehiculeType;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Liste des types de véhicules disponibles avec leurs libellés en français
  final List<Map<String, dynamic>> _vehiculeTypes = [
    {'value': 'car', 'label': 'Voiture'},
    {'value': 'motorbike', 'label': 'Moto'},
  ];
  
  // Valeur par défaut pour le type de véhicule
  final String _defaultVehiculeType = 'motorbike';

  @override
  void initState() {
    super.initState();
    // Définir la valeur par défaut pour le type de véhicule
    _selectedvehiculeType = _defaultVehiculeType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final driverData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'vehiculeType': _selectedvehiculeType,
        if (_selectedvehiculeType != 'on_foot')
          'licensePlate': _licensePlateController.text.trim(),
        'role': 'driver',
      };

      await Provider.of<DriverService>(
        context,
        listen: false,
      ).createDriver(driverData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chauffeur ajouté avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un chauffeur'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nom complet
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Ce champ est obligatoire';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value!)) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Téléphone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  border: OutlineInputBorder(),
                  prefixText: '+',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null,
              ),
              const SizedBox(height: 16),

              // Mot de passe
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe *',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ce champ est obligatoire';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirmation du mot de passe
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe *',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Champ de sélection du type de véhicule
              DropdownButtonFormField<String>(
                value: _selectedvehiculeType,
                decoration: const InputDecoration(
                  labelText: 'Type de véhicule *',
                  border: OutlineInputBorder(),
                  hintText: 'Sélectionnez un type de véhicule',
                ),
                isExpanded: true,
                items: _vehiculeTypes
                    .map<DropdownMenuItem<String>>((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'],
                    child: Text(
                      type['label'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedvehiculeType = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un type de véhicule';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Plaque d'immatriculation (conditionnelle)
              if (_selectedvehiculeType != null &&
                  _selectedvehiculeType != 'on_foot')
                TextFormField(
                  controller: _licensePlateController,
                  decoration: const InputDecoration(
                    labelText: 'Plaque d\'immatriculation',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: AB-123-CD',
                  ),
                  validator: (value) {
                    if ((_selectedvehiculeType == 'car' ||
                            _selectedvehiculeType == 'motorbike') &&
                        (value?.isEmpty ?? true)) {
                      return 'Ce champ est obligatoire pour ce type de véhicule';
                    }
                    return null;
                  },
                ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        // Bouton Annuler
        OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'ANNULER',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        // Bouton Ajouter
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text(
                  'AJOUTER LE CHAUFFEUR',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ],
    );
  }
}
