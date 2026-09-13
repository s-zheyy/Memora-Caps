import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/capsule.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/capsule_service.dart';
import '../services/insight_service.dart';
import '../theme.dart';

class GrowthDashboardScreen extends StatelessWidget {
  const GrowthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final service = CapsuleService();

    return StreamBuilder<List<Capsule>>(
      stream: service.watchCapsules(),
      builder: (context, snap) {
        final capsules = snap.data ?? [];
        final reflections = capsules.where((c) => c.hasReflection).length;
        final achieved = capsules.where((c) => !c.isLocked).length;
        final streak = InsightService.computeStreak(capsules);
        final monthly = InsightService.monthlyReflectionActivity(capsules);
        final maxVal = (monthly.values.isEmpty ? 1 : monthly.values.reduce((a, b) => a > b ? a : b)).toDouble();

        return StreamBuilder<UserProfile?>(
          stream: auth.profileStream(),
          builder: (context, profileSnap) {
            final firstName = (profileSnap.data?.fullName ?? 'there').split(' ').first;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Growth', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _MiniStat(label: 'Reflections', value: '$reflections', icon: Icons.emoji_objects_outlined, color: AppColors.accentBlue),
                    const SizedBox(width: 10),
                    _MiniStat(label: 'Achieved', value: '$achieved', icon: Icons.check_circle_outline, color: AppColors.success),
                    const SizedBox(width: 10),
                    _MiniStat(label: 'Streak', value: '$streak days', icon: Icons.local_fire_department, color: AppColors.streak),
                  ],
                ),
                const SizedBox(height: 22),
                const Text('Monthly Reflection Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
                    child: SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          maxY: maxVal < 4 ? 4 : maxVal + 1,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final keys = monthly.keys.toList();
                                  final i = value.toInt();
                                  if (i < 0 || i >= keys.length) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(keys[i], style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: monthly.values.toList().asMap().entries.map((entry) {
                            return BarChartGroupData(x: entry.key, barRods: [
                              BarChartRodData(
                                toY: entry.value.toDouble(),
                                color: AppColors.navy,
                                width: 22,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
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
                        Text('AI Growth Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentBlue)),
                      ]),
                      const SizedBox(height: 10),
                      Text(InsightService.growthSummary(firstName, capsules), style: const TextStyle(fontSize: 12.5, height: 1.5)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ]),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
