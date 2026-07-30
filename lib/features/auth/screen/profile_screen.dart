import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/providers/auth_provider.dart';
import 'package:fruitripe/features/auth/screen/edit_profile_screen.dart';
import 'package:fruitripe/features/auth/widgets/profile_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access '
            'your inventory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await context.read<AuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AuthProvider>().refreshProfile(),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Column(
                children: [
                  const ProfileAvatar(radius: 52, editable: true),
                  const SizedBox(height: 16),
                  Text(
                    profile.username,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _SectionLabel('Account'),
            _InfoTile(
              icon: Icons.person_outline,
              label: 'Username',
              value: profile.username,
            ),
            _InfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: profile.email,
              // Email lives in auth.users, not app_user, and the
              // database trigger blocks changing it here.
              trailing: const Tooltip(
                message: 'Email cannot be changed',
                child: Icon(Icons.lock_outline, size: 16),
              ),
            ),
            _InfoTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: (profile.phoneNumber?.trim().isNotEmpty ?? false)
                  ? profile.phoneNumber!
                  : 'Not set',
            ),

            const SizedBox(height: 24),
            _SectionLabel('Preferences'),
            _InfoTile(
              icon: Icons.notifications_outlined,
              label: 'Spoilage alerts',
              value: profile.alertPreference.label,
            ),

            const SizedBox(height: 24),
            _SectionLabel('About'),
            _InfoTile(
              icon: Icons.calendar_today_outlined,
              label: 'Member since',
              value: _formatDate(profile.createdAt),
            ),

            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: auth.busy ? null : () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: Icon(icon),
        title: Text(label, style: Theme.of(context).textTheme.bodySmall),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        trailing: trailing,
        dense: true,
      ),
    );
  }
}