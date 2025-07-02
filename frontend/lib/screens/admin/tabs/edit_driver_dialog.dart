import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/driver.dart';
import '../../../services/driver_service.dart';

class EditDriverDialog extends StatefulWidget {
  final Driver driver;

  const EditDriverDialog({super.key, required this.driver});

  @override
  State<EditDriverDialog> createState() => _EditDriverDialogState();
}

class _EditDriverDialogState extends State<EditDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _vehiculeTypeController;
  late TextEditingController _licensePlateController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driver.name);
    _emailController = TextEditingController(text: widget.driver.email);
    _phoneController = TextEditingController(text: widget.driver.phone);
    _vehiculeTypeController = TextEditingController(
      text: widget.driver.vehiculeType ?? '',
    );
    _licensePlateController = TextEditingController(
      text: widget.driver.licensePlate ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehiculeTypeController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Future<void> _updateDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final driverService = context.read<DriverService>();
      final updates = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        if (_vehiculeTypeController.text.trim().isNotEmpty)
          'vehiculeType': _vehiculeTypeController.text.trim(),
        if (_licensePlateController.text.trim().isNotEmpty)
          'licensePlate': _licensePlateController.text.trim(),
      };

      await driverService.updateDriver(widget.driver.id, updates);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la mise à jour du chauffeur: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le chauffeur'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Ce champ est requis';
                  if (!value!.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehiculeTypeController,
                decoration: const InputDecoration(
                  labelText: 'Type de véhicule (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licensePlateController,
                decoration: const InputDecoration(
                  labelText: 'Plaque d\'immatriculation (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...{
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              },
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateDriver,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
