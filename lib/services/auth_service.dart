import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../models/user.dart';
import '../models/jadwal_obat.dart';
import '../models/sesi.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void> init() async {
    await GoogleSignIn.instance.initialize();
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

    final hasDataDiri = user.nama.isNotEmpty && user.umur > 0;

    final jadwal = hasDataDiri
        ? await DatabaseHelper().getJadwalByUserId(user.id!)
        : null;
    final hasDataObat = jadwal != null;

    DatabaseHelper().setLoggedInUser(user.id!);

    return {
      'success': true,
      'userId': user.id,
      'hasDataDiri': hasDataDiri,
      'hasDataObat': hasDataObat,
      'isNewUser': !hasDataDiri || !hasDataObat,
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
    final user =
        await DatabaseHelper().getUserByEmail(email.toLowerCase().trim());
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
    final user =
        await DatabaseHelper().getUserByEmail(email.toLowerCase().trim());
    if (user == null) return false;

    final jadwal = JadwalObat(
      userId: user.id!,
      status: 1,
    );
    final jadwalId = await DatabaseHelper().insertJadwal(jadwal);

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

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final email = googleUser.email.toLowerCase().trim();
      final name = googleUser.displayName ?? '';
      final photoUrl = googleUser.photoUrl;

      var user = await DatabaseHelper().getUserByEmail(email);
      bool isNewUser = false;

      if (user == null) {
        final newUser = User(
          email: email,
          password: _hash(googleUser.id),
          nama: name,
          umur: 0,
          tanggalDiagnosis: DateTime.now(),
          jenisTbc: '',
          statusHiv: '',
        );
        final userId = await DatabaseHelper().insertUser(newUser);
        user = await DatabaseHelper().getUserById(userId);
        isNewUser = true;
      }

      DatabaseHelper().setLoggedInUser(user!.id!);

      final hasDataDiri = user.nama.isNotEmpty && user.umur > 0;
      final jadwal = hasDataDiri
          ? await DatabaseHelper().getJadwalByUserId(user.id!)
          : null;
      final hasDataObat = jadwal != null;

      return {
        'success': true,
        'userId': user.id,
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

  void markUserCompleted(String email) {}

  bool isUserCompleted(String email) => true;

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