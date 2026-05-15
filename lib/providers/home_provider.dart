// lib/providers/home_provider.dart
import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';

class HomeProvider extends ChangeNotifier {
  final UserRepository _repository = UserRepository();
  
  bool isLoading = true;
  bool obatSudahDiminum = false;
  String namaObat = '';
  String jamObat = '';
  String userName = '';
  List<Map<String, dynamic>> jadwalObat = [];
  
  int? _userId;
  
  HomeProvider(this._userId);
  
  Future<void> loadData() async {
    if (_userId == null) return;
    
    isLoading = true;
    notifyListeners();
    
    try {
      final userData = await _repository.getUserData(_userId!);
      final dataDiri = userData['dataDiri'] as Map<String, String>? ?? {};
      
      userName = dataDiri['nama'] ?? '';
      jadwalObat = List<Map<String, dynamic>>.from(userData['jadwalObat'] ?? []);
      
      if (jadwalObat.isNotEmpty) {
        final firstObat = jadwalObat.first;
        namaObat = firstObat['namaObat'] ?? '';
        jamObat = firstObat['waktu'] ?? '';
      }
      
      final today = DateTime.now().toIso8601String().split('T').first;
      obatSudahDiminum = await _repository.getKepatuhanStatus(_userId!, today) == 1;
      
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> konfirmasiMinum() async {
    if (_userId == null) return;
    
    final today = DateTime.now().toIso8601String().split('T').first;
    final newStatus = obatSudahDiminum ? 0 : 1;
    
    await _repository.updateKepatuhan(_userId!, today, newStatus);
    obatSudahDiminum = !obatSudahDiminum;
    notifyListeners();
  }
}