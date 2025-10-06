// lib/src/models/expense.dart

class Expense {
  final String id;
  final String title;
  final double amount;
  final String currency;
  final String category;
  final DateTime date;
  final String? notes;
  final String type;
  final String? person;
  final double? exchangeRate; // سعر الصرف المستخدم
  final double? baseAmount; // المبلغ بالعملة الأساسية

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    this.notes,
    required this.type,
    this.person,
    this.exchangeRate,
    this.baseAmount,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'شيكل',
      category: json['category'] as String? ?? 'عام',
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      type: json['type'] as String? ?? 'expense',
      person: json['person'] as String?,
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
      baseAmount: (json['baseAmount'] as num?)?.toDouble(),
    );
  }

  // الحصول على المبلغ المعادل بالعملة الأساسية
  double getAmountInBaseCurrency() {
    return baseAmount ?? amount;
  }

  // الحصول على سعر الصرف إذا كان موجوداً
  String getExchangeRateInfo() {
    if (exchangeRate != null && currency != 'شيكل') {
      return 'سعر الصرف: ${exchangeRate!.toStringAsFixed(4)}';
    }
    return '';
  }
}