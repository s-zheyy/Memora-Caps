import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // =========================
  // PRE-MADE AVATAR CHOICES
  // =========================

  static const List<String> _avatars = [
    '👩‍🎓',
    '🧑‍💻',
    '📚',
    '🧠',
    '🎨',
    '🌱',
    '⭐',
    '🚀',
    '📝',
    '💡',
    '🎯',
    '🏆',
  ];

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
                          child: Text(
                            profile.avatar,
                            style: const TextStyle(
                              fontSize: 40,
                            ),
                          ),
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
  // AVATAR SELECTION DIALOG
  // =========================

  void _showAvatarDialog(
    BuildContext context,
    UserProfile profile,
    AuthService auth,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Choose Your Avatar'),

          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: _avatars.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final avatar = _avatars[index];
                final isSelected = profile.avatar == avatar;

                return GestureDetector(
                  onTap: () async {
                    await auth.updateProfile(
                      UserProfile(
                        uid: profile.uid,
                        fullName: profile.fullName,
                        studentId: profile.studentId,
                        course: profile.course,
                        yearLevel: profile.yearLevel,
                        email: profile.email,
                        photoUrl: profile.photoUrl,
                        avatar: avatar,
                        createdAt: profile.createdAt,
                      ),
                    );

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.navyLight.withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.navyDark
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        avatar,
                        style: const TextStyle(
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
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
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}