import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/core/validators.dart';
import 'package:fruitripe/providers/auth_provider.dart';
import 'package:fruitripe/features/auth/widgets/auth_error_banner.dart';
import 'package:fruitripe/features/auth/widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _phoneCtrl;
  late AlertPreference _alertPreference;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _usernameCtrl = TextEditingController(text: profile?.username ?? '');
    _phoneCtrl = TextEditingController(text: profile?.phoneNumber ?? '');
    _alertPreference = profile?.alertPreference ?? AlertPreference.before24h;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final profile = context.read<AuthProvider>().profile;
    if (profile == null) return false;
    return _usernameCtrl.text.trim() != profile.username ||
        _phoneCtrl.text.trim() != (profile.phoneNumber ?? '') ||
        _alertPreference != profile.alertPreference;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await context.read<AuthProvider>().updateProfile(
      username: _usernameCtrl.text,
      phoneNumber: _phoneCtrl.text,
      alertPreference: _alertPreference,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your profile has been updated successfully!'),
          backgroundColor: Color(0xFF1B5E3F),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account Setting'),
          actions: [
            TextButton(
              onPressed: auth.busy ? null : _save,
              child: const Text('Save'),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: ProfileAvatar(radius: 48, editable: true),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Tap the camera icon to change your picture',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _usernameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.username,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Read-only. Email belongs to auth.users and the
                  // protect_privileged_columns() trigger rejects any
                  // attempt to change it through app_user.
                  TextFormField(
                    initialValue: profile?.email ?? '',
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                      helperText: 'Email cannot be changed',
                      suffixIcon: Icon(Icons.lock_outline, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                      hintText: '+60 12-345 6789',
                      helperText: 'Optional',
                    ),
                    validator: Validators.phoneOptional,
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 32),
                  Text(
                    'SPOILAGE ALERTS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'When should we remind you about fruit nearing its '
                        'expiry?',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),

                  ...AlertPreference.values.map(
                        (pref) => RadioListTile<AlertPreference>(
                      value: pref,
                      groupValue: _alertPreference,
                      title: Text(pref.label),
                      contentPadding: EdgeInsets.zero,
                      onChanged: auth.busy
                          ? null
                          : (v) => setState(() => _alertPreference = v!),
                    ),
                  ),

                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    AuthErrorBanner(message: auth.errorMessage!),
                  ],

                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: (auth.busy || !_hasChanges) ? null : _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: auth.busy
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Save Changes'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}