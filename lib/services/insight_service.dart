import '../models/capsule.dart';

/// Generates the "AI Academic Insight" / "AI Growth Analysis" style text
/// seen in the mockups, computed locally from the user's real capsule data
/// (no external API key required). Swap the body of these methods for a
/// real LLM call later if desired — see README.
class InsightService {
  static String dashboardInsight(String firstName, List<Capsule> capsules) {
    if (capsules.isEmpty) {
      return 'Welcome, $firstName! Create your first memory capsule to '
          'start tracking your academic growth.';
    }
    final locked = capsules.where((c) => c.isLocked).toList();
    if (locked.isNotEmpty) {
      locked.sort((a, b) => a.unlockDate.compareTo(b.unlockDate));
      final next = locked.first;
      final days = next.unlockDate.difference(DateTime.now()).inDays;
      return 'Your reflection streak is soaring! $firstName, your '
          '"${next.title}" capsule is only $days day${days == 1 ? '' : 's'} '
          'away from unlocking. Ready to see your growth?';
    }
    return 'Great work, $firstName — every capsule is unlocked. Start a new '
        'one to keep building your reflection history.';
  }

  static String capsuleAnalysis(Capsule capsule) {
    final summary = capsule.originalReflection.isEmpty
        ? 'No original reflection was recorded for this capsule.'
        : 'You highlighted: "${_trim(capsule.originalReflection)}"';
    final growth = capsule.hasReflection
        ? 'Comparing then and now, your thinking has evolved — your latest '
            'notes show ${_trim(capsule.currentReflection)}'
        : 'Add a new reflection to see how your perspective has changed '
            'since you wrote this capsule.';
    final nextGoal = capsule.goal.isEmpty
        ? 'Set a goal next time you write a capsule to track progress.'
        : 'Keep working toward: ${_trim(capsule.goal)}';
    return '$summary\n\n$growth\n\n$nextGoal';
  }

  static String growthSummary(String firstName, List<Capsule> capsules) {
    if (capsules.isEmpty) {
      return 'Start opening capsules and adding reflections to generate '
          'your personalized growth summary.';
    }
    final reflected = capsules.where((c) => c.hasReflection).length;
    final opened = capsules.where((c) => !c.isLocked).length;
    final categories = capsules.map((c) => c.category).toSet();
    return '$firstName, your overall pattern shows steady improvement '
        'across $opened opened capsule${opened == 1 ? '' : 's'} spanning '
        '${categories.length} subject area${categories.length == 1 ? '' : 's'}. '
        'You\'ve added follow-up reflections to $reflected capsule'
        '${reflected == 1 ? '' : 's'} — keep that habit going to strengthen '
        'long-term memory synthesis.';
  }

  static String _trim(String text) {
    final clean = text.trim();
    return clean.length > 90 ? '${clean.substring(0, 90)}...' : clean;
  }

  /// Simple consecutive-day streak based on capsule creation / reflection days.
  static int computeStreak(List<Capsule> capsules) {
    final days = <DateTime>{};
    for (final c in capsules) {
      days.add(DateTime(c.createdAt.year, c.createdAt.month, c.createdAt.day));
      if (c.reflectionUpdatedAt != null) {
        days.add(DateTime(c.reflectionUpdatedAt!.year, c.reflectionUpdatedAt!.month,
            c.reflectionUpdatedAt!.day));
      }
    }
    if (days.isEmpty) return 0;
    final sorted = days.toList()..sort((a, b) => b.compareTo(a));
    int streak = 1;
    DateTime cursor = sorted.first;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (todayDate.difference(cursor).inDays > 1) return 0;
    for (int i = 1; i < sorted.length; i++) {
      final diff = cursor.difference(sorted[i]).inDays;
      if (diff == 1) {
        streak++;
        cursor = sorted[i];
      } else if (diff == 0) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Monthly reflection counts for the last 5 months, for the bar chart.
  static Map<String, int> monthlyReflectionActivity(List<Capsule> capsules) {
    final now = DateTime.now();
    final result = <String, int>{};
    for (int i = 4; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final label = _monthLabel(month.month);
      final count = capsules.where((c) {
        final ref = c.reflectionUpdatedAt ?? c.createdAt;
        return ref.year == month.year && ref.month == month.month;
      }).length;
      result[label] = count;
    }
    return result;
  }

  static String _monthLabel(int month) {
    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return labels[month - 1];
  }
}
