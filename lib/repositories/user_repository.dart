// lib/repositories/user_repository.dart
import '../database/database_helper.dart';

class UserRepository {
  final DatabaseHelper _db = DatabaseHelper();

  // Ambil data lengkap user
  Future<Map<String, dynamic>> getUserData(int userId) async {
    return await _db.getCompleteUserData(userId);
  }

  // Simpan data diri dan obat
  Future<int> saveUserData(Map<String, dynamic> dataDiri, List<Map<String, dynamic>> jadwalObat, {String? email}) async {
    return await _db.saveCompleteUserData(dataDiri, jadwalObat, email: email);
  }

  // Update kepatuhan minum obat
  Future<void> updateKepatuhan(int userId, String tanggal, int status) async {
    await _db.updateKepatuhan(userId, tanggal, status);
  }

  // Ambil status kepatuhan hari ini
  Future<int> getKepatuhanStatus(int userId, String tanggal) async {
    return await _db.getKepatuhanStatus(userId, tanggal);
  }

  // Ambil jadwal obat user
  Future<List<Map<String, dynamic>>> getJadwalObat(int userId) async {
    final jadwalId = await _db.getJadwalIdByUserId(userId);
    if (jadwalId == null) return [];
    return await _db.getSesiByJadwalId(jadwalId);
  }

  // Logout
  Future<void> logout() async {
    await _db.logout();
  }
}