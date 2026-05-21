import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../database/database_helper.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> init() async {
    // Method ini bisa kosong
    print('AuthService initialized');
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

    final existingUser = await DatabaseHelper().getUserByEmail(key);
    if (existingUser != null) {
      return {
        'success': false,
        'message': 'Email sudah terdaftar',
      };
    }

    final userData = {
      'email': key,
      'password': _hash(password),
      'nama': '',
      'umur': 0,
      'tanggal_diagnosis': DateTime.now().toIso8601String(),
      'jenis_tbc': '',
      'status_hiv': '',
      'tahap_pengobatan': '',
      'masa_pengobatan': '',
    };

    final userId = await DatabaseHelper().insertUser(userData);

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

    if (user == null || user['password'] != _hash(password)) {
      return {
        'success': false,
        'message': 'Email atau kata sandi salah',
      };
    }

    final hasDataDiri = user['nama'].isNotEmpty && user['umur'] > 0;

    final jadwalId = hasDataDiri
        ? await DatabaseHelper().getJadwalIdByUserId(user['id'])
        : null;
    final hasDataObat = jadwalId != null;

    DatabaseHelper().setLoggedInUser(user['id']);

    return {
      'success': true,
      'userId': user['id'],
      'email': user['email'],
      'name': user['nama'],
      'hasDataDiri': hasDataDiri,
      'hasDataObat': hasDataObat,
    };
  }

  // LOGIN dengan Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Login dibatalkan',
        };
      }

    final email = googleUser.email.toLowerCase().trim();
    final name = googleUser.displayName ?? '';
    final photoUrl = googleUser.photoUrl;

    // ... sisa kode tetap sama

      var user = await DatabaseHelper().getUserByEmail(email);
      bool isNewUser = false;

      if (user == null) {
        final newUserData = {
          'email': email,
          'password': _hash(googleUser.id),
          'nama': name,
          'umur': 0,
          'tanggal_diagnosis': DateTime.now().toIso8601String(),
          'jenis_tbc': '',
          'status_hiv': '',
          'tahap_pengobatan': '',
          'masa_pengobatan': '',
        };
        final userId = await DatabaseHelper().insertUser(newUserData);
        user = await DatabaseHelper().getUserById(userId);
        isNewUser = true;
      }

      if (user == null) {
        return {
          'success': false,
          'message': 'Gagal membuat akun',
        };
      }

      DatabaseHelper().setLoggedInUser(user['id']);

      final hasDataDiri = user['nama'].isNotEmpty && user['umur'] > 0;
      final jadwalId = hasDataDiri
          ? await DatabaseHelper().getJadwalIdByUserId(user['id'])
          : null;
      final hasDataObat = jadwalId != null;

      return {
        'success': true,
        'userId': user['id'],
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
        'isNewUser': isNewUser,
        'hasDataDiri': hasDataDiri,
        'hasDataObat': hasDataObat,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal login dengan Google: $e',
      };
    }
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

  // Method helper untuk ambil user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    return await DatabaseHelper().getUserByEmail(email);
  }
}