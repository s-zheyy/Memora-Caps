import 'package:flutter/material.dart';
import '../models/capsule.dart';
import '../services/capsule_service.dart';
import '../services/insight_service.dart';
import '../theme.dart';
import 'add_reflection_screen.dart';

/// Shows a single capsule.
///
/// IMPORTANT — this screen enforces the app's core rule:
/// a locked capsule cannot be read OR edited. There is no "Edit" action
/// anywhere for capsule content, at any time — once a capsule is created
/// its original reflection is permanent, so the before/after comparison
/// the app is built around actually means something. The only way to add
/// new content is "Add Reflection", which appends a new, separate entry —
/// it never overwrites what was originally written.
class CapsuleDetailsScreen extends StatelessWidget {
  final String capsuleId;
  const CapsuleDetailsScreen({super.key, required this.capsuleId});

  @override
  Widget build(BuildContext context) {
    final service = CapsuleService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capsule Details'),
        actions: [
          StreamBuilder<Capsule?>(
            stream: service.watchCapsule(capsuleId),
            builder: (context, snap) {
              final capsule = snap.data;
              if (capsule == null) return const SizedBox.shrink();
              // Only Delete is offered here — deliberately no Edit icon.
              return IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete capsule?'),
                      content: Text('This will permanently delete "${capsule.title}". This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await service.deleteCapsule(capsuleId);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Capsule?>(
        stream: service.watchCapsule(capsuleId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final capsule = snap.data;
          if (capsule == null) {
            return const Center(child: Text('This capsule no longer exists.'));
          }
          final locked = capsule.isLocked;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(capsule.category, style: const TextStyle(fontSize: 11, color: AppColors.accentBlue)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (locked ? AppColors.warning : AppColors.success).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(locked ? Icons.lock_outline : Icons.lock_open, size: 12, color: locked ? AppColors.warning : AppColors.success),
                              const SizedBox(width: 4),
                              Text(locked ? 'Locked' : 'Opened', style: TextStyle(fontSize: 11, color: locked ? AppColors.warning : AppColors.success)),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(capsule.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        locked ? 'Sealed until ${_fmt(capsule.unlockDate)}' : 'Unlocked on ${_fmt(capsule.unlockDate)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),

              // ── LOCKED STATE: content is hidden, not just uneditable ──
              if (locked) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warning.withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_outline, size: 36, color: AppColors.warning),
                      const SizedBox(height: 14),
                      const Text('This capsule is sealed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Text(
                        'Your goal and reflection are locked away until '
                        '${_fmt(capsule.unlockDate)} — that\'s the point. Come '
                        'back then to read what you wrote and see how far '
                        'you\'ve come.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ]

              // ── OPENED STATE: original content, permanently read-only ──
              else ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MY GOAL', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(capsule.goal.isEmpty ? 'No goal set.' : capsule.goal, style: const TextStyle(fontSize: 13, height: 1.4)),
                        const SizedBox(height: 14),
                        Row(children: const [
                          Text('ORIGINAL REFLECTION', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                          SizedBox(width: 6),
                          Icon(Icons.push_pin_outlined, size: 12, color: AppColors.textMuted),
                        ]),
                        const SizedBox(height: 4),
                        Text(capsule.originalReflection, style: const TextStyle(fontSize: 13, height: 1.4)),
                        const SizedBox(height: 4),
                        const Text(
                          'Permanent record — written when this capsule was created.',
                          style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('UNLOCKED ON', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                                Text(_fmt(capsule.unlockDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Row(children: [
                              const Text('MOOD THEN: ', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              Text(kMoodEmojis[capsule.mood] ?? '🙂', style: const TextStyle(fontSize: 16)),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (capsule.hasReflection) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('LATEST REFLECTION', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                              if (capsule.reflectionUpdatedAt != null)
                                Text(_fmt(capsule.reflectionUpdatedAt!), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(capsule.currentReflection, style: const TextStyle(fontSize: 13, height: 1.4)),
                          if (capsule.lessonsLearned.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text('LESSONS LEARNED', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(capsule.lessonsLearned, style: const TextStyle(fontSize: 13, height: 1.4)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentBlue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: const [
                        Icon(Icons.auto_awesome, color: AppColors.accentBlue, size: 18),
                        SizedBox(width: 6),
                        Text('AI Growth Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentBlue)),
                      ]),
                      const SizedBox(height: 10),
                      Text(InsightService.capsuleAnalysis(capsule), style: const TextStyle(fontSize: 12.5, height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AddReflectionScreen(capsule: capsule)),
                  ),
                  icon: const Icon(Icons.edit_note),
                  label: Text(capsule.hasReflection ? 'Update My Reflection' : 'Add Reflection'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) => '${_month(d.month)} ${d.day}, ${d.year}';
  String _month(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}
