// lib/src/widgets/expense_detail_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/expense.dart';
import '../blocs/home/home_bloc.dart';

class ExpenseDetailDialog extends StatefulWidget {
  final Expense expense;

  const ExpenseDetailDialog({super.key, required this.expense});

  @override
  State<ExpenseDetailDialog> createState() => _ExpenseDetailDialogState();
}

class _ExpenseDetailDialogState extends State<ExpenseDetailDialog> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late TextEditingController _notesController;
  late TextEditingController _personController;
  late String _selectedType;
  late String _selectedCurrency;

  // ✅ استخدام نفس القوائم المستخدمة في AddExpenseDialog
  static const List<String> _typeValues = ['expense', 'income', 'debt_to_me', 'debt_from_me'];
  static const List<String> _typeLabels = ['مصروف', 'دخل', 'دين لي', 'دين علي'];
  static const List<String> _currencyValues = ['₪', '\$', '€', '£'];
  static const List<String> _currencyLabels = ['شيكل (₪)', 'دولار (\$)', 'يورو (€)', 'جنيه (£)'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController = TextEditingController(text: widget.expense.amount.toString());
    _categoryController = TextEditingController(text: widget.expense.category);
    _notesController = TextEditingController(text: widget.expense.notes ?? '');
    _personController = TextEditingController(text: widget.expense.person ?? '');
    _selectedType = widget.expense.type;
    
    // ✅ إصلاح: تحويل 'شيكل' إلى '₪' إذا لزم الأمر
    _selectedCurrency = widget.expense.currency == 'شيكل' ? '₪' : widget.expense.currency;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    _personController.dispose();
    super.dispose();
  }

  void _updateExpense(BuildContext context) {
    final newTitle = _titleController.text.trim();
    final newAmount = double.tryParse(_amountController.text) ?? 0.0;
    final newCategory = _categoryController.text.trim();
    final newNotes = _notesController.text.trim();
    final newPerson = _personController.text.trim();

    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال عنوان للمعاملة')),
      );
      return;
    }

    if (newAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح أكبر من الصفر')),
      );
      return;
    }

    // إذا كان النوع دين لي أو دين علي ويجب إدخال شخص
    if ((_selectedType == 'debt_to_me' || _selectedType == 'debt_from_me') && newPerson.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم الشخص للدين')),
      );
      return;
    }

    // إرسال حدث التعديل إلى الـ Bloc
    context.read<HomeBloc>().add(UpdateExpenseEvent(
      expenseId: widget.expense.id,
      title: newTitle,
      amount: newAmount,
      type: _selectedType,
      currency: _selectedCurrency,
      category: newCategory.isNotEmpty ? newCategory : 'عام',
      notes: newNotes.isNotEmpty ? newNotes : null,
      person: (_selectedType == 'debt_to_me' || _selectedType == 'debt_from_me') && newPerson.isNotEmpty 
          ? newPerson 
          : null,
    ));

    Navigator.pop(context);
  }

  void _deleteExpense(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المعاملة'),
        content: const Text('هل أنت متأكد من حذف هذه المعاملة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<HomeBloc>().add(DeleteExpenseEvent(expenseId: widget.expense.id));
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تفاصيل المعاملة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // حقل العنوان
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'العنوان *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            
            // حقل المبلغ والعملة
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    items: _currencyValues.asMap().entries.map((entry) {
                      final index = entry.key;
                      final value = entry.value;
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(_currencyLabels[index]),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'العملة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // حقل النوع
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _typeValues.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value;
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(_typeLabels[index]),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'نوع المعاملة *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            
            // حقل الفئة
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'الفئة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            
            // حقل الشخص (للدين)
            if (_selectedType == 'debt_to_me' || _selectedType == 'debt_from_me')
              TextField(
                controller: _personController,
                decoration: const InputDecoration(
                  labelText: 'اسم الشخص *',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_selectedType == 'debt_to_me' || _selectedType == 'debt_from_me')
              const SizedBox(height: 15),
            
            // حقل الملاحظات
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            
            // أزرار الحفظ والحذف
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateExpense(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('تحديث', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _deleteExpense(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('حذف', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}