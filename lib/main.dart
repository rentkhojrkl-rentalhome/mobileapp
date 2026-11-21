import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'models/property.dart';

import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'core/widgets/app_drawer.dart';
import 'features/tenant/home/home_screen.dart';
import 'features/tenant/explore/search_screen.dart';
import 'features/tenant/saved/saved_screen.dart';
import 'features/messages/messages_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/owner/dashboard/owner_dashboard_screen.dart';
import 'features/tenant/requirements/need_room_screen.dart';
import 'features/tenant/requirements/my_requirements_screen.dart';

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
      home: const SplashGate(),
    );
  }
}

/// Shows the exact branded artwork, then opens the existing authentication
/// gate. Session restoration still happens before runApp, as before.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 4600), () {
      if (!mounted) return;
      setState(() => _finished = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _finished
          ? const AuthGate(key: ValueKey('auth-gate'))
          : const SplashScreen(key: ValueKey('brand-splash')),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  bool _authenticated = false;
  String? _userRole;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    if (!AuthService.instance.isLoggedIn) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _authenticated = false;
      });
      return;
    }

    try {
      final user = await AuthService.instance.getCurrentUser();
      final role = user['role']?.toString().toLowerCase();

      if (role != 'owner' && role != 'tenant') {
        throw Exception('Invalid account role.');
      }

      if (!mounted) return;
      setState(() {
        _userRole = role;
        _authenticated = true;
        _checking = false;
      });
    } catch (_) {
      await AuthService.instance.logout();
      if (!mounted) return;
      setState(() {
        _authenticated = false;
        _checking = false;
      });
    }
  }

  Future<void> _handleLoginSuccess() async {
    try {
      final user = await AuthService.instance.getCurrentUser();
      final role = user['role']?.toString().toLowerCase();

      if (role != 'owner' && role != 'tenant') {
        throw Exception('Your account role could not be verified.');
      }

      if (!mounted) return;
      setState(() {
        _userRole = role;
        _authenticated = true;
        _error = null;
      });
    } catch (e) {
      await AuthService.instance.logout();
      if (!mounted) return;
      setState(() {
        _authenticated = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!)),
      );
    }
  }

  void _handleLogout() {
    if (!mounted) return;
    setState(() {
      _authenticated = false;
      _userRole = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFFFCFDF9),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_rounded, size: 58, color: Color(0xFF07583C)),
              SizedBox(height: 18),
              Text(
                'RentKhojRKL',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF07583C),
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Color(0xFF07583C)),
            ],
          ),
        ),
      );
    }

    if (!_authenticated) {
      return LoginScreen(
        key: const ValueKey('login'),
        onLoginSuccess: _handleLoginSuccess,
      );
    }

    return AppShell(
      key: const ValueKey('app'),
      initialRole: _userRole ?? 'tenant',
      onLogout: _handleLogout,
    );
  }
}

class AppShell extends StatefulWidget {
  final String initialRole;
  final VoidCallback onLogout;

  const AppShell({
    super.key,
    required this.initialRole,
    required this.onLogout,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  late String userRole;

  final saved = <Property>{};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    userRole = widget.initialRole;
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _selectDrawerTab(int index) {
    setState(() => tab = index);
  }

  void _openNeedRoom() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NeedRoomScreen()),
    );
  }

  void _openMyRequirements() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyRequirementsScreen()),
    );
  }

  void _updateRole(String? role) {
    if (role != null && mounted) {
      setState(() => userRole = role.toLowerCase());
    }
    if (role == null && !AuthService.instance.isLoggedIn) {
      widget.onLogout();
    }
  }

  void _handleListProperty() {
    if (userRole == 'owner') {
      setState(() => tab = 1);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Property listing is available for Owner accounts.'),
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
        onMenuTap: _openDrawer,
      ),
      if (isOwner)
        OwnerDashboardScreen(onMenuTap: _openDrawer)
      else
        SavedScreen(saved: saved),
      const MessagesScreen(),
      ProfileScreen(onRoleChanged: _updateRole),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        role: userRole,
        selectedIndex: tab,
        onNavigate: _selectDrawerTab,
        onLogout: widget.onLogout,
        onOpenNeedRoom: _openNeedRoom,
        onOpenMyRequirements: _openMyRequirements,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(key: ValueKey(tab), child: pages[tab]),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        indicatorColor: const Color(0xFFCAEACB),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(isOwner ? Icons.add_home_work_outlined : Icons.favorite_border),
            selectedIcon: Icon(isOwner ? Icons.add_home_work : Icons.favorite),
            label: isOwner ? 'Dashboard' : 'Saved',
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

