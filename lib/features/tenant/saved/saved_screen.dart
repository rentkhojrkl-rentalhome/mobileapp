
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/property.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({
    super.key,
    required this.saved,
  });

  final Set<Property> saved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saved listings',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: saved.isEmpty
                ? const EmptyState(
                    icon: Icons.favorite_border,
                    text: 'Save properties you want to compare later.',
                  )
                : ListView(
                    children: saved
                        .map(
                          (property) => ListTile(
                            title: Text(property.title),
                            subtitle: Text(
                              '${property.area} · ₹${property.rent}/month',
                            ),
                            leading: const Icon(
                              Icons.favorite,
                              color: AppTheme.forest,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
