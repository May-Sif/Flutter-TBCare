// lib/main.dart

import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';
import 'pages/isi_datadiri.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TBCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const IsiDataDiriPage(),
    );
  }
}