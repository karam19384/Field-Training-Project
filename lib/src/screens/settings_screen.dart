import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget/src/blocs/auth/auth_bloc.dart';
import 'package:my_budget/src/blocs/settings/settings_cubit.dart';
import 'package:my_budget/src/blocs/auth/auth_event.dart';
import 'package:my_budget/src/services/storage_service.dart';
import 'package:my_budget/src/services/firestore_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final FirestoreService _fsService = FirestoreService();

  final List<String> _languages = ['العربية', 'English'];
  final List<String> _currencies = [
    'شيكل إسرائيلي (₪)',
    'دولار أمريكي (\$)',
    'يورو (€)',
  ];

  void _changeLanguage(String? newLanguage) {
    if (newLanguage == null) return;
    final cubit = context.read<SettingsCubit>();
    if (newLanguage.toLowerCase().startsWith('en')) {
      cubit.setLocale(const Locale('en'));
    } else {
      cubit.setLocale(const Locale('ar'));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تغيير اللغة / Language changed: $newLanguage'),
      ),
    );
  }

  void _changeCurrency(String? newCurrency) {
    if (newCurrency == null) return;
    context.read<SettingsCubit>().setCurrency(newCurrency);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('تم تغيير العملة إلى $newCurrency')));
  }

  void _toggleDarkMode(bool value) {
    context.read<SettingsCubit>().setDarkMode(value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم ${value ? 'تفعيل' : 'إلغاء'} الوضع الليلي')),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف جميع البيانات'),
        content: const Text(
          'هل أنت متأكد من حذف جميع البيانات؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
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

  void _deleteAllData() async {
    try {
      await _fsService.deleteAllUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف جميع البيانات')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
    }
  }

  Future<void> _handleBackupUpload() async {
    try {
      await _storageService.uploadBackupJson(
        await _storageService.buildBackupJson(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إنشاء نسخة احتياطية')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل النسخ الاحتياطي: $e')));
    }
  }

  Future<void> _handleBackupDownload() async {
    try {
      await _storageService.downloadBackupJson();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تنزيل النسخة بنجاح')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل التنزيل: $e')));
    }
  }

  Future<void> _handleRestore() async {
    try {
      final backup = await _storageService.downloadBackupJson();
      await _fsService.deleteAllUserData();
      await _storageService.restoreFromBackup(backup);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تمت الاستعادة بنجاح')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشلت الاستعادة: $e')));
    }
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
                _handleBackupUpload();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text('تحميل نسخة احتياطية'),
              onTap: () {
                Navigator.pop(context);
                _handleBackupDownload();
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
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          _buildSectionHeader('عام'),
          _buildSettingItem(
            icon: Icons.language,
            title: 'اللغة',
            subtitle:
                context.watch<SettingsCubit>().state.locale.languageCode == 'ar'
                ? 'العربية'
                : 'English',
            trailing: DropdownButton<String>(
              value:
                  context.watch<SettingsCubit>().state.locale.languageCode ==
                      'ar'
                  ? 'العربية'
                  : 'English',
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
            subtitle: context.watch<SettingsCubit>().state.currency,
            trailing: DropdownButton<String>(
              value: context.watch<SettingsCubit>().state.currency,
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
            subtitle:
                context.watch<SettingsCubit>().state.themeMode == ThemeMode.dark
                ? 'مفعل'
                : 'معطل',
            trailing: Switch(
              value:
                  context.watch<SettingsCubit>().state.themeMode ==
                  ThemeMode.dark,
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
            onTap: _handleRestore,
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
