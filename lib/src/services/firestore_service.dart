// lib/src/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // الحصول على معرف المستخدم الحالي
  String? get userId => _auth.currentUser?.uid;

  // 1. إضافة مصروف جديد
  Future<void> addExpense({
    required String title,
    required double amount,
    required String type,
    required String currency,
    required String notes,
    String? person,
  }) async {
    if (userId == null) {
      throw Exception('User not logged in!');
    }

    await _db.collection('expenses').add({
      'userId': userId,
      'title': title,
      'amount': amount,
      'type': type,
      'currency': currency,
      'notes': notes,
      'person': person,
      'date': Timestamp.now(),
    });
  }

  // 2. جلب جميع مصاريف المستخدم
  // هذه الدالة ستعالج المشكلة التي واجهتها
  Stream<List<Map<String, dynamic>>> getExpenses() {
    if (userId == null) {
      return Stream.value([]);
    }

    return _db
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {...doc.data(), 'id': doc.id};
      }).toList();
    });
  }

  // 3. حساب الميزانية
  Stream<Map<String, double>> getBudgetSummary() {
    if (userId == null) {
      return Stream.value({'total_with_me': 0, 'total_from_me': 0});
    }

    return _db
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      double totalWithMe = 0;
      double totalFromMe = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final type = data['type'] as String? ?? '';

        if (type == 'debt_to_me') {
          totalWithMe += amount;
        } else if (type == 'debt_from_me') {
          totalFromMe += amount;
        }
      }

      return {
        'total_with_me': totalWithMe,
        'total_from_me': totalFromMe,
      };
    });
  }

  // 4. حذف مصروف
  Future<void> deleteExpense(String expenseId) async {
    if (userId == null) {
      throw Exception('User not logged in!');
    }
    await _db.collection('expenses').doc(expenseId).delete();
  }
}