// lib/src/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ... (Login and register methods remain the same) ...
  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register(String email, String password, String name) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    // تحديث اسم المستخدم بعد إنشاء الحساب
    await userCredential.user!.updateDisplayName(name);
    return userCredential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
  // دالة جديدة للحصول على المستخدم الحالي
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}