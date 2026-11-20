
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/property.dart';
import '../../../services/property_service.dart';
import '../properties/add_property_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  late Future<List<Property>> propertiesFuture;

  @override
  void initState() {
    super.initState();
    loadProperties();
  }

  void loadProperties() {
    propertiesFuture = RentKhojApi.myProperties();
  }

  Future<void> openAddProperty() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddPropertyScreen(),
      ),
    );

    if (result == true && mounted) {
      setState(loadProperties);
    }
  }

  Widget statCard(String title, int count, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.forest, size: 24),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Owner Centre'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(loadProperties);
          await propertiesFuture;
        },
        child: FutureBuilder<List<Property>>(
          future: propertiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 50,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text('Unable to load your listings'),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(loadProperties),
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              );
            }

            final properties = snapshot.data ?? [];

            final pending = properties
                .where((p) => p.status.toLowerCase() == 'pending')
                .length;

            final active = properties
                .where((p) =>
                    ['active', 'approved'].contains(p.status.toLowerCase()))
                .length;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Manage your properties',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage listings and find tenants through RentKhojRKL.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 22),

                Row(
                  children: [
                    statCard(
                      'Total Listings',
                      properties.length,
                      Icons.home_work_outlined,
                    ),
                    const SizedBox(width: 12),
                    statCard(
                      'Active',
                      active,
                      Icons.verified_outlined,
                    ),
                    const SizedBox(width: 12),
                    statCard(
                      'Pending',
                      pending,
                      Icons.hourglass_empty,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: openAddProperty,
                    icon: const Icon(Icons.add_home_outlined),
                    label: const Text('Add New Property'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'My Listings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),

                const SizedBox(height: 14),

                if (properties.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 35),
                    child: Column(
                      children: [
                        Icon(
                          Icons.home_work_outlined,
                          size: 55,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No properties listed yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Start by adding your first property.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                else
                  ...properties.map((property) {
                    final status = property.status;
                    final color = status.toLowerCase() == 'pending'
                        ? Colors.orange
                        : status.toLowerCase() == 'rejected'
                            ? Colors.red
                            : AppTheme.forest;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.moss,
                          child: Icon(
                            Icons.home_outlined,
                            color: AppTheme.forest,
                          ),
                        ),
                        title: Text(
                          property.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${property.area} • ₹${property.rent}/month',
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.circle,
                              color: color,
                              size: 10,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
