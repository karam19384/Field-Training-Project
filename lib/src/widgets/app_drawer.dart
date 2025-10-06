// lib/src/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_budget/src/blocs/auth/auth_bloc.dart';
import 'package:my_budget/src/blocs/home/home_bloc.dart';
import 'package:my_budget/src/screens/profile_screen.dart';
import 'package:my_budget/src/screens/categories_screen.dart';
import 'package:my_budget/src/screens/contacts_screen.dart';
import 'package:my_budget/src/screens/income_screen.dart';
import 'package:my_budget/src/screens/statistics_screen.dart';
import 'package:my_budget/src/screens/export_data_screen.dart';
import 'package:my_budget/src/screens/custom_page_screen.dart';

import '../blocs/auth/auth_event.dart';
import '../models/expense.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends StatefulWidget {
  final User? user;

  const AppDrawer({super.key, required this.user});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    if (widget.user?.uid != null) {
      final doc = await _firestore.collection('users').doc(widget.user!.uid).get();
      if (doc.exists) {
        setState(() {
          _userName = doc.data()?['name'] ?? widget.user?.displayName;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // رأس الدراور - معلومات المستخدم
          _buildHeader(context),
          
          // القائمة الرئيسية
          Expanded(
            child: _buildMainList(),
          ),

          // قسم تسجيل الخروج
          _buildLogoutSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.blueAccent.shade700, Colors.blueAccent.shade400],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المستخدم
            GestureDetector(
              onTap: () => _navigateTo(context, const ProfileScreen()),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: widget.user?.photoURL != null
                    ? NetworkImage(widget.user!.photoURL!)
                    : null,
                child: widget.user?.photoURL == null
                    ? Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.blueAccent.shade700,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 15),

            // اسم المستخدم
            Text(
              _userName ?? widget.user?.displayName ?? 'مستخدم جديد',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),

            // البريد الإلكتروني
            Text(
              widget.user?.email ?? 'لا يوجد بريد إلكتروني',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),

            // زر تعديل الملف الشخصي
            OutlinedButton(
              onPressed: () => _navigateTo(context, const ProfileScreen()),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 5),
                  Text('تعديل الملف'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainList() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        // استخراج الفئات والأشلام من البيانات
        List<String> categories = [];
        List<String> persons = [];

        if (state is HomeLoaded) {
          categories = _extractCategories(state.expenses);
          persons = _extractPersons(state.expenses);
        }

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // قسم الإدارة
            _buildSectionHeader('الإدارة'),
            _buildListTile(
              context,
              icon: Icons.dashboard,
              title: 'لوحة التحكم',
              onTap: () => Navigator.pop(context),
            ),
            _buildListTile(
              context,
              icon: Icons.category,
              title: 'إدارة الفئات',
              onTap: () => _navigateTo(context, const CategoriesScreen()),
            ),
            _buildListTile(
              context,
              icon: Icons.contacts,
              title: 'إدارة الأشخاص',
              onTap: () => _navigateTo(context, const ContactsScreen()),
            ),
            _buildListTile(
              context,
              icon: Icons.attach_money,
              title: 'الإيرادات',
              onTap: () => _navigateTo(context, const IncomeScreen()),
            ),

            // الصفحات المخصصة - الفئات
            if (categories.isNotEmpty) ...[
              _buildSectionHeader('صفحات الفئات'),
              ...categories.map((category) => _buildCustomPageItem(
                context,
                name: category,
                type: 'category',
                icon: Icons.category,
                color: Colors.blueAccent,
              )),
            ],

            // الصفحات المخصصة - الأشخاص
            if (persons.isNotEmpty) ...[
              _buildSectionHeader('صفحات الأشخاص'),
              ...persons.map((person) => _buildCustomPageItem(
                context,
                name: person,
                type: 'person',
                icon: Icons.person,
                color: Colors.greenAccent,
              )),
            ],

            // قسم التقارير والإحصائيات
            _buildSectionHeader('التقارير والإحصائيات'),
            _buildListTile(
              context,
              icon: Icons.bar_chart,
              title: 'الإحصائيات',
              onTap: () => _navigateTo(context, const StatisticsScreen()),
            ),
            _buildListTile(
              context,
              icon: Icons.import_export,
              title: 'تصدير البيانات',
              onTap: () => _navigateTo(context, const ExportDataScreen()),
            ),

            // قسم الإعدادات
            _buildSectionHeader('الإعدادات'),
            _buildListTile(
              context,
              icon: Icons.settings,
              title: 'الإعدادات',
              onTap: () => _navigateTo(context, const SettingsScreen()),
            ),
            _buildListTile(
              context,
              icon: Icons.help_outline,
              title: 'المساعدة والدعم',
              onTap: () => _showHelpDialog(context),
            ),
            _buildListTile(
              context,
              icon: Icons.info_outline,
              title: 'عن التطبيق',
              onTap: () => _showAboutDialog(context),
            ),
          ],
        );
      },
    );
  }

  List<String> _extractCategories(List<Expense> expenses) {
    final categories = <String>{};
    for (final expense in expenses) {
      if (expense.category.isNotEmpty && expense.category != 'عام') {
        categories.add(expense.category);
      }
    }
    return categories.toList()..sort();
  }

  List<String> _extractPersons(List<Expense> expenses) {
    final persons = <String>{};
    for (final expense in expenses) {
      if (expense.person != null && expense.person!.isNotEmpty) {
        persons.add(expense.person!);
      }
    }
    return persons.toList()..sort();
  }

  Widget _buildCustomPageItem(
    BuildContext context, {
    required String name,
    required String type,
    required IconData icon,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        name,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: const Icon(Icons.arrow_left, size: 16, color: Colors.grey),
      dense: true,
      onTap: () => _navigateToCustomPage(context, name, type),
    );
  }

  // باقي الدوال تبقى كما هي مع التعديلات البسيطة...
  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.blueAccent,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_left,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Text(
            'إصدار التطبيق 1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 10),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutConfirmation(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text(
                'تسجيل الخروج',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _navigateToCustomPage(BuildContext context, String name, String type) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomPageScreen(
          pageType: type,
          pageName: name,
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text('تسجيل الخروج'),
            ],
          ),
          content: const Text('هل أنت متأكد من أنك تريد تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                context.read<AuthBloc>().add(SignOutEvent());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue),
              SizedBox(width: 10),
              Text('المساعدة والدعم'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'كيف يمكننا مساعدتك؟',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('• إضافة معاملة: استخدم الزر + في الشاشة الرئيسية'),
                Text('• تعديل معاملة: اضغط على أي معاملة في القائمة'),
                Text('• البحث: استخدم شريط البحث في الأعلى'),
                Text('• الصفحات المخصصة: تظهر تلقائياً عند إضافة معاملات'),
                SizedBox(height: 10),
                Text(
                  'للتواصل مع الدعم الفني:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('support@mybudget.com'),
                Text('+972 123 456 789'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.green),
              SizedBox(width: 10),
              Text('عن التطبيق'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Budget',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 10),
                Text('إصدار 1.0.0'),
                Text('أخر تحديث: أكتوبر 2024'),
                SizedBox(height: 10),
                Text(
                  'تطبيق إدارة المصاريف الشخصية يساعدك على:',
                ),
                Text('• تتبع مصاريفك وإيراداتك'),
                Text('• إدارة الديون والمعاملات'),
                Text('• تحليل عادات الإنفاق'),
                Text('• التخطيط المالي'),
                SizedBox(height: 10),
                Text(
                  'تم التطوير باستخدام Flutter & Firebase',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }
}