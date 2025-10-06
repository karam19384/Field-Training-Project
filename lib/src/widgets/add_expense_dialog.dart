// lib/src/widgets/add_expense_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/home/home_bloc.dart';
import '../services/currency_service.dart';

class AddExpenseDialog extends StatefulWidget {
  final String? preSelectedType;
  final String? preSelectedCategory;
  final String? preSelectedPerson;

  const AddExpenseDialog({
    super.key, 
    this.preSelectedType,
    this.preSelectedCategory,
    this.preSelectedPerson,
  });

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _personController = TextEditingController();

  // ✅ إصلاح: استخدام قائمة ثابتة بدون تكرار
  static const List<String> _typeValues = ['expense', 'income', 'debt_to_me', 'debt_from_me'];
  static const List<String> _typeLabels = ['مصروف', 'دخل', 'دين لي', 'دين علي'];

  // ✅ إصلاح: قائمة العملات ثابتة
  static const List<String> _currencyValues = ['₪', '\$', '€', '£'];
  static const List<String> _currencyLabels = ['شيكل (₪)', 'دولار (\$)', 'يورو (€)', 'جنيه (£)'];

  late String _selectedType;
  late String _selectedCurrency;
  double? _exchangeRate;
  double? _convertedAmount;
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    
    // ✅ إصلاح: تعيين قيم ابتدائية صحيحة
    _selectedType = widget.preSelectedType ?? 'expense';
    _selectedCurrency = '₪'; // العملة الافتراضية
    
    // تعيين القيم المسبقة إذا وجدت
    _categoryController.text = widget.preSelectedCategory ?? 'عام';
    _personController.text = widget.preSelectedPerson ?? '';
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

  Future<void> _convertCurrency() async {
    if (_selectedCurrency == '₪') {
      setState(() {
        _exchangeRate = null;
        _convertedAmount = null;
      });
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isConverting = true);

    try {
      final rate = await CurrencyService.getExchangeRate(_selectedCurrency, '₪');
      if (rate != null) {
        setState(() {
          _exchangeRate = rate;
          _convertedAmount = amount * rate;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحويل العملة: $e')),
      );
    } finally {
      setState(() => _isConverting = false);
    }
  }

  void _addExpense(BuildContext context) {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final category = _categoryController.text.trim();
    final notes = _notesController.text.trim();
    final person = _personController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال عنوان للمعاملة')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح أكبر من الصفر')),
      );
      return;
    }

    // إذا كان النوع دين لي أو دين علي ويجب إدخال شخص
    if ((_selectedType == 'debt_to_me' || _selectedType == 'debt_from_me') && person.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم الشخص للدين')),
      );
      return;
    }

    // إرسال حدث إضافة المعاملة
    context.read<HomeBloc>().add(AddNewExpenseEvent(
      title: title,
      amount: amount,
      type: _selectedType,
      currency: _selectedCurrency,
      category: category.isNotEmpty ? category : 'عام',
      notes: notes.isNotEmpty ? notes : null,
      person: (_selectedType == 'debt_to_me' || _selectedType == 'debt_from_me') && person.isNotEmpty 
          ? person 
          : null,
    ));

    Navigator.pop(context);
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إضافة معاملة جديدة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // حقل العنوان
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'العنوان *',
                border: OutlineInputBorder(),
                hintText: 'أدخل عنوان المعاملة',
              ),
            ),
            const SizedBox(height: 15),
            
            // صف المبلغ والعملة
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
                      hintText: '0.00',
                    ),
                    onChanged: (value) {
                      if (_selectedCurrency != '₪') {
                        _convertCurrency();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    // ✅ إصلاح: قيمة موجودة في القائمة
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
                      _convertCurrency();
                    },
                    decoration: const InputDecoration(
                      labelText: 'العملة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            
            // عرض سعر الصرف والمبلغ المحول
            if (_isConverting)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_exchangeRate != null && _convertedAmount != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'سعر الصرف: ${_exchangeRate!.toStringAsFixed(4)} | المبلغ بالشيكل: ${_convertedAmount!.toStringAsFixed(2)} ₪',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ),
            const SizedBox(height: 15),
            
            // حقل نوع المعاملة
            DropdownButtonFormField<String>(
              // ✅ إصلاح: قيمة موجودة في القائمة
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
                hintText: 'عام',
              ),
            ),
            const SizedBox(height: 15),
            
            // حقل الشخص (يظهر فقط للدين)
            if (_selectedType == 'debt_to_me' || _selectedType == 'debt_from_me')
              TextField(
                controller: _personController,
                decoration: const InputDecoration(
                  labelText: 'اسم الشخص *',
                  border: OutlineInputBorder(),
                  hintText: 'أدخل اسم الشخص',
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
                hintText: 'أدخل أي ملاحظات إضافية',
              ),
            ),
            const SizedBox(height: 25),
            
            // أزرار الإضافة والإلغاء
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
                    onPressed: () => _addExpense(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'إضافة',
                      style: TextStyle(color: Colors.white),
                    ),
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