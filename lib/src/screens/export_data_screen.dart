// lib/src/screens/export_data_screen.dart

import 'package:flutter/material.dart';

class ExportDataScreen extends StatelessWidget {
  const ExportDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تصدير البيانات'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.import_export, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('شاشة تصدير البيانات قيد التطوير'),
          ],
        ),
      ),
    );
  }
}