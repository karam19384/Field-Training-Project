
import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Upload a user profile image (kept as-is for compatibility)
  Future<String?> uploadProfileImage(File file) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final ref = _storage.ref().child('users/$uid/profile.jpg');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Build a full JSON backup of user subcollections.
  Future<Map<String, dynamic>> buildBackupJson() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');
    final collections = <String>[
      'expenses', 'incomes', 'contacts', 'categories', 'debts'
    ];

    final backup = <String, dynamic>{};
    for (final col in collections) {
      final snap = await _firestore.collection('users').doc(uid).collection(col).get();
      backup[col] = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    }
    return backup;
  }

  /// Upload backup.json to Firebase Storage
  Future<void> uploadBackupJson(Map<String, dynamic> backup) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');
    final ref = _storage.ref('users/$uid/backup.json');
    final data = const Utf8Encoder().convert(jsonEncode(backup));
    await ref.putData(data, SettableMetadata(contentType: 'application/json'));
  }

  /// Download backup.json from Firebase Storage
  Future<Map<String, dynamic>> downloadBackupJson() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');
    final ref = _storage.ref('users/$uid/backup.json');
    final data = await ref.getData();
    if (data == null) throw Exception('No backup found');
    final text = const Utf8Decoder().convert(data);
    return jsonDecode(text) as Map<String, dynamic>;
  }

  /// Restore Firestore from a JSON backup (id preserved when exists)
  Future<void> restoreFromBackup(Map<String, dynamic> backup) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');
    final collections = <String>['expenses', 'incomes', 'contacts', 'categories', 'debts'];

    final batch = _firestore.batch();
    for (final col in collections) {
      final items = (backup[col] as List?) ?? [];
      for (final item in items) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = map.remove('id') as String?;
        final ref = _firestore.collection('users').doc(uid).collection(col).doc(id);
        batch.set(ref, map, SetOptions(merge: true));
      }
    }
    await batch.commit();
  }

  /// Delete all user subcollections and the user doc.
  Future<void> deleteAllUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');
    final collections = <String>['expenses', 'incomes', 'contacts', 'categories', 'debts'];

    for (final col in collections) {
      final snap = await _firestore.collection('users').doc(uid).collection(col).get();
      for (final d in snap.docs) {
        await d.reference.delete();
      }
    }
    await _firestore.collection('users').doc(uid).delete();
  }
}
