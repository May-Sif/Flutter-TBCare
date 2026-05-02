import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';

class HomeScreen extends StatelessWidget {
  final String email;
  final String name;
  final String? photoUrl;

  const HomeScreen({
    super.key,
    required this.email,
    this.name = '',
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: 
          const Text(
            'Beranda',
            style: 
              TextStyle(
                fontWeight: FontWeight.w600
              )
          ),
      ),
      body: 
        const Center(
          child: 
            Text(
              'Halaman Home',
              style: 
                TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary
                ),
            ),
        ),
      );
  }
}