import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

final Map<String, String> _registeredUsers = {};

final Set<String> _completedUsers = {};

class AuthService {
  static final AuthService 
    _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn 
    _googleSignIn = GoogleSignIn.instance;

  Future<void> init() async {
    await _googleSignIn.initialize();
  }

  String _hash(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  Map<String, dynamic> register({
    required String email,
    required String password,
  }) {
    final key = email.toLowerCase().trim();
    if (_registeredUsers.containsKey(key)) {
      return {
        'success': false,
        'message': 'Email sudah terdaftar',
      };
    }
    _registeredUsers[key] = _hash(password);
    return {'success': true};
  }

  Map<String, dynamic> login({
    required String email,
    required String password,
  }) {
    final key = email.toLowerCase().trim();
    final stored = _registeredUsers[key];
    if (stored == null || stored != _hash(password)) {
      return {
        'success': false, 
        'message': 'Email atau kata sandi salah'
      };
    }
    return {
      'success': true,
      'isNewUser': !_completedUsers.contains(key),
    };
  }

  void markUserCompleted(String email) {
    _completedUsers.add(email.toLowerCase().trim());
  }

  bool isUserCompleted(String email) {
    return _completedUsers.contains(email.toLowerCase().trim());
  }

  Future<Map<String, dynamic>> signInWithGoogle() 
  async {
    try {
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        return {
          'success': false,
        };
      }
      final account = await _googleSignIn.authenticate();
      final key = account.email.toLowerCase().trim();
      return {
        'success': true,
        'email': account.email,
        'name': account.displayName ?? '',
        'photoUrl': account.photoUrl,
        'isNewUser': !_completedUsers.contains(key),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal masuk dengan Google\n${e.toString()}',
      };
    }
  }

  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
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