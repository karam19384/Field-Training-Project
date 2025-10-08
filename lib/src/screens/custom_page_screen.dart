import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/expense.dart';
import '../blocs/home/home_bloc.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/expense_detail_dialog.dart';
import '../services/currency_service.dart';

class CustomPageScreen extends StatefulWidget {
  final String pageType; // 'category' أو 'person'
  final String pageName;

  const CustomPageScreen({
    super.key,
    required this.pageType,
    required this.pageName,
  });

  @override
  State<CustomPageScreen> createState() => _CustomPageScreenState();
}

class _CustomPageScreenState extends State<CustomPageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Expense> _pageExpenses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final homeBloc = BlocProvider.of<HomeBloc>(context);

    if (homeBloc.state is HomeLoaded) {
      // إذا كانت البيانات محملة مسبقاً، استخدمها مباشرة
      _processExpenses((homeBloc.state as HomeLoaded).expenses);
    } else if (homeBloc.state is HomeInitial) {
      // إذا لم تكن البيانات محملة، اطلب تحميلها
      homeBloc.add(const GetHomeDataEvent());
    } else if (homeBloc.state is HomeError) {
      // إذا كان هناك خطأ
      setState(() {
        _isLoading = false;
        _errorMessage = (homeBloc.state as HomeError).message;
      });
    }
  }

  void _processExpenses(List<Expense> allExpenses) {
    if (!mounted) return;

    setState(() {
      _pageExpenses = allExpenses.where((expense) {
        if (widget.pageType == 'category') {
          return expense.category == widget.pageName;
        } else {
          return expense.person == widget.pageName;
        }
      }).toList();
      _isLoading = false;
      _errorMessage = null;
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<Expense> _getFilteredExpenses() {
    if (_searchQuery.isEmpty) return _pageExpenses;

    return _pageExpenses.where((expense) {
      return expense.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (expense.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (expense.person?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
    }).toList();
  }

  Map<String, double> _calculateStats(List<Expense> expenses) {
    double income = 0;
    double expense = 0;
    double debtToMe = 0;
    double debtFromMe = 0;

    for (final exp in expenses) {
      final amount = exp.getAmountInBaseCurrency();
      switch (exp.type) {
        case 'income':
          income += amount;
          break;
        case 'expense':
          expense += amount;
          break;
        case 'debt_to_me':
          debtToMe += amount;
          break;
        case 'debt_from_me':
          debtFromMe += amount;
          break;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'debtToMe': debtToMe,
      'debtFromMe': debtFromMe,
      'net': (income + debtToMe) - (expense + debtFromMe),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageName),
        backgroundColor: _getPageColor(),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExpenseForm(context),
          ),
        ],
      ),
      body: BlocListener<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeLoaded) {
            _processExpenses(state.expenses);
          } else if (state is HomeError) {
            setState(() {
              _isLoading = false;
              _errorMessage = state.message;
            });
          } else if (state is HomeLoading) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseForm(context),
        backgroundColor: _getPageColor(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    final filteredExpenses = _getFilteredExpenses();
    final stats = _calculateStats(_pageExpenses);
    final filteredStats = _calculateStats(filteredExpenses);

    return Column(
      children: [
        _buildSearchBar(),
        _buildPageSummary(stats, filteredStats, filteredExpenses.length),
        Expanded(child: _buildExpensesList(filteredExpenses)),
      ],
    );
  }

  Color _getPageColor() {
    final colors = [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.tealAccent,
    ];
    final index = widget.pageName.hashCode % colors.length;
    return colors[index];
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث في ${widget.pageName}...',
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
    );
  }

  Widget _buildPageSummary(
    Map<String, double> stats,
    Map<String, double> filteredStats,
    int filteredCount,
  ) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              widget.pageName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getPageColor(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('المجموع', stats['net']!),
                _buildStatItem('المعاملات', _pageExpenses.length.toDouble()),
                if (_searchQuery.isNotEmpty)
                  _buildStatItem('النتائج', filteredCount.toDouble()),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (stats['income']! > 0)
                  _buildDetailChip('دخل', stats['income']!, Colors.green),
                if (stats['expense']! > 0)
                  _buildDetailChip('مصروف', stats['expense']!, Colors.red),
                if (stats['debtToMe']! > 0)
                  _buildDetailChip('دين لي', stats['debtToMe']!, Colors.green),
                if (stats['debtFromMe']! > 0)
                  _buildDetailChip('دين علي', stats['debtFromMe']!, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          label == 'المعاملات' || label == 'النتائج'
              ? value.toInt().toString()
              : '${value.toStringAsFixed(2)} ₪',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailChip(String label, double value, Color color) {
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Text(
        '$label: ${value.toStringAsFixed(2)} ₪',
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Widget _buildExpensesList(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'لا توجد معاملات في ${widget.pageName}'
                  : 'لا توجد نتائج للبحث',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                },
                child: const Text('مسح البحث'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isLoading = true;
        });
        context.read<HomeBloc>().add(const RefreshHomeDataEvent());
      },
      child: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return _buildExpenseItem(context, expense);
        },
      ),
    );
  }

  Widget _buildExpenseItem(BuildContext context, Expense expense) {
    final isIncome = expense.type == 'income';
    final isDebtToMe = expense.type == 'debt_to_me';
    final isDebtFromMe = expense.type == 'debt_from_me';

    Color itemColor;
    IconData itemIcon;

    if (isIncome || isDebtToMe) {
      itemColor = Colors.green.shade600;
      itemIcon = Icons.arrow_downward;
    } else if (isDebtFromMe) {
      itemColor = Colors.red.shade600;
      itemIcon = Icons.arrow_upward;
    } else {
      itemColor = Colors.orange.shade700;
      itemIcon = Icons.money_off;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getTypeLabel(expense.type)} • ${_formatDate(expense.date)}',
              softWrap: true,
            ),
            if (expense.notes != null && expense.notes!.isNotEmpty)
              Text(
                expense.notes!,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (widget.pageType == 'person' && expense.category != 'عام')
              Text(
                'الفئة: ${expense.category}',
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
              style: TextStyle(color: itemColor, fontWeight: FontWeight.bold),
            ),
            if (expense.currency != '₪' && expense.baseAmount != null)
              Text(
                '${expense.baseAmount!.toStringAsFixed(2)} ₪',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            Text(
              '${expense.date.day}/${expense.date.month}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _showExpenseDetailDialog(context, expense),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'income':
        return 'دخل';
      case 'debt_to_me':
        return 'دين لي';
      case 'debt_from_me':
        return 'دين علي';
      default:
        return 'مصروف';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              context.read<HomeBloc>().add(const GetHomeDataEvent());
            },
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
      builder: (ctx) => AddExpenseDialog(
        preSelectedCategory: widget.pageType == 'category'
            ? widget.pageName
            : null,
        preSelectedPerson: widget.pageType == 'person' ? widget.pageName : null,
      ),
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
