// lib/src/screens/contacts_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/custom_page_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  StreamSubscription? _sub;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _loadContacts() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    _sub?.cancel();
    _sub = _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .orderBy('name')
        .snapshots()
        .listen(
      (snapshot) {
        final data = snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data()
            }).toList();
        if (mounted) {
          setState(() {
            _contacts = List<Map<String, dynamic>>.from(data);
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $error')),
        );
      },
    );
  }

  Future<void> _addContact(String name) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم الشخص')),
      );
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _nameController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إضافة "$name" بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الإضافة: $e')),
      );
    }
  }

  Future<void> _deleteContact(String contactId, String contactName) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف "$contactName" بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحذف: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأشخاص'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // حقل إضافة شخص جديد
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم الشخص',
                            border: OutlineInputBorder(),
                            hintText: 'أدخل اسم الشخص',
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _addContact(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          final name = _nameController.text.trim();
                          _addContact(name);
                        },
                        child: const Text('إضافة'),
                      ),
                    ],
                  ),
                ),
                
                // قائمة الأشخاص
                Expanded(
                  child: _contacts.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('لا توجد أشخاص مضافة بعد'),
                              SizedBox(height: 8),
                              Text(
                                'قم بإضافة أشخاص لتتبع المعاملات معهم',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _contacts.length,
                          itemBuilder: (context, index) {
                            final contact = _contacts[index];
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
                                  child: const Icon(Icons.person, color: Colors.green),
                                ),
                                title: Text(contact['name']),
                                subtitle: const Text('انقر للذهاب لصفحة الشخص'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showDeleteDialog(contact['id'], contact['name']),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CustomPageScreen(
                                        pageType: 'person',
                                        pageName: contact['name'],
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

  void _showDeleteDialog(String contactId, String contactName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الشخص'),
        content: Text('هل أنت متأكد من حذف "$contactName"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteContact(contactId, contactName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}