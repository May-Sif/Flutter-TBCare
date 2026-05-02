import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../models/user.dart';
import '../models/jadwal_obat.dart';
import '../models/riwayat_kepatuhan.dart';
import '../models/sesi.dart';
import '../models/sesi_riwayat.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void> init() async {
    await _googleSignIn.initialize();
  }

  String _hash(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  // REGISTER dengan SQLite
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    final key = email.toLowerCase().trim();
    
    // Cek apakah email sudah terdaftar di database
    final existingUser = await DatabaseHelper().getUserByEmail(key);
    if (existingUser != null) {
      return {
        'success': false,
        'message': 'Email sudah terdaftar',
      };
    }
    
    // Simpan user ke database (belum lengkap, nanti diisi di IsiDataDiri)
    final user = User(
      email: key,
      password: _hash(password),
      nama: '',
      umur: 0,
      tanggalDiagnosis: DateTime.now(),
      jenisTbc: '',
      statusHiv: '',
    );
    
    final userId = await DatabaseHelper().insertUser(user);
    
    return {
      'success': true,
      'userId': userId,
    };
  }

  // LOGIN dengan SQLite
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final key = email.toLowerCase().trim();
    
    final user = await DatabaseHelper().getUserByEmail(key);
    
    if (user == null || user.password != _hash(password)) {
      return {
        'success': false,
        'message': 'Email atau kata sandi salah',
      };
    }
    
    // Cek apakah user sudah melengkapi data diri
    final isCompleted = user.nama.isNotEmpty && user.umur > 0;
    
    // Set user yang sedang login ke DatabaseHelper
    DatabaseHelper().setLoggedInUser(user.id!);
    
    return {
      'success': true,
      'userId': user.id,
      'isNewUser': !isCompleted,
    };
  }

  // UPDATE data diri user setelah register
  Future<bool> updateUserData({
    required String email,
    required String nama,
    required int umur,
    required DateTime tanggalDiagnosis,
    required String jenisTbc,
    required String statusHiv,
  }) async {
    final user = await DatabaseHelper().getUserByEmail(email.toLowerCase().trim());
    if (user == null) return false;
    
    user.nama = nama;
    user.umur = umur;
    user.tanggalDiagnosis = tanggalDiagnosis;
    user.jenisTbc = jenisTbc;
    user.statusHiv = statusHiv;
    
    await DatabaseHelper().updateUser(user);
    return true;
  }

  // UPDATE jadwal obat
  Future<bool> updateJadwalObat({
    required String email,
    required List<Map<String, dynamic>> sesiList,
  }) async {
    final user = await DatabaseHelper().getUserByEmail(email.toLowerCase().trim());
    if (user == null) return false;
    
    // Buat jadwal baru
    final jadwal = JadwalObat(
      userId: user.id!,
      status: 1,
    );
    final jadwalId = await DatabaseHelper().insertJadwal(jadwal);
    
    // Insert sesi
    for (var sesi in sesiList) {
      final newSesi = Sesi(
        userId: user.id!,
        namaSesi: sesi['nama_sesi'],
        namaObat: sesi['nama_obat'],
        waktu: sesi['waktu'],
        status: 1,
        jadwalId: jadwalId,
      );
      await DatabaseHelper().insertSesi(newSesi);
    }
    
    return true;
  }

  // LOGIN dengan Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    // TODO: Implement Google Sign In nanti
    return {
      'success': false,
      'message': 'Fitur Google Sign In sedang dalam pengembangan',
    };
  }
  
  // MARK user completed (untuk backward compatibility)
  void markUserCompleted(String email) {
    // Tidak perlu karena sudah pakai SQLite
  }

  bool isUserCompleted(String email) {
    // Tidak perlu karena sudah pakai SQLite
    return true;
  }

  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await DatabaseHelper().logout();
  }

  Future<void> saveRememberMe(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('remember_email', email);
  }

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('remember_email');
  }

  Future<void> clearRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_email');
  }
}