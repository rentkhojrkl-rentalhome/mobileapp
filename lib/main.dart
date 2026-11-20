
import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'models/property.dart';

import 'features/tenant/home/home_screen.dart';
import 'features/tenant/explore/search_screen.dart';
import 'features/tenant/saved/saved_screen.dart';
import 'features/messages/messages_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/owner/dashboard/owner_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AuthService.instance.restoreSession();

  runApp(const RentKhojApp());
}

class RentKhojApp extends StatelessWidget {
  const RentKhojApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentKhojRKL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  String? userRole;

  final saved = <Property>{};

  @override
  void initState() {
    super.initState();
    _restoreUserRole();
  }

  Future<void> _restoreUserRole() async {
    if (!AuthService.instance.isLoggedIn) return;

    try {
      final user = await AuthService.instance.getCurrentUser();

      if (!mounted) return;

      setState(() {
        userRole = user['role']?.toString().toLowerCase();
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        userRole = null;
      });
    }
  }

  void _updateRole(String? role) {
    final normalizedRole = role?.toLowerCase();

    if (userRole == normalizedRole) return;

    setState(() {
      userRole = normalizedRole;
    });
  }

  void _handleListProperty() {
    if (userRole == 'owner') {
      setState(() {
        tab = 1;
      });
      return;
    }

    if (!AuthService.instance.isLoggedIn) {
      setState(() {
        tab = 3;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please login with your Owner account to list a property.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Property listing is available for Owner accounts.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = userRole == 'owner';

    final pages = [
      HomeScreen(
        saved: saved,
        onSaved: () => setState(() {}),
        onSearch: (properties) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SearchScreen(properties: properties),
            ),
          );
        },
        onListProperty: _handleListProperty,
      ),

      if (isOwner)
        const OwnerDashboardScreen()
      else
        SavedScreen(saved: saved),

      const MessagesScreen(),

      ProfileScreen(
        onRoleChanged: _updateRole,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[tab],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) {
          setState(() {
            tab = value;
          });
        },
        indicatorColor: const Color(0xFFCAEACB),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              isOwner
                  ? Icons.add_home_work_outlined
                  : Icons.favorite_border,
            ),
            selectedIcon: Icon(
              isOwner
                  ? Icons.add_home_work
                  : Icons.favorite,
            ),
            label: isOwner ? 'List Property' : 'Saved',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
