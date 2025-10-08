import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../models/budget_summary.dart';
import '../blocs/home/home_bloc.dart';
import '../widgets/app_drawer.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/expense_detail_dialog.dart';
import '../services/currency_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'الكل';
  List<Expense> _filteredExpenses = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // تأخير تحميل البيانات لتجنب مشاكل التهيئة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeBloc>().add(const GetHomeDataEvent());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _updateFilteredExpenses(List<Expense> expenses) {
    if (!mounted) return; // التحقق من أن الـ widget ما زال mounted
    
    setState(() {
      _filteredExpenses = _filterExpenses(expenses, _searchQuery, _selectedFilter);
    });
  }

  List<Expense> _filterExpenses(List<Expense> expenses, String searchText, String selectedFilter) {
    return expenses.where((expense) {
      final matchesSearch = searchText.isEmpty || 
          expense.title.toLowerCase().contains(searchText.toLowerCase()) ||
          (expense.notes?.toLowerCase().contains(searchText.toLowerCase()) ?? false) ||
          (expense.person?.toLowerCase().contains(searchText.toLowerCase()) ?? false);

      final matchesType = selectedFilter == 'الكل' || 
          _getTypeValue(selectedFilter) == expense.type;

      return matchesSearch && matchesType;
    }).toList();
  }

  String _getTypeValue(String arabicType) {
    switch (arabicType) {
      case 'مصروف': return 'expense';
      case 'دخل': return 'income';
      case 'دين لي': return 'debt_to_me';
      case 'دين علي': return 'debt_from_me';
      default: return arabicType;
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        
      ),
      drawer: AppDrawer(user: user),
      body: BlocListener<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeLoaded) {
            _updateFilteredExpenses(state.expenses);
          }
        },
        child: Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeLoading || state is HomeInitial) {
                    return _buildLoadingState();
                  }

                  if (state is HomeError) {
                    return _buildErrorState(state.message);
                  }

                  if (state is HomeLoaded) {
                    return _buildContent(state.budgetSummary);
                  }

                  return _buildErrorState('حالة غير متوقعة');
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseForm(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // شريط البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث في المعاملات...',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          
          // خيارات التصفية
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('الكل'),
                _buildFilterChip('مصروف'),
                _buildFilterChip('دخل'),
                _buildFilterChip('دين لي'),
                _buildFilterChip('دين علي'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: _selectedFilter == label,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? label : 'الكل';
          });
          if (context.read<HomeBloc>().state is HomeLoaded) {
            final state = context.read<HomeBloc>().state as HomeLoaded;
            _updateFilteredExpenses(state.expenses);
          }
        },
        selectedColor: Colors.blueAccent,
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildContent(BudgetSummary summary) {
    return Column(
      children: [
        _buildBudgetSummary(summary),
        const SizedBox(height: 16),
        _buildExpensesList(),
      ],
    );
  }

  Widget _buildBudgetSummary(BudgetSummary summary) {
    final netBalance = summary.netBalance;
    final Color balanceColor = netBalance >= 0 ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'صافي الرصيد: ${netBalance.toStringAsFixed(2)} ₪',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: balanceColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('الدخل', summary.totalIncome, Colors.green),
                _buildSummaryItem('المصروفات', summary.totalExpenses, Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('دين لي', summary.totalDebtToMe, Colors.blue),
                _buildSummaryItem('دين علي', summary.totalDebtFromMe, Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            _buildProgressIndicator(summary.totalIncome, summary.totalExpenses,summary.totalDebtToMe),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(2)} ₪',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(double income, double expenses, double totalDebtToMe) {
    final percentage = income > 0 ? ((expenses + totalDebtToMe) / income) * 100 : 0;
    final isOverBudget = expenses > income;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('نسبة الصرف'),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: isOverBudget ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: income > 0 ? ((expenses + totalDebtToMe) / income) : 0,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOverBudget ? Colors.red : 
            percentage > 80 ? Colors.orange : Colors.green,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isOverBudget ? 'تجاوزت الميزانية!' : 'ضمن الميزانية',
          style: TextStyle(
            fontSize: 12,
            color: isOverBudget ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesList() {
    if (_filteredExpenses.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _getEmptyMessage(),
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (_searchQuery.isNotEmpty || _selectedFilter != 'الكل')
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _selectedFilter = 'الكل';
                    });
                  },
                  child: const Text('مسح الفلترة'),
                ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<HomeBloc>().add(const RefreshHomeDataEvent());
        },
        child: ListView.builder(
          itemCount: _filteredExpenses.length,
          itemBuilder: (context, index) {
            final expense = _filteredExpenses[index];
            return _buildExpenseItem(context, expense);
          },
        ),
      ),
    );
  }

  String _getEmptyMessage() {
    if (_searchQuery.isNotEmpty) {
      return 'لا توجد معاملات تطابق البحث';
    } else if (_selectedFilter != 'الكل') {
      return 'لا توجد معاملات من هذا النوع';
    } else {
      return 'لا توجد معاملات حتى الآن';
    }
  }

  Widget _buildExpenseItem(BuildContext context, Expense expense) {
    final isIncome = expense.type == 'income';
    final isDebtToMe = expense.type == 'debt_to_me';
    final isDebtFromMe = expense.type == 'debt_from_me';

    Color itemColor;
    IconData itemIcon;
    String typeLabel;

    if (isIncome) {
      itemColor = Colors.green.shade600;
      itemIcon = Icons.arrow_downward;
      typeLabel = 'دخل';
    } else if (isDebtToMe) {
      itemColor = Colors.green.shade600;
      itemIcon = Icons.arrow_downward;
      typeLabel = 'دين لي';
    } else if (isDebtFromMe) {
      itemColor = Colors.red.shade600;
      itemIcon = Icons.arrow_upward;
      typeLabel = 'دين علي';
    } else {
      itemColor = Colors.orange.shade700;
      itemIcon = Icons.money_off;
      typeLabel = 'مصروف';
    }

    final titleText = expense.person != null && (isDebtToMe || isDebtFromMe)
        ? '${expense.title} (${expense.person})'
        : expense.title;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: itemColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(itemIcon, color: itemColor, size: 20),
        ),
        title: Text(
          titleText,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$typeLabel • ${expense.category}'),
            if (expense.notes != null && expense.notes!.isNotEmpty)
              Text(
                expense.notes!,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (expense.exchangeRate != null && expense.currency != '₪')
              Text(
                'سعر الصرف: ${expense.exchangeRate!.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${expense.amount.toStringAsFixed(2)} ${CurrencyService.getCurrencySymbol(expense.currency)}',
              style: TextStyle(
                color: itemColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (expense.currency != '₪' && expense.baseAmount != null)
              Text(
                '${expense.baseAmount!.toStringAsFixed(2)} ₪',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            Text(
              '${expense.date.day}/${expense.date.month}/${expense.date.year}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _showExpenseDetailDialog(context, expense),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('جاري تحميل البيانات...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<HomeBloc>().add(const GetHomeDataEvent()),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (ctx) => const AddExpenseDialog(),
    );
  }

  void _showExpenseDetailDialog(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (ctx) => ExpenseDetailDialog(expense: expense),
    );
  }
}