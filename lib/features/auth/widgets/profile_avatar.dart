import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/providers/auth_provider.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    super.key,
    this.radius = 48,
    this.editable = false,
  });

  final double radius;
  final bool editable;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _pick(ImageSource source) async {
    Navigator.of(context).pop(); // close the sheet first

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (picked == null) return;
      if (!mounted) return;

      setState(() => _uploading = true);

      final ok = await context
          .read<AuthProvider>()
          .uploadProfilePicture(File(picked.path));

      if (!mounted) return;
      setState(() => _uploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Profile picture updated.'
              : context.read<AuthProvider>().errorMessage ??
              'Upload failed.'),
          backgroundColor: ok ? const Color(0xFF1B5E3F) : null,
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);

      final denied = e.code == 'camera_access_denied' ||
          e.code == 'photo_access_denied';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(denied
              ? 'Permission denied. Enable it in your device settings to '
              'change your picture.'
              : 'Could not open the picker. Please try again.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    }
  }

  void _openSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Change profile picture',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => _pick(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => _pick(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: widget.radius,
          backgroundColor: scheme.primaryContainer,
          // Keyed on the URL so a new upload actually repaints -
          // without this Flutter reuses the cached image.
          backgroundImage: profile?.hasProfilePic == true
              ? NetworkImage(profile!.profilePicUrl!)
              : null,
          child: _uploading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : (profile?.hasProfilePic == true
              ? null
              : Text(
            profile?.initial ?? '?',
            style: TextStyle(
              fontSize: widget.radius * 0.7,
              fontWeight: FontWeight.bold,
              color: scheme.onPrimaryContainer,
            ),
          )),
        ),
        if (widget.editable && !_uploading)
          Material(
            color: scheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _openSheet,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.camera_alt,
                  size: widget.radius * 0.32,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}