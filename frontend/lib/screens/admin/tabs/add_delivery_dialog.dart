import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/delivery_service.dart';

class AddDeliveryDialog extends StatefulWidget {
  const AddDeliveryDialog({super.key});

  @override
  State<AddDeliveryDialog> createState() => _AddDeliveryDialogState();
}

class _AddDeliveryDialogState extends State<AddDeliveryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _orderIdController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _orderIdController.dispose();
    _customerNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final deliveryData = {
        'orderId': _orderIdController.text.trim(),
        'customerName': _customerNameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      await Provider.of<DeliveryService>(context, listen: false)
          .createDelivery(deliveryData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livraison créée avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
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
    return AlertDialog(
      title: const Text('Nouvelle livraison'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Numéro de commande
              TextFormField(
                controller: _orderIdController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de commande *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: CMD-2023-001',
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Le numéro de commande est requis'
                    : null,
              ),
              const SizedBox(height: 16),
              
              // Nom du client
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du client *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Le nom du client est requis'
                    : null,
              ),
              const SizedBox(height: 16),
              
              // Adresse de livraison
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse de livraison *',
                  border: OutlineInputBorder(),
                  hintText: 'Adresse complète du client',
                ),
                maxLines: 2,
                validator: (value) => value?.isEmpty ?? true
                    ? 'L\'adresse de livraison est requise'
                    : null,
              ),
              const SizedBox(height: 16),
              
              // Téléphone du client
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone du client *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 226 XX XX XX XX',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => (value?.isEmpty ?? true) || value!.length < 8
                    ? 'Un numéro de téléphone valide est requis'
                    : null,
              ),
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes supplémentaires',
                  hintText: 'Instructions spéciales, code de porte, etc.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      contentPadding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
      actions: [
        OverflowBar(
          alignment: MainAxisAlignment.end,
          spacing: 8,
          overflowAlignment: OverflowBarAlignment.end,
          children: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('ANNULER', style: TextStyle(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('CRÉER LA LIVRAISON', 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}
