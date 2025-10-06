import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  List<Map<String, dynamic>> _incomeSources = [];

  @override
  void initState() {
    super.initState();
    _loadIncomeSources();
  }

  void _loadIncomeSources() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('income_sources')
        .orderBy('name')
        .get();

    setState(() {
      _incomeSources = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] as String,
          'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
          'currency': data['currency'] as String? ?? '₪',
          'description': data['description'] as String?,
        };
      }).toList();
    });
  }

  Future<void> _addIncomeSource() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final name = _sourceController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم مصدر الدخل')),
      );
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('income_sources')
          .add({
        'name': name,
        'amount': amount,
        'currency': '₪',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _sourceController.clear();
      _amountController.clear();
      _loadIncomeSources();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة مصدر الدخل بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الإضافة: $e')),
      );
    }
  }

  Future<void> _editIncomeSource(Map<String, dynamic> incomeSource) async {
    final newName = await _showEditDialog(
      initialName: incomeSource['name'],
      initialAmount: incomeSource['amount'].toString(),
    );

    if (newName != null && newName.isNotEmpty) {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('income_sources')
            .doc(incomeSource['id'])
            .update({
          'name': newName,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _loadIncomeSources();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل مصدر الدخل بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التعديل: $e')),
        );
      }
    }
  }

  Future<void> _deleteIncomeSource(String incomeSourceId, String name) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('income_sources')
          .doc(incomeSourceId)
          .delete();

      _loadIncomeSources();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف "$name" بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحذف: $e')),
      );
    }
  }

  Future<String?> _showEditDialog({String initialName = '', String initialAmount = ''}) async {
    final nameController = TextEditingController(text: initialName);
    final amountController = TextEditingController(text: initialAmount);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل مصدر الدخل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم مصدر الدخل'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'المبلغ الشهري'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showAddIncomeSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مصدر دخل جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'اسم مصدر الدخل',
                hintText: 'مثال: راتب، تجارة، إيجار...',
              ),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'المبلغ الشهري',
                hintText: '0.00',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addIncomeSource();
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مصادر الدخل'),
      ),
      body: Column(
        children: [
          // Summary Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'إجمالي الدخل الشهري',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_calculateTotalIncome().toStringAsFixed(2)} ₪',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Income Sources List
          Expanded(
            child: _incomeSources.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.attach_money, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('لا توجد مصادر دخل مضافة بعد'),
                        SizedBox(height: 8),
                        Text(
                          'قم بإضافة مصادر الدخل لمتابعة دخلك الشهري',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _incomeSources.length,
                    itemBuilder: (context, index) {
                      final source = _incomeSources[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.attach_money, color: Colors.green),
                          ),
                          title: Text(source['name']),
                          subtitle: Text('${source['amount'].toStringAsFixed(2)} ${source['currency']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editIncomeSource(source),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteDialog(source['id'], source['name']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddIncomeSourceDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  double _calculateTotalIncome() {
    return _incomeSources.fold(0.0, (sum, source) => sum + (source['amount'] as double));
  }

  void _showDeleteDialog(String incomeSourceId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف مصدر الدخل'),
        content: Text('هل أنت متأكد من حذف "$name"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteIncomeSource(incomeSourceId, name);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}