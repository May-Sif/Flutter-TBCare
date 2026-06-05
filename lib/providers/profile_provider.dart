// lib/providers/profile_provider.dart
import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';
import '../pages/authentication/authentication.dart';

class ProfileProvider extends ChangeNotifier {
  final UserRepository _repository = UserRepository();
  
  bool isLoading = true;
  Map<String, String> dataDiri = {};
  List<Map<String, dynamic>> jadwalObat = [];
  
  int? _userId;
  
  ProfileProvider(this._userId);
  
  Future<void> loadData() async {
    if (_userId == null) return;
    
    isLoading = true;
    notifyListeners();
    
    try {
      final userData = await _repository.getUserData(_userId!);
      dataDiri = Map<String, String>.from(userData['dataDiri'] as Map<String, dynamic>? ?? {});
      jadwalObat = List<Map<String, dynamic>>.from(userData['jadwalObat'] ?? []);
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> saveData(Map<String, String> newDataDiri, List<Map<String, dynamic>> newJadwalObat) async {
    await _repository.saveUserData(newDataDiri, newJadwalObat);
    dataDiri = newDataDiri;
    jadwalObat = newJadwalObat;
    notifyListeners();
  }
  
  Future<void> logout(BuildContext context) async {
    await _repository.logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }
}