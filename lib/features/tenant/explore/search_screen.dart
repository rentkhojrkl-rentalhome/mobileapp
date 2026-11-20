
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/property.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.properties,
  });

  final Future<List<Property>> properties;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String term = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find your next home'),
      ),
      body: FutureBuilder<List<Property>>(
        future: widget.properties,
        builder: (context, snap) {
          final found = (snap.data ?? [])
              .where(
                (p) =>
                    '${p.title} ${p.area} ${p.type}'
                        .toLowerCase()
                        .contains(term.toLowerCase()),
              )
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) {
                    setState(() => term = value);
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Area, property type, or title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: snap.connectionState != ConnectionState.done
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : snap.hasError
                        ? const EmptyState(
                            icon: Icons.cloud_off,
                            text: 'Unable to load properties.',
                          )
                        : found.isEmpty
                            ? const EmptyState(
                                icon: Icons.search_off,
                                text: 'No matching properties found.',
                              )
                            : ListView.builder(
                                itemCount: found.length,
                                itemBuilder: (context, index) {
                                  final property = found[index];

                                  return ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: AppTheme.moss,
                                      child: Icon(
                                        Icons.home,
                                        color: AppTheme.forest,
                                      ),
                                    ),
                                    title: Text(property.title),
                                    subtitle: Text(
                                      '${property.area} · ₹${property.rent}/month',
                                    ),
                                    trailing: Text(property.type),
                                  );
                                },
                              ),
              ),
            ],
          );
        },
      ),
    );
  }
}