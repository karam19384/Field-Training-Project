// lib/src/screens/categories_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/custom_page_screen.dart';
import 'dart:async';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  StreamSubscription? _sub;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _loadCategories() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    _sub?.cancel();
    _sub = _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .listen((snapshot) {
          final data = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          if (mounted) {
            setState(() {
              _categories = List<Map<String, dynamic>>.from(data);
            });
          }
        });
  }

  Future<void> _addCategory(String name) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء إدخال اسم الفئة')));
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .add({'name': name, 'createdAt': FieldValue.serverTimestamp()});

      _nameController.clear();
      _loadCategories();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم إضافة الفئة "$name" بنجاح')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في إضافة الفئة: $e')));
    }
  }

  Future<void> _deleteCategory(String categoryId, String categoryName) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(categoryId)
          .delete();

      _loadCategories();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف الفئة "$categoryName" بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في حذف الفئة: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الفئات')),
      body: Column(
        children: [
          // حقل إضافة فئة جديدة
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الفئة',
                      border: OutlineInputBorder(),
                      hintText: 'أدخل اسم الفئة',
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _addCategory(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    _addCategory(name);
                  },
                  child: const Text('إضافة'),
                ),
              ],
            ),
          ),

          // قائمة الفئات
          Expanded(
            child: _categories.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('لا توجد فئات مضافة بعد'),
                        SizedBox(height: 8),
                        Text(
                          'قم بإضافة فئات جديدة لتنظيم معاملاتك',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.category,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(category['name']),
                          subtitle: const Text('انقر للذهاب لصفحة الفئة'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteDialog(
                              category['id'],
                              category['name'],
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomPageScreen(
                                  pageType: 'category',
                                  pageName: category['name'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String categoryId, String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الفئة'),
        content: Text('هل أنت متأكد من حذف "$categoryName"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(categoryId, categoryName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
