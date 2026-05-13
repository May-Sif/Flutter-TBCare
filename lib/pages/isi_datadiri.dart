import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';
import 'isi_dataobat.dart';

class IsiDataDiriPage extends StatelessWidget {
  final String email;
  final String name;
  final String? photoUrl;

  const IsiDataDiriPage({
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
            'Isi Data Diri',
            style: TextStyle(
              fontWeight: FontWeight.w600
            )
          ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Halaman Isi Data Diri',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary
              ),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: 
                const TextStyle(
                  fontSize: 14, 
                  color: AppColors.textSecondary
                ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IsiDataObatPage(
                          email: email,
                          name: name,
                          photoUrl: photoUrl,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: 
                    const Text(
                      'Selesai',
                      style: 
                        TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600
                        )
                    ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}