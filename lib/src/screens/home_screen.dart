// lib/src/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/home/home_bloc.dart';
import '../blocs/home/home_event.dart';
import '../blocs/home/home_state.dart';
import '../widgets/app_drawer.dart'; // القائمة الجانبية اليمنى
// استيراد شاشة إضافة المصاريف (سيتم إنشاؤها لاحقاً)
// import 'add_expense_screen.dart'; 

class HomeScreen extends StatefulWidget {
  final User? user;
  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // عند تهيئة الشاشة، نطلب من HomeBloc جلب البيانات
    context.read<HomeBloc>().add(GetHomeDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(SignOutEvent());
            },
          ),
          // زر لفتح القائمة الجانبية اليمنى
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              );
            },
          ),
        ],
      ),
      // القائمة الجانبية اليمنى
      endDrawer: AppDrawer(user: widget.user,),
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          // التعامل مع حالات الأخطاء أو النجاح
          if (state is HomeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HomeLoaded) {
            final budgetSummary = state.budgetSummary;
            final expenses = state.expenses;
            final totalWithMe = budgetSummary['total_with_me'] ?? 0;
            final totalFromMe = budgetSummary['total_from_me'] ?? 0;

            return  Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // قسم الميزانية
                    _buildBudgetSummary(totalWithMe, totalFromMe),
                    const SizedBox(height: 20),
                    const Text(
                      'المصاريف الأخيرة:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // قائمة المصاريف
                    Expanded(
                      child: expenses.isEmpty
                          ? const Center(child: Text('لا توجد مصاريف حتى الآن.'))
                          : ListView.builder(
                              itemCount: expenses.length,
                              itemBuilder: (context, index) {
                                final expense = expenses[index];
                                return _buildExpenseItem(context, expense);
                              },
                            ),
                    ),
                  ],
                ),
            );
          }
          // حالة افتراضية لعرض رسالة خطأ
          return const Center(child: Text('حدث خطأ ما.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // يتم فتح نموذج إضافة المصروف هنا
          _showAddExpenseForm(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // دالة لبناء واجهة ملخص الميزانية
  Widget _buildBudgetSummary(double totalWithMe, double totalFromMe) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryColumn('دين لي', totalWithMe, Colors.green),
            _buildSummaryColumn('دين علي', totalFromMe, Colors.red),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لبناء أعمدة الملخص
  Widget _buildSummaryColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${amount.toStringAsFixed(2)} \$',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // دالة لبناء عنصر المصروف في القائمة
  Widget _buildExpenseItem(BuildContext context, Map<String, dynamic> expense) {
    final isDebtFromMe = expense['type'] == 'debt_from_me';
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(
          isDebtFromMe ? Icons.arrow_upward : Icons.arrow_downward,
          color: isDebtFromMe ? Colors.red : Colors.green,
        ),
        title: Text(expense['title'] ?? 'بدون عنوان'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الملاحظات: ${expense['notes'] ?? 'لا يوجد'}'),
            if (expense['person'] != null) Text('الشخص: ${expense['person']}'),
          ],
        ),
        trailing: Text(
          '${expense['amount']?.toStringAsFixed(2)} ${expense['currency']}',
          style: TextStyle(
            color: isDebtFromMe ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          // هنا سيتم التنقل إلى شاشة تفاصيل المصروف
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('سيتم عرض التفاصيل قريباً')),
          );
        },
      ),
    );
  }

  // دالة لعرض نموذج إضافة المصروف
  void _showAddExpenseForm(BuildContext context) {
    // يمكنك هنا استدعاء شاشة إضافة المصروف
    // showModalBottomSheet(
    //   context: context,
    //   builder: (context) {
    //     return AddExpenseScreen(); // سيتم إنشاء هذه الشاشة لاحقاً
    //   },
    // );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم فتح نموذج إضافة المصروف قريباً')),
    );
  }
}