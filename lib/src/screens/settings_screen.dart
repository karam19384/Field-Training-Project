import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget/src/blocs/auth/auth_bloc.dart';
import 'package:my_budget/src/blocs/auth/auth_event.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'العربية';
  String _selectedCurrency = 'شيكل إسرائيلي (₪)';
  bool _darkMode = false;

  final List<String> _languages = ['العربية', 'English'];
  final List<String> _currencies = ['شيكل إسرائيلي (₪)', 'دولار أمريكي (\$)', 'يورو (€)'];

  void _changeLanguage(String? newLanguage) {
    if (newLanguage != null) {
      setState(() {
        _selectedLanguage = newLanguage;
      });
      // TODO: Implement actual language change logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تغيير اللغة إلى $newLanguage')),
      );
    }
  }

  void _changeCurrency(String? newCurrency) {
    if (newCurrency != null) {
      setState(() {
        _selectedCurrency = newCurrency;
      });
      // TODO: Implement actual currency change logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تغيير العملة إلى $newCurrency')),
      );
    }
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _darkMode = value;
    });
    // TODO: Implement actual dark mode logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم ${value ? 'تفعيل' : 'إلغاء'} الوضع الليلي')),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف جميع البيانات'),
        content: const Text('هل أنت متأكد من حذف جميع البيانات؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
  }

  void _deleteAllData() {
    // TODO: Implement actual data deletion logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف جميع البيانات')),
    );
  }

  void _showBackupOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('رفع نسخة احتياطية'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement backup upload
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري رفع النسخة الاحتياطية...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text('تحميل نسخة احتياطية'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement backup download
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري تحميل النسخة الاحتياطية...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('عام'),
          _buildSettingItem(
            icon: Icons.language,
            title: 'اللغة',
            subtitle: _selectedLanguage,
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              items: _languages.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: _changeLanguage,
              underline: const SizedBox(),
            ),
          ),
          _buildSettingItem(
            icon: Icons.currency_exchange,
            title: 'العملة الافتراضية',
            subtitle: _selectedCurrency,
            trailing: DropdownButton<String>(
              value: _selectedCurrency,
              items: _currencies.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: _changeCurrency,
              underline: const SizedBox(),
            ),
          ),
          _buildSectionHeader('المظهر'),
          _buildSettingItem(
            icon: Icons.dark_mode,
            title: 'الوضع الليلي',
            subtitle: _darkMode ? 'مفعل' : 'معطل',
            trailing: Switch(
              value: _darkMode,
              onChanged: _toggleDarkMode,
            ),
          ),
          _buildSectionHeader('البيانات'),
          _buildSettingItem(
            icon: Icons.backup,
            title: 'نسخ احتياطي',
            subtitle: 'آخر نسخ: ${DateTime.now().toString().split(' ')[0]}',
            onTap: _showBackupOptions,
          ),
          _buildSettingItem(
            icon: Icons.restore,
            title: 'استعادة البيانات',
            onTap: () {
              // TODO: Implement restore logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جاري استعادة البيانات...')),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.delete_outline,
            title: 'حذف جميع البيانات',
            titleColor: Colors.red,
            onTap: _showDeleteConfirmation,
          ),
          _buildSectionHeader('الحساب'),
          _buildSettingItem(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            titleColor: Colors.orange,
            onTap: () {
              context.read<AuthBloc>().add(SignOutEvent());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color titleColor = Colors.black,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}