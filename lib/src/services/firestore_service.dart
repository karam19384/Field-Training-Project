import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'currency_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  // التحقق من وجود المستخدم ورمي استثناء إذا لم يكن مسجل الدخول
  void _checkUserAuth() {
    if (userId == null) {
      throw Exception('يجب تسجيل الدخول أولاً!');
    }
  }

  // 1. إضافة مصروف جديد مع دعم تحويل العملات
  Future<void> addExpense({
    required String title,
    required double amount,
    required String type,
    String currency = '₪',
    String category = 'عام',
    String? notes,
    String? person,
  }) async {
    _checkUserAuth();

    double? exchangeRate;
    double? baseAmount;

    // إذا كانت العملة غير الشيكل، حساب سعر الصرف
    if (currency != '₪') {
      exchangeRate = await CurrencyService.getExchangeRate(currency, '₪');
      if (exchangeRate != null) {
        baseAmount = amount * exchangeRate;
      }
    } else {
      baseAmount = amount;
    }

    await _db.collection('users').doc(userId!).collection('expenses').add({
      'userId': userId, // إضافة userId للمستند نفسه للاستعلامات المتقدمة
      'title': title,
      'amount': amount,
      'type': type,
      'currency': currency,
      'category': category,
      'notes': notes,
      'person': person ?? '',
      'date': Timestamp.now(),
      'exchangeRate': exchangeRate,
      'baseAmount': baseAmount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. جلب مصاريف المستخدم الحالي فقط
  Stream<List<Map<String, dynamic>>> getExpenses() {
    if (userId == null) {
      return Stream.value([]);
    }

    return _db
        .collection('users')
        .doc(userId!)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              ...data,
              'id': doc.id,
              'date': (data['date'] as Timestamp).toDate().toIso8601String(),
            };
          }).toList(),
        );
  }

  // 3. حساب الميزانية المعدل مع الفصل بين الديون والمصاريف
  Stream<Map<String, dynamic>> getBudgetSummary() {
    if (userId == null) {
      return Stream.value({
        'total_income': 0.0,
        'total_expenses': 0.0,
        'total_debt_to_me': 0.0,
        'total_debt_from_me': 0.0,
        'net_balance': 0.0,
      });
    }

    return _db
        .collection('users')
        .doc(userId!)
        .collection('expenses')
        .snapshots()
        .map((snapshot) {
          double totalIncome = 0.0;
          double totalExpenses = 0.0;
          double totalDebtToMe = 0.0;
          double totalDebtFromMe = 0.0;

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final amount =
                (data['baseAmount'] as num?)?.toDouble() ??
                (data['amount'] as num?)?.toDouble() ??
                0.0;
            final type = data['type'] as String? ?? '';

            if (type == 'income') {
              totalIncome += amount;
            } else if (type == 'expense') {
              totalExpenses += amount;
            } else if (type == 'debt_to_me') {
              totalDebtToMe += amount;
            } else if (type == 'debt_from_me') {
              totalDebtFromMe += amount;
            }
          }

          final netBalance = totalIncome - (totalExpenses + totalDebtToMe);

          return {
            'total_income': totalIncome,
            'total_expenses': totalExpenses,
            'total_debt_to_me': totalDebtToMe,
            'total_debt_from_me': totalDebtFromMe,
            'net_balance': netBalance,
          };
        });
  }

  // 4. تحديث المصروف مع دعم تحويل العملات
  Future<void> updateExpense({
    required String expenseId,
    required String title,
    required double amount,
    required String type,
    String currency = '₪',
    String category = 'عام',
    String? notes,
    String? person,
  }) async {
    _checkUserAuth();

    double? exchangeRate;
    double? baseAmount;

    if (currency != '₪') {
      exchangeRate = await CurrencyService.getExchangeRate(currency, '₪');
      if (exchangeRate != null) {
        baseAmount = amount * exchangeRate;
      }
    } else {
      baseAmount = amount;
    }

    await _db
        .collection('users')
        .doc(userId!)
        .collection('expenses')
        .doc(expenseId)
        .update({
          'title': title,
          'amount': amount,
          'type': type,
          'currency': currency,
          'category': category,
          'notes': notes,
          'person': person ?? '',
          'exchangeRate': exchangeRate,
          'baseAmount': baseAmount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // 5. حذف المصروف
  Future<void> deleteExpense(String expenseId) async {
    _checkUserAuth();

    await _db
        .collection('users')
        .doc(userId!)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  // 6. جلب الإحصائيات حسب الفئة للمستخدم الحالي
  Stream<Map<String, double>> getCategoryStats() {
    if (userId == null) {
      return Stream.value({});
    }

    return _db
        .collection('users')
        .doc(userId!)
        .collection('expenses')
        .snapshots()
        .map((snapshot) {
          final categoryStats = <String, double>{};

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final category = data['category'] as String? ?? 'عام';
            final amount =
                (data['baseAmount'] as num?)?.toDouble() ??
                (data['amount'] as num?)?.toDouble() ??
                0.0;
            final type = data['type'] as String? ?? 'expense';

            if (type == 'expense') {
              categoryStats[category] =
                  (categoryStats[category] ?? 0.0) + amount;
            }
          }

          return categoryStats;
        });
  }

  // 7. جلب إحصائيات الديون للمستخدم الحالي
  Stream<Map<String, double>> getDebtStats() {
    if (userId == null) {
      return Stream.value({});
    }

    return _db
        .collection('users')
        .doc(userId!)
        .collection('expenses')
        .snapshots()
        .map((snapshot) {
          final debtStats = <String, double>{};

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final person = data['person'] as String?;
            final amount =
                (data['baseAmount'] as num?)?.toDouble() ??
                (data['amount'] as num?)?.toDouble() ??
                0.0;
            final type = data['type'] as String? ?? '';

            if (person != null &&
                (type == 'debt_to_me' || type == 'debt_from_me')) {
              final currentAmount = debtStats[person] ?? 0.0;
              if (type == 'debt_to_me') {
                debtStats[person] = currentAmount + amount;
              } else {
                debtStats[person] = currentAmount - amount;
              }
            }
          }

          return debtStats;
        });
  }

  // 8. دوال الإدارة (الدخل، الفئات، الأشخاص) للمستخدم الحالي فقط

  // 8.1 إضافة مصدر دخل
  Future<void> addIncomeSource({
    required String name,
    required double amount,
    String currency = '₪',
    String? description,
  }) async {
    _checkUserAuth();

    double? exchangeRate;
    double? baseAmount;

    if (currency != '₪') {
      exchangeRate = await CurrencyService.getExchangeRate(currency, '₪');
      if (exchangeRate != null) {
        baseAmount = amount * exchangeRate;
      }
    } else {
      baseAmount = amount;
    }

    await _db
        .collection('users')
        .doc(userId!)
        .collection('income_sources')
        .add({
          'userId': userId,
          'name': name,
          'amount': amount,
          'currency': currency,
          'baseAmount': baseAmount,
          'exchangeRate': exchangeRate,
          'description': description,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  // 8.2 جلب مصادر الدخل
  Stream<List<Map<String, dynamic>>> getIncomeSources() {
    if (userId == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(userId!)
        .collection('income_sources')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return {...data, 'id': doc.id};
          }).toList(),
        );
  }

  // 8.3 تحديث مصدر الدخل
  Future<void> updateIncomeSource({
    required String incomeSourceId,
    required String name,
    required double amount,
    String currency = '₪',
    String? description,
  }) async {
    _checkUserAuth();

    double? exchangeRate;
    double? baseAmount;

    if (currency != '₪') {
      exchangeRate = await CurrencyService.getExchangeRate(currency, '₪');
      if (exchangeRate != null) {
        baseAmount = amount * exchangeRate;
      }
    } else {
      baseAmount = amount;
    }

    await _db
        .collection('users')
        .doc(userId!)
        .collection('income_sources')
        .doc(incomeSourceId)
        .update({
          'name': name,
          'amount': amount,
          'currency': currency,
          'baseAmount': baseAmount,
          'exchangeRate': exchangeRate,
          'description': description,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // 8.4 حذف مصدر الدخل
  Future<void> deleteIncomeSource(String incomeSourceId) async {
    _checkUserAuth();
    await _db
        .collection('users')
        .doc(userId!)
        .collection('income_sources')
        .doc(incomeSourceId)
        .delete();
  }

  // 9. إضافة فئة
  Future<void> addCategory(String name) async {
    _checkUserAuth();
    await _db.collection('users').doc(userId!).collection('categories').add({
      'userId': userId,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 10. إضافة شخص
  Future<void> addContact(String name) async {
    _checkUserAuth();
    await _db.collection('users').doc(userId!).collection('contacts').add({
      'userId': userId,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 11. جلب الفئات للمستخدم الحالي فقط
  Stream<List<Map<String, dynamic>>> getCategories() {
    if (userId == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(userId!)
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return {...data, 'id': doc.id};
          }).toList(),
        );
  }

  // 12. جلب الأشخاص للمستخدم الحالي فقط
  Stream<List<Map<String, dynamic>>> getContacts() {
    if (userId == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(userId!)
        .collection('contacts')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return {...data, 'id': doc.id};
          }).toList(),
        );
  }

  // 13. حذف الفئة
  Future<void> deleteCategory(String categoryId) async {
    _checkUserAuth();
    await _db
        .collection('users')
        .doc(userId!)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  // 14. حذف الشخص
  Future<void> deleteContact(String contactId) async {
    _checkUserAuth();
    await _db
        .collection('users')
        .doc(userId!)
        .collection('contacts')
        .doc(contactId)
        .delete();
  }

  // 15. الحصول على بيانات المستخدم
  Future<Map<String, dynamic>?> getUserProfile() async {
    _checkUserAuth();
    final doc = await _db.collection('users').doc(userId!).get();
    return doc.data();
  }

  // 16. تحديث بيانات المستخدم
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    _checkUserAuth();
    await _db.collection('users').doc(userId!).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 17. جلب جميع معاملات المستخدم (للاستخدام في التصدير)
  Future<List<Map<String, dynamic>>> getAllUserTransactions() async {
    _checkUserAuth();
    final snapshot = await _db
        .collection('users')
        .doc(userId!)
        .collection('expenses')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'id': doc.id,
        'date': (data['date'] as Timestamp).toDate().toIso8601String(),
      };
    }).toList();
  }

  // 18. جلب إحصائيات شهرية
  Stream<Map<String, double>> getMonthlyStats(int year, int month) {
    if (userId == null) return Stream.value({});

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return _db
        .collection('users')
        .doc(userId!)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .map((snapshot) {
          double income = 0.0;
          double expenses = 0.0;
          double debtToMe = 0.0;
          double debtFromMe = 0.0;

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final amount =
                (data['baseAmount'] as num?)?.toDouble() ??
                (data['amount'] as num?)?.toDouble() ??
                0.0;
            final type = data['type'] as String? ?? '';

            switch (type) {
              case 'income':
                income += amount;
                break;
              case 'expense':
                expenses += amount;
                break;
              case 'debt_to_me':
                debtToMe += amount;
                break;
              case 'debt_from_me':
                debtFromMe += amount;
                break;
            }
          }

          final netBalance = income - expenses;

          return {
            'income': income,
            'expenses': expenses,
            'debtToMe': debtToMe,
            'debtFromMe': debtFromMe,
            'netBalance': netBalance,
            'expensePercentage': income > 0 ? (expenses / income) * 100 : 0,
          };
        });
  }

  // 19. جلب إحصائيات السنة
  Stream<Map<String, double>> getYearlyStats(int year) {
    if (userId == null) return Stream.value({});

    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31, 23, 59, 59);

    return _db
        .collection('users')
        .doc(userId!)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .map((snapshot) {
          double income = 0.0;
          double expenses = 0.0;
          double debtToMe = 0.0;
          double debtFromMe = 0.0;

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final amount =
                (data['baseAmount'] as num?)?.toDouble() ??
                (data['amount'] as num?)?.toDouble() ??
                0.0;
            final type = data['type'] as String? ?? '';

            switch (type) {
              case 'income':
                income += amount;
                break;
              case 'expense':
                expenses += amount;
                break;
              case 'debt_to_me':
                debtToMe += amount;
                break;
              case 'debt_from_me':
                debtFromMe += amount;
                break;
            }
          }

          final netBalance = income - expenses;

          return {
            'income': income,
            'expenses': expenses,
            'debtToMe': debtToMe,
            'debtFromMe': debtFromMe,
            'netBalance': netBalance,
            'expensePercentage': income > 0 ? (expenses / income) * 100 : 0,
          };
        });
  }

  // 20. حذف جميع بيانات المستخدم
  Future<void> deleteAllUserData() async {
    _checkUserAuth();

    // حذف جميع المجموعات الفرعية
    final collections = [
      'expenses',
      'income_sources',
      'categories',
      'contacts',
    ];

    for (final collection in collections) {
      final snapshot = await _db
          .collection('users')
          .doc(userId!)
          .collection(collection)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }

    // حذف مستند المستخدم الرئيسي
    await _db.collection('users').doc(userId!).delete();
  }
}
