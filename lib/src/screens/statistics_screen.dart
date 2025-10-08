import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget/src/blocs/home/home_bloc.dart';
import 'package:my_budget/src/models/expense.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, double> _currentMonthStats = {};
  Map<String, double> _lastMonthStats = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoaded) {
            _calculateStats(state.expenses);
            return _buildStatisticsContent();
          } else if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(child: Text('حدث خطأ في تحميل البيانات'));
          }
        },
      ),
    );
  }

  void _calculateStats(List<Expense> expenses) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    _currentMonthStats = _calculateMonthStats(expenses, currentMonth);
    _lastMonthStats = _calculateMonthStats(expenses, lastMonth);
  }

  Map<String, double> _calculateMonthStats(
    List<Expense> expenses,
    DateTime month,
  ) {
    double income = 0;
    double expensesTotal = 0;
    double debtToMe = 0;
    double debtFromMe = 0;

    for (final expense in expenses) {
      if (expense.date.year == month.year &&
          expense.date.month == month.month) {
        final amount = expense.getAmountInBaseCurrency();
        switch (expense.type) {
          case 'income':
            income += amount;
            break;
          case 'expense':
            expensesTotal += amount;
            break;
          case 'debt_to_me':
            debtToMe += amount;
            break;
          case 'debt_from_me':
            debtFromMe += amount;
            break;
        }
      }
    }

    final netBalance = income - expensesTotal;
    final double expensePercentage = income > 0
        ? (expensesTotal / income) * 100
        : 0;

    return {
      'income': income,
      'expenses': expensesTotal,
      'debtToMe': debtToMe,
      'debtFromMe': debtFromMe,
      'netBalance': netBalance,
      'expensePercentage': expensePercentage,
    };
  }

  Widget _buildStatisticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthSection('الشهر الحالي', _currentMonthStats, Colors.blue),
          const SizedBox(height: 24),
          _buildMonthSection('الشهر الماضي', _lastMonthStats, Colors.green),
          const SizedBox(height: 24),
          _buildComparisonSection(),
        ],
      ),
    );
  }

  Widget _buildMonthSection(
    String title,
    Map<String, double> stats,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('الدخل', stats['income']!, Colors.green),
            _buildStatRow('المصروفات', stats['expenses']!, Colors.red),
            _buildStatRow(
              'صافي الرصيد',
              stats['netBalance']!,
              stats['netBalance']! >= 0 ? Colors.blue : Colors.orange,
            ),
            _buildStatRow('دين لي', stats['debtToMe']!, Colors.teal),
            _buildStatRow('دين علي', stats['debtFromMe']!, Colors.purple),
            if (stats['income']! > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'نسبة الصرف: ${stats['expensePercentage']!.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            '${value.toStringAsFixed(2)} ₪',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection() {
    final incomeChange = _calculatePercentageChange(
      _currentMonthStats['income']!,
      _lastMonthStats['income']!,
    );
    final expenseChange = _calculatePercentageChange(
      _currentMonthStats['expenses']!,
      _lastMonthStats['expenses']!,
    );

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مقارنة مع الشهر الماضي',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildComparisonRow('الدخل', incomeChange),
            _buildComparisonRow('المصروفات', expenseChange),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, double change) {
    final isPositive = change >= 0;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final color = isPositive ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 4),
              Text(
                '${change.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculatePercentageChange(double current, double previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }
}
