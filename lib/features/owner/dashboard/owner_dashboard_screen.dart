
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/property.dart';
import '../../../services/property_service.dart';
import '../properties/add_property_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const OwnerDashboardScreen({
    super.key,
    this.onMenuTap,
  });

  @override
  State<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState
    extends State<OwnerDashboardScreen> {
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

  Widget statCard(
    String title,
    int count,
    IconData icon,
  ) {
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
            Icon(
              icon,
              color: AppTheme.forest,
              size: 24,
            ),
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

      // OWNER APP BAR
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          onPressed: widget.onMenuTap,
          icon: const Icon(
            Icons.menu_rounded,
            size: 27,
            color: AppTheme.forest,
          ),
        ),
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              setState(loadProperties);
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.forest,
            ),
            tooltip: 'Refresh listings',
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: RefreshIndicator(
        color: AppTheme.forest,
        onRefresh: () async {
          setState(loadProperties);
          await propertiesFuture;
        },

        child: FutureBuilder<List<Property>>(
          future: propertiesFuture,
          builder: (context, snapshot) {

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.forest,
                ),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 50,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Unable to load your listings',
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(loadProperties);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ),
                ],
              );
            }

            final properties = snapshot.data ?? [];

            final pending = properties
                .where(
                  (p) =>
                      p.status.toLowerCase() == 'pending',
                )
                .length;

            final active = properties
                .where(
                  (p) => [
                    'active',
                    'approved',
                  ].contains(p.status.toLowerCase()),
                )
                .length;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                30,
              ),
              children: [

                // WELCOME HEADER
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
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 24),

                // DASHBOARD STATISTICS
                Row(
                  children: [
                    statCard(
                      'Total Listings',
                      properties.length,
                      Icons.home_work_outlined,
                    ),
                    const SizedBox(width: 10),
                    statCard(
                      'Active',
                      active,
                      Icons.verified_outlined,
                    ),
                    const SizedBox(width: 10),
                    statCard(
                      'Pending',
                      pending,
                      Icons.hourglass_empty_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // ADD PROPERTY BUTTON
                SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: openAddProperty,
                    icon: const Icon(
                      Icons.add_home_work_outlined,
                    ),
                    label: const Text(
                      'Add New Property',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // LISTINGS HEADER
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Listings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    Text(
                      '${properties.length} Properties',
                      style: const TextStyle(
                        color: AppTheme.forest,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // EMPTY STATE
                if (properties.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 35,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.border,
                      ),
                    ),
                    child: const Column(
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
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Start by adding your first property.',
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )

                // PROPERTY LIST
                else
                  ...properties.map((property) {
                    final status =
                        property.status.toLowerCase();

                    final color = status == 'pending'
                        ? Colors.orange
                        : status == 'rejected'
                            ? Colors.red
                            : AppTheme.forest;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.all(12),

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
                            color: AppTheme.ink,
                          ),
                        ),

                        subtitle: Padding(
                          padding: const EdgeInsets.only(
                            top: 6,
                          ),
                          child: Text(
                            '${property.area} • ₹${property.rent}/month',
                          ),
                        ),

                        trailing: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
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
