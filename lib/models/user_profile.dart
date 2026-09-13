import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at users/{uid} (document itself, capsules are a subcollection).

class UserProfile {
  final String uid;
  final String fullName;
  final String studentId;
  final String course;
  final String yearLevel;
  final String email;
  final String photoUrl;
  final String avatar;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.studentId,
    required this.course,
    required this.yearLevel,
    required this.email,
    this.photoUrl = '',
    this.avatar = '👩‍🎓',
    required this.createdAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      fullName: map['fullName'] ?? '',
      studentId: map['studentId'] ?? '',
      course: map['course'] ?? '',
      yearLevel: map['yearLevel'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      avatar: map['avatar'] ?? '👩‍🎓',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'studentId': studentId,
      'course': course,
      'yearLevel': yearLevel,
      'email': email,
      'photoUrl': photoUrl,
      'avatar': avatar,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}