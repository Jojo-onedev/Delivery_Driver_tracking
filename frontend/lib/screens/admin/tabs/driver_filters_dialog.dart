import 'package:flutter/material.dart';

class DriverFiltersDialog extends StatefulWidget {
  final Map<String, bool> statusFilters;
  final Function(Map<String, bool>) onFiltersChanged;

  const DriverFiltersDialog({
    super.key,
    required this.statusFilters,
    required this.onFiltersChanged,
  });

  @override
  State<DriverFiltersDialog> createState() => _DriverFiltersDialogState();
}

class _DriverFiltersDialogState extends State<DriverFiltersDialog> {
  late Map<String, bool> _statusFilters;

  @override
  void initState() {
    super.initState();
    _statusFilters = Map.from(widget.statusFilters);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtres avancés'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statut du chauffeur',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ..._statusFilters.entries.map((entry) {
              return CheckboxListTile(
                title: Text(_getStatusText(entry.key)),
                value: entry.value,
                onChanged: (value) {
                  setState(() {
                    _statusFilters[entry.key] = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            widget.onFiltersChanged(_statusFilters);
            Navigator.pop(context);
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'online':
        return 'En ligne';
      case 'offline':
        return 'Hors ligne';
      case 'on_delivery':
        return 'En livraison';
      default:
        return status;
    }
  }
}
