import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single "memory capsule" document stored at:
/// users/{uid}/capsules/{capsuleId}
class Capsule {
  final String id;
  final String title;
  final String category;
  final String goal;
  final String originalReflection;
  final String mood; // emoji key: happy, calm, excited, motivated, thoughtful
  final DateTime createdAt;
  final DateTime unlockDate;

  // Fields populated once the capsule is opened / reflected on again.
  final String currentReflection;
  final String lessonsLearned;
  final DateTime? reflectionUpdatedAt;

  Capsule({
    required this.id,
    required this.title,
    required this.category,
    required this.goal,
    required this.originalReflection,
    required this.mood,
    required this.createdAt,
    required this.unlockDate,
    this.currentReflection = '',
    this.lessonsLearned = '',
    this.reflectionUpdatedAt,
  });

  /// A capsule is locked until "now" reaches its unlockDate.
  bool get isLocked => DateTime.now().isBefore(unlockDate);

  /// Has the user added a follow-up reflection since opening it?
  bool get hasReflection => currentReflection.trim().isNotEmpty;

  factory Capsule.fromMap(String id, Map<String, dynamic> map) {
    return Capsule(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? 'General',
      goal: map['goal'] ?? '',
      originalReflection: map['originalReflection'] ?? '',
      mood: map['mood'] ?? 'calm',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      unlockDate: (map['unlockDate'] is Timestamp)
          ? (map['unlockDate'] as Timestamp).toDate()
          : DateTime.now(),
      currentReflection: map['currentReflection'] ?? '',
      lessonsLearned: map['lessonsLearned'] ?? '',
      reflectionUpdatedAt: (map['reflectionUpdatedAt'] is Timestamp)
          ? (map['reflectionUpdatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'goal': goal,
      'originalReflection': originalReflection,
      'mood': mood,
      'createdAt': Timestamp.fromDate(createdAt),
      'unlockDate': Timestamp.fromDate(unlockDate),
      'currentReflection': currentReflection,
      'lessonsLearned': lessonsLearned,
      'reflectionUpdatedAt': reflectionUpdatedAt != null
          ? Timestamp.fromDate(reflectionUpdatedAt!)
          : null,
    };
  }

  Capsule copyWith({
    String? title,
    String? category,
    String? goal,
    String? originalReflection,
    String? mood,
    DateTime? unlockDate,
    String? currentReflection,
    String? lessonsLearned,
    DateTime? reflectionUpdatedAt,
  }) {
    return Capsule(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      goal: goal ?? this.goal,
      originalReflection: originalReflection ?? this.originalReflection,
      mood: mood ?? this.mood,
      createdAt: createdAt,
      unlockDate: unlockDate ?? this.unlockDate,
      currentReflection: currentReflection ?? this.currentReflection,
      lessonsLearned: lessonsLearned ?? this.lessonsLearned,
      reflectionUpdatedAt: reflectionUpdatedAt ?? this.reflectionUpdatedAt,
    );
  }
}

const List<String> kCapsuleCategories = [
  'Academic Goal',
  'Study Habits',
  'Challenges',
  'Learning Experience',
  'Achievement',
  'Personal Growth',
];

/// mood key -> emoji, used by the "How are you feeling today?" picker.
const Map<String, String> kMoodEmojis = {
  'happy': '😄',
  'calm': '😌',
  'excited': '🤩',
  'tired': '😴',
  'sad': '😔',
};
