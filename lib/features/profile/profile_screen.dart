
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../screens/login_screen.dart';
import '../../screens/edit_profile_screen.dart';
import '../owner/dashboard/owner_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<String?>? onRoleChanged;

  const ProfileScreen({
    super.key,
    this.onRoleChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService.instance;

  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _uploadingPhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final user = await _authService.getCurrentUser();

      if (!mounted) return;

      final role = user['role']?.toString().toLowerCase();

      setState(() {
        _user = user;
        _loading = false;
      });

      widget.onRoleChanged?.call(role);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _user = null;
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });

      widget.onRoleChanged?.call(null);
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();

      if (!mounted) return;

      setState(() {
        _user = null;
        _error = null;
      });

      widget.onRoleChanged?.call(null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          name: _user?['name']?.toString() ?? '',
          phone: _user?['phone']?.toString() ?? '',
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadUser();
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto) return;

    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image == null || !mounted) return;

      setState(() => _uploadingPhoto = true);

      final result = await _authService.uploadProfilePhoto(image);

      if (!mounted) return;

      await _loadUser();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'Profile photo updated successfully!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_user == null) {
      return Column(
        children: [
          Expanded(
            child: LoginScreen(
              onLoginSuccess: _loadUser,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      );
    }

    final name = _user!['name']?.toString() ?? 'RentKhoj User';
    final email = _user!['email']?.toString() ?? '';
    final phone = _user!['phone']?.toString() ?? '';
    final role = _user!['role']?.toString() ?? 'tenant';

    final photoUrl = _user!['profile_photo_url']?.toString() ?? '';
    final hasPhoto = photoUrl.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'My profile',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 24),

        // PROFILE PHOTO
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.moss,
                backgroundImage:
                    hasPhoto ? NetworkImage(photoUrl) : null,
                child: !hasPhoto
                    ? Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: AppTheme.forest,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppTheme.forest,
                  child: _uploadingPhoto
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 17,
                          onPressed: _pickAndUploadPhoto,
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Center(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppTheme.ink,
            ),
          ),
        ),

        Center(
          child: Chip(
            label: Text(role.toUpperCase()),
            backgroundColor: AppTheme.moss,
            labelStyle: const TextStyle(
              color: AppTheme.forest,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(height: 25),

        // CONTACT DETAILS
        Card(
          elevation: 0,
          color: AppTheme.moss,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.email_outlined,
                  color: AppTheme.forest,
                ),
                title: const Text('Email'),
                subtitle: Text(
                  email.isEmpty ? 'Not available' : email,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.phone_outlined,
                  color: AppTheme.forest,
                ),
                title: const Text('Phone'),
                subtitle: Text(
                  phone.isEmpty ? 'Not available' : phone,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // EDIT PROFILE
        FilledButton.icon(
          onPressed: _editProfile,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Profile'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.forest,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),

        const SizedBox(height: 12),

        // REFRESH PROFILE
        OutlinedButton.icon(
          onPressed: _loadUser,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh profile'),
        ),

        // OWNER CENTRE
        if (role.toLowerCase() == 'owner') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OwnerDashboardScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Owner Centre'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.forest,
                side: const BorderSide(color: AppTheme.forest),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // LOGOUT
        FilledButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.forest,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    );
  }
}
