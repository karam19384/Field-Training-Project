class BudgetSummary {
  final double totalIncome; // إجمالي الدخل
  final double totalExpenses; // إجمالي المصروفات
  final double totalDebtToMe; // دين لي
  final double totalDebtFromMe; // دين علي
  final double netBalance; // الرصيد الصافي (الدخل - المصروفات)

  BudgetSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalDebtToMe,
    required this.totalDebtFromMe,
    required this.netBalance,
  });

  // دالة تحويل من JSON
  factory BudgetSummary.fromJson(Map<String, dynamic> json) {
    return BudgetSummary(
      totalIncome: (json['total_income'] as num? ?? 0.0).toDouble(),
      totalExpenses: (json['total_expenses'] as num? ?? 0.0).toDouble(),
      totalDebtToMe: (json['total_debt_to_me'] as num? ?? 0.0).toDouble(),
      totalDebtFromMe: (json['total_debt_from_me'] as num? ?? 0.0).toDouble(),
      netBalance: (json['net_balance'] as num? ?? 0.0).toDouble(),
    );
  }

  // دالة نسخ مع إمكانية تحديث القيم
  BudgetSummary copyWith({
    double? totalIncome,
    double? totalExpenses,
    double? totalDebtToMe,
    double? totalDebtFromMe,
    double? netBalance,
  }) {
    return BudgetSummary(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalDebtToMe: totalDebtToMe ?? this.totalDebtToMe,
      totalDebtFromMe: totalDebtFromMe ?? this.totalDebtFromMe,
      netBalance: netBalance ?? this.netBalance,
    );
  }

  @override
  String toString() {
    return 'BudgetSummary{totalIncome: $totalIncome, totalExpenses: $totalExpenses, totalDebtToMe: $totalDebtToMe, totalDebtFromMe: $totalDebtFromMe, netBalance: $netBalance}';
  }
}