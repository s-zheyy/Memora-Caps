import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/capsule.dart';

/// Handles all Create / Read / Update / Delete operations for capsules,
/// stored per-user at users/{uid}/capsules/{capsuleId}.
class CapsuleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No signed-in user.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users').doc(_uid).collection('capsules');

  /// CREATE
  Future<String> createCapsule(Capsule capsule) async {
    final doc = await _collection.add(capsule.toMap());
    return doc.id;
  }

  /// READ (live list, newest first)
  Stream<List<Capsule>> watchCapsules() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => Capsule.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// READ single capsule (live, used by the details screen)
  Stream<Capsule?> watchCapsule(String id) {
    return _collection.doc(id).snapshots().map(
          (doc) => doc.exists ? Capsule.fromMap(doc.id, doc.data()!) : null,
        );
  }

  /// UPDATE — the only way an existing capsule's document changes.
  /// Deliberately scoped to just the reflection fields (Add Reflection
  /// module): title/category/goal/originalReflection/unlockDate are
  /// immutable once created, so what's sealed in a locked capsule is
  /// guaranteed to be exactly what the user originally wrote.
  Future<void> addReflection({
    required String capsuleId,
    required String currentReflection,
    required String lessonsLearned,
  }) async {
    await _collection.doc(capsuleId).update({
      'currentReflection': currentReflection,
      'lessonsLearned': lessonsLearned,
      'reflectionUpdatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// DELETE
  Future<void> deleteCapsule(String id) async {
    await _collection.doc(id).delete();
  }
}
