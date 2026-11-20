
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../services/auth_service.dart';

class AppDrawer extends StatefulWidget {
  final String role;
  final int selectedIndex;
  final ValueChanged<int> onNavigate;
  final VoidCallback onLogout;
  final VoidCallback onOpenNeedRoom;
  final VoidCallback onOpenMyRequirements;

  const AppDrawer({
    super.key,
    required this.role,
    required this.selectedIndex,
    required this.onNavigate,
    required this.onLogout,
    required this.onOpenNeedRoom,
    required this.onOpenMyRequirements,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, dynamic>? user;
  bool loading = true;

  bool get isOwner => widget.role.toLowerCase() == 'owner';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final result = await AuthService.instance.getCurrentUser();

      if (!mounted) return;

      setState(() {
        user = result;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void navigate(int index) {
    Navigator.pop(context);
    widget.onNavigate(index);
  }

  void openNeedRoom() {
    Navigator.pop(context);
    widget.onOpenNeedRoom();
  }

  void openMyRequirements() {
    Navigator.pop(context);
    widget.onOpenMyRequirements();
  }

  Widget menuItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final selected = widget.selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: selected ? AppTheme.moss : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: selected ? AppTheme.forest : Colors.black54,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppTheme.forest : AppTheme.ink,
            ),
          ),
          trailing: selected
              ? const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.forest,
                )
              : null,
          onTap: () => navigate(index),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 15, 7),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget extraMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      leading: Icon(icon, color: AppTheme.forest),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.ink,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: Colors.black38,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = user?['name']?.toString() ?? 'RentKhoj User';
    final email = user?['email']?.toString() ?? '';
    final photo = user?['profile_photo_url']?.toString() ?? '';

    final menu = isOwner
        ? [
            (Icons.home_outlined, 'Home', 0),
            (Icons.dashboard_outlined, 'Owner Dashboard', 1),
            (Icons.chat_bubble_outline, 'Messages', 2),
            (Icons.person_outline, 'My Profile', 3),
          ]
        : [
            (Icons.home_outlined, 'Home', 0),
            (Icons.favorite_border, 'Saved Properties', 1),
            (Icons.chat_bubble_outline, 'Messages', 2),
            (Icons.person_outline, 'My Profile', 3),
          ];

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.84,
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Column(
          children: [
            // PROFILE HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 22, 18, 24),
              decoration: const BoxDecoration(
                color: AppTheme.forest,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.home_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                      const SizedBox(width: 9),
                      const Expanded(
                        child: Text(
                          'RentKhojRKL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Hero(
                        tag: 'rentkhoj-profile-avatar',
                        child: CircleAvatar(
                          radius: 31,
                          backgroundColor: AppTheme.moss,
                          backgroundImage: photo.isNotEmpty
                              ? NetworkImage(photo)
                              : null,
                          child: photo.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 35,
                                  color: AppTheme.forest,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                loading ? 'Loading profile...' : name,
                                key: ValueKey(name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              isOwner ? 'OWNER ACCOUNT' : 'TENANT ACCOUNT',
                              style: const TextStyle(
                                color: Color(0xFFD6E9DE),
                                fontSize: 10,
                                letterSpacing: 1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () => navigate(3),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'View / Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // MENU
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                children: [
                  sectionTitle('Main Menu'),

                  ...menu.map(
                    (item) => menuItem(
                      icon: item.$1,
                      title: item.$2,
                      index: item.$3,
                    ),
                  ),

                  // TENANT ROOM REQUIREMENTS
                  if (!isOwner) ...[
                    sectionTitle('Room Requirements'),

                    extraMenuItem(
                      icon: Icons.add_home_work_outlined,
                      title: 'I Need a Room',
                      onTap: openNeedRoom,
                    ),

                    extraMenuItem(
                      icon: Icons.list_alt_rounded,
                      title: 'My Requirements',
                      onTap: openMyRequirements,
                    ),
                  ],

                  sectionTitle('Account'),

                  extraMenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Notification centre will be connected next.',
                          ),
                        ),
                      );
                    },
                  ),

                  extraMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings will be added next.'),
                        ),
                      );
                    },
                  ),

                  extraMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // LOGOUT FOOTER
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService.instance.logout();
                  widget.onLogout();
                },
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'RentKhojRKL • Made for Rourkela',
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
