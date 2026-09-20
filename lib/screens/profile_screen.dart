import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return StreamBuilder<UserProfile?>(
      stream: auth.profileStream(),
      builder: (context, snap) {
        final profile = snap.data;

        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (profile == null) {
          return const Center(
            child: Text('Profile not found.'),
          );
        }

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.navyDark,
                    AppColors.navyLight,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // PROFILE AVATAR
                  // =========================
                  GestureDetector(
                    onTap: () => _showAvatarDialog(
                      context,
                      profile,
                      auth,
                    ),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white24,
                          backgroundImage: _profileImage(profile),
                            child: profile.photoData.isEmpty
                              ? Text(
                                  profile.avatar,
                                  style: const TextStyle(fontSize: 40),
                                )
                              : null,
                        ),

                        Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.navyDark,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 14,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Tap avatar to change',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    profile.studentId,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            label: 'Course',
                            value: profile.course,
                          ),
                          const Divider(),
                          _InfoRow(
                            label: 'Year Level',
                            value: profile.yearLevel,
                          ),
                          const Divider(),
                          _InfoRow(
                            label: 'Email',
                            value: profile.email,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed: () => _showEditDialog(
                      context,
                      profile,
                      auth,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    onPressed: () async {
                      await auth.logout();

                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: AppColors.danger,
                    ),
                    label: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // PROFILE PHOTO SELECTION
  // =========================

  void _showAvatarDialog(
    BuildContext context,
    UserProfile profile,
    AuthService auth,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickProfilePhoto(context, profile, auth);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfilePhoto(
    BuildContext context,
    UserProfile profile,
    AuthService auth,
  ) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 320,
        maxHeight: 320,
      );
      if (image == null) return;

      final photoData = await auth.encodeProfilePhoto(image);
      await auth.updateProfile(
        UserProfile(
          uid: profile.uid,
          fullName: profile.fullName,
          studentId: profile.studentId,
          course: profile.course,
          yearLevel: profile.yearLevel,
          email: profile.email,
          photoUrl: '',
          photoData: photoData,
          avatar: profile.avatar,
          createdAt: profile.createdAt,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update profile photo.')),
        );
      }
    }
  }

  ImageProvider<Object>? _profileImage(UserProfile profile) {
    if (profile.photoData.isNotEmpty) {
      return MemoryImage(base64Decode(profile.photoData));
    }
    return null;
  }

  // =========================
  // EDIT PROFILE
  // =========================

  void _showEditDialog(
    BuildContext context,
    UserProfile profile,
    AuthService auth,
  ) {
    final courseCtrl = TextEditingController(
      text: profile.course,
    );

    final yearCtrl = TextEditingController(
      text: profile.yearLevel,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: courseCtrl,
              decoration: const InputDecoration(
                labelText: 'Course',
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: yearCtrl,
              decoration: const InputDecoration(
                labelText: 'Year Level',
              ),
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),

          TextButton(
            onPressed: () async {
              await auth.updateProfile(
                UserProfile(
                  uid: profile.uid,
                  fullName: profile.fullName,
                  studentId: profile.studentId,
                  course: courseCtrl.text.trim(),
                  yearLevel: yearCtrl.text.trim(),
                  email: profile.email,
                  photoUrl: profile.photoUrl,
                        photoData: profile.photoData,
                  avatar: profile.avatar,
                  createdAt: profile.createdAt,
                ),
              );

              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}