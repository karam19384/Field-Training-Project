
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<String?> uploadProfileImage(File file) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final ref = _storage.ref().child('users/$uid/profile.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _firestore.collection('users').doc(uid).set({'photoUrl': url}, SetOptions(merge: true));
    return url;
  }
}
