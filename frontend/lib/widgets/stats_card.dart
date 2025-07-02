import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26), // ~10% d'opacité
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!)],
          ],
        ),
      ),
    );
  }
}
