import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/capsule.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/capsule_service.dart';
import '../services/insight_service.dart';
import '../theme.dart';
import 'capsule_details_screen.dart';
import 'capsules_list_screen.dart';
import 'create_edit_capsule_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final capsuleService = CapsuleService();

    return StreamBuilder<UserProfile?>(
      stream: auth.profileStream(),
      builder: (context, profileSnap) {
        final profile = profileSnap.data;
        final firstName = (profile?.fullName ?? 'there').split(' ').first;

        return StreamBuilder<List<Capsule>>(
          stream: capsuleService.watchCapsules(),
          builder: (context, capSnap) {
            final capsules = capSnap.data ?? [];
            final total = capsules.length;
            final locked = capsules.where((c) => c.isLocked).length;
            final opened = total - locked;
            final streak = InsightService.computeStreak(capsules);
            final recent = [...capsules]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return Scaffold(
              floatingActionButton: FloatingActionButton(
                backgroundColor: AppColors.navy,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateEditCapsuleScreen()),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome back, $firstName!',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              profile?.course.isNotEmpty == true
                                  ? profile!.course
                                  : ' ',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.navyLight,
                        child: Text(
                          profile?.avatar ?? '👩‍🎓',
                          style: const TextStyle(fontSize: 23),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: const [
                          Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
                          SizedBox(width: 6),
                          Text('AI Academic Insight',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          InsightService.dashboardInsight(firstName, capsules),
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Academic Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.4,
                    children: [
                      _StatCard(label: 'Total Capsules', value: '$total', icon: Icons.widgets_outlined, color: AppColors.accentBlue),
                      _StatCard(label: 'Locked', value: '$locked', icon: Icons.lock_outline, color: AppColors.warning),
                      _StatCard(label: 'Opened', value: '$opened', icon: Icons.lock_open, color: AppColors.success),
                      _StatCard(label: 'Streak', value: '$streak days', icon: Icons.local_fire_department, color: AppColors.streak),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Capsules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CapsulesListScreen()),
                        ),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  if (recent.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No capsules yet. Tap + to create one.', style: TextStyle(color: AppColors.textMuted))),
                    )
                  else
                    ...recent.take(3).map((c) => _RecentTile(capsule: c)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final Capsule capsule;
  const _RecentTile({required this.capsule});

  @override
  Widget build(BuildContext context) {
    final locked = capsule.isLocked;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CapsuleDetailsScreen(capsuleId: capsule.id)),
        ),
        leading: CircleAvatar(
          backgroundColor: locked ? AppColors.warning.withOpacity(0.15) : AppColors.success.withOpacity(0.15),
          child: Icon(locked ? Icons.lock_outline : Icons.lock_open, color: locked ? AppColors.warning : AppColors.success, size: 18),
        ),
        title: Text(capsule.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(capsule.category, style: const TextStyle(fontSize: 12)),
        trailing: Text(
          locked ? 'Unlocks ${_fmt(capsule.unlockDate)}' : 'Unlocked ${_fmt(capsule.unlockDate)}',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${_month(d.month)} ${d.day}, ${d.year}';
  String _month(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}
