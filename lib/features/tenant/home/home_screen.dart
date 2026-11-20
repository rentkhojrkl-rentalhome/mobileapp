
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_tile.dart';
import '../../../core/widgets/promo_banner.dart';
import '../../../core/widgets/property_card.dart';
import '../../../models/property.dart';
import '../../../services/property_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.saved,
    required this.onSaved,
    required this.onSearch,
    required this.onListProperty,
    required this.onMenuTap,
  });

  final Set<Property> saved;
  final VoidCallback onSaved;
  final ValueChanged<Future<List<Property>>> onSearch;
  final VoidCallback onListProperty;
  final VoidCallback? onMenuTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Property>> properties = RentKhojApi.properties();
  String selectedType = 'All';

  Future<void> refreshProperties() async {
    setState(() {
      properties = RentKhojApi.properties();
    });

    try {
      await properties;
    } catch (_) {}
  }

  void openSearch() {
    widget.onSearch(properties);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.forest,
      onRefresh: refreshProperties,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        children: [
          // LOCATION HEADER
          Row(
            children: [
             IconButton(
  onPressed: widget.onMenuTap,
  icon: const Icon(
    Icons.menu_rounded,
    color: AppTheme.forest,
    size: 28,
  ),
  style: IconButton.styleFrom(
    backgroundColor: AppTheme.moss,
    fixedSize: const Size(48, 48),
  ),
),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR LOCATION',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Row(
                      children: [
                        Text(
                          'Rourkela, Odisha',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 19,
                          color: AppTheme.forest,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.moss,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.forest,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // WELCOME TEXT
          const Text(
            'Find your',
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w500,
              color: AppTheme.ink,
            ),
          ),
          const Text(
            'perfect place.',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w900,
              color: AppTheme.forest,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover a home that matches your lifestyle.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 22),

          // SEARCH BAR
          InkWell(
            onTap: openSearch,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 17,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE5ECE5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.forest.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppTheme.forest,
                    size: 25,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search area, property or rent...',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.tune_rounded,
                    color: AppTheme.forest,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // CATEGORIES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Explore categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              Text(
                'Browse',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.forest.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 85,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'Room', 'Flat', 'House', 'PG']
                  .map(
                    (type) => CategoryChip(
                      label: type,
                      active: selectedType == type,
                      onTap: () {
                        setState(() => selectedType = type);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 20),

          // PROMO BANNER
          PromoBanner(
  onTap: widget.onListProperty,
),
          const SizedBox(height: 28),

          // FEATURED PROPERTIES HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Featured properties',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Explore homes around Rourkela',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: openSearch,
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: AppTheme.forest,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // PROPERTY LIST
          FutureBuilder<List<Property>>(
            future: properties,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.forest,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Column(
                  children: [
                    const EmptyState(
                      icon: Icons.cloud_off_outlined,
                      text:
                          'Could not connect to RentKhoj server. Please check your internet connection.',
                    ),
                    TextButton.icon(
                      onPressed: refreshProperties,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                );
              }

              final list = (snapshot.data ?? [])
                  .where(
                    (item) =>
                        selectedType == 'All' ||
                        item.type.toLowerCase() ==
                            selectedType.toLowerCase(),
                  )
                  .toList();

              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.home_work_outlined,
                  text:
                      'No available listings in this category yet. Try another category.',
                );
              }

              return SizedBox(
                height: 286,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: 14),
                  itemBuilder: (_, index) {
                    final property = list[index];

                    return PropertyCard(
                      property: property,
                      saved: widget.saved.contains(property),
                      onSaved: () {
                        setState(() {
                          if (widget.saved.contains(property)) {
                            widget.saved.remove(property);
                          } else {
                            widget.saved.add(property);
                          }
                        });
                        widget.onSaved();
                      },
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // TRUST SECTION
          const Text(
            'Rent with confidence',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'A better way to find your next home.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 14),

          const InfoTile(
            icon: Icons.verified_user_outlined,
            title: 'Verified owner badges',
            text:
                'See which owners have completed platform verification.',
          ),

          const InfoTile(
            icon: Icons.home_work_outlined,
            title: 'Local rental listings',
            text:
                'Explore rental options around your preferred area.',
          ),

          const InfoTile(
            icon: Icons.history_toggle_off,
            title: 'Rental status you can trust',
            text:
                'Owners mark their home Available, Rented, or Vacant. Rent agreements are not platform-verified.',
          ),
        ],
      ),
    );
  }
}
