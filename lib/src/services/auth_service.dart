// lib/src/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // تسجيل الدخول
  Future<UserCredential> login(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email, 
      password: password
    );
    
    // تحديث آخر مرة تم الدخول فيها
    await _updateUserLastLogin(userCredential.user!.uid);
    
    return userCredential;
  }

  // إنشاء حساب جديد
  Future<UserCredential> register(String email, String password, String name) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password
    );
    
    // إنشاء مستند المستخدم في Firestore
    await _createUserDocument(
      userCredential.user!.uid, 
      email, 
      name
    );
    
    return userCredential;
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // الحصول على المستخدم الحالي
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // إنشاء مستند المستخدم في Firestore
  Future<void> _createUserDocument(String uid, String email, String name) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'currency': '₪', // العملة الافتراضية
      'language': 'ar', // اللغة الافتراضية
    });
  }

  // تحديث آخر مرة تم الدخول فيها
  Future<void> _updateUserLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // الحصول على بيانات المستخدم
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // تحديث بيانات المستخدم
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // حذف حساب المستخدم
  Future<void> deleteUserAccount(String uid) async {
    // حذف جميع بيانات المستخدم أولاً
    await _deleteUserData(uid);
    // ثم حذف الحساب من Authentication
    await _auth.currentUser!.delete();
  }

  // حذف جميع بيانات المستخدم
  Future<void> _deleteUserData(String uid) async {
    // حذف جميع المجموعات الفرعية
    final collections = ['expenses', 'incomes', 'categories', 'contacts'];
    
    for (final collection in collections) {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection(collection)
          .get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
    
    // حذف مستند المستخدم الرئيسي
    await _firestore.collection('users').doc(uid).delete();
  }
}