import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

/// Wraps FirebaseAuth + the "users" Firestore collection.
/// Notifies listeners so screens can react to sign-in state changes.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registers a new account, then creates the matching profile document.
  Future<void> register({
    required String fullName,
    required String studentId,
    required String course,
    required String yearLevel,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    final profile = UserProfile(
      uid: uid,
      fullName: fullName.trim(),
      studentId: studentId.trim(),
      course: course.trim(),
      yearLevel: yearLevel.trim(),
      email: email.trim(),
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(uid).set(profile.toMap());
    await credential.user!.updateDisplayName(fullName.trim());
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Live stream of the signed-in user's profile document.
  Stream<UserProfile?> profileStream() {
    final uid = currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.uid).update(profile.toMap());
  }
}
