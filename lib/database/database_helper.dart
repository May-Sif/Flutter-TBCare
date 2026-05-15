import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tbcare.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel user (data diri pasien)
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        nama TEXT NOT NULL,
        umur INTEGER NOT NULL,
        tanggal_diagnosis TEXT NOT NULL,
        jenis_tbc TEXT NOT NULL,
        status_hiv TEXT,
        tahap_pengobatan TEXT,
        masa_pengobatan TEXT
      )
    ''');

    // Tabel jadwal obat (1 user punya 1 jadwal)
    await db.execute('''
      CREATE TABLE jadwal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE
      )
    ''');

    // Tabel sesi (detail obat per sesi)
    await db.execute('''
      CREATE TABLE sesi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jadwal_id INTEGER NOT NULL,
        nama_sesi TEXT NOT NULL,
        nama_obat TEXT NOT NULL,
        waktu TEXT NOT NULL,
        waktu_makan TEXT,
        keterangan TEXT,
        FOREIGN KEY (jadwal_id) REFERENCES jadwal (id) ON DELETE CASCADE
      )
    ''');

    // Tabel kepatuhan (tracking minum obat per hari)
    await db.execute('''
      CREATE TABLE kepatuhan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        status INTEGER DEFAULT 0,
        UNIQUE(user_id, tanggal),
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE
      )
    ''');
  }

  // ========== USER ==========
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert('user', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'user',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'user',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUser(int userId, Map<String, dynamic> user) async {
    Database db = await database;
    return await db.update(
      'user',
      user,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ========== JADWAL & SESI ==========
  Future<int> insertJadwal(int userId) async {
    Database db = await database;
    return await db.insert('jadwal', {'user_id': userId});
  }

  Future<int?> getJadwalIdByUserId(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'jadwal',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first['id'] : null;
  }

  Future<int> insertSesi(Map<String, dynamic> sesi) async {
    Database db = await database;
    return await db.insert('sesi', sesi);
  }

  Future<List<Map<String, dynamic>>> getSesiByJadwalId(int jadwalId) async {
    Database db = await database;
    return await db.query(
      'sesi',
      where: 'jadwal_id = ?',
      whereArgs: [jadwalId],
    );
  }

  Future<int> deleteSesiByJadwalId(int jadwalId) async {
    Database db = await database;
    return await db.delete('sesi', where: 'jadwal_id = ?', whereArgs: [jadwalId]);
  }

  // ========== KEPATUHAN ==========
  Future<int> updateKepatuhan(int userId, String tanggal, int status) async {
    Database db = await database;
    
    // Cek apakah sudah ada
    List<Map<String, dynamic>> existing = await db.query(
      'kepatuhan',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, tanggal],
    );
    
    if (existing.isNotEmpty) {
      // Update
      return await db.update(
        'kepatuhan',
        {'status': status},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      // Insert baru
      return await db.insert('kepatuhan', {
        'user_id': userId,
        'tanggal': tanggal,
        'status': status,
      });
    }
  }

  Future<int> getKepatuhanCount(int userId, String bulan) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'kepatuhan',
      where: 'user_id = ? AND tanggal LIKE ? AND status = 1',
      whereArgs: [userId, '$bulan%'],
    );
    return result.length;
  }

  // ========== SIMPAN DATA LENGKAP ==========
  Future<int> saveCompleteUserData(
    Map<String, dynamic> dataDiri,
    List<Map<String, dynamic>> jadwalObat, {
    String? email,
  }) async {
    Database db = await database;
    
    try {
      // 1. Cek user berdasarkan email
      String userEmail = email ?? dataDiri['nama'].toLowerCase().replaceAll(' ', '.') + '@tbcare.com';
      Map<String, dynamic>? existingUser = await getUserByEmail(userEmail);
      
      int userId;
      
      if (existingUser != null) {
        userId = existingUser['id'];
        // Update user
        await updateUser(userId, {
          'nama': dataDiri['nama'],
          'umur': int.parse(dataDiri['umur']),
          'tanggal_diagnosis': dataDiri['tanggalDiagnosis'],
          'jenis_tbc': dataDiri['tipeTbc'],
          'status_hiv': dataDiri['statusHiv'],
          'tahap_pengobatan': dataDiri['tahapPengobatan'],
          'masa_pengobatan': dataDiri['masaPengobatan'],
        });
      } else {
        // Insert user baru
        userId = await insertUser({
          'email': userEmail,
          'password': 'default123',
          'nama': dataDiri['nama'],
          'umur': int.parse(dataDiri['umur']),
          'tanggal_diagnosis': dataDiri['tanggalDiagnosis'],
          'jenis_tbc': dataDiri['tipeTbc'],
          'status_hiv': dataDiri['statusHiv'],
          'tahap_pengobatan': dataDiri['tahapPengobatan'],
          'masa_pengobatan': dataDiri['masaPengobatan'],
        });
      }
      
      // 2. Hapus jadwal lama jika ada
      int? jadwalId = await getJadwalIdByUserId(userId);
      if (jadwalId != null) {
        await deleteSesiByJadwalId(jadwalId);
      } else {
        jadwalId = await insertJadwal(userId);
      }
      
      // 3. Insert sesi baru
      for (var obat in jadwalObat) {
        await insertSesi({
          'jadwal_id': jadwalId,
          'nama_sesi': obat['sesi'].toLowerCase(),
          'nama_obat': obat['namaObat'],
          'waktu': obat['waktu'],
          'waktu_makan': obat['waktuMakan'],
          'keterangan': obat['keterangan'],
        });
      }
      
      setLoggedInUser(userId);
      return userId;
      
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // ========== SESSION MANAGEMENT ==========
  int? _currentUserId;

  void setLoggedInUser(int userId) {
    _currentUserId = userId;
  }

  int? getCurrentUserId() {
    return _currentUserId;
  }

  bool isUserLoggedIn() {
    return _currentUserId != null;
  }

  Future<void> logout() async {
    _currentUserId = null;
  }

  // Untuk mengambil data lengkap user
  Future<Map<String, dynamic>> getCompleteUserData(int userId) async {
    Database db = await database;
    
    // Ambil user
    List<Map<String, dynamic>> userResult = await db.query(
      'user',
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    if (userResult.isEmpty) return {};
    
    final user = userResult.first;
    
    // Ambil jadwal
    int? jadwalId = await getJadwalIdByUserId(userId);
    
    List<Map<String, dynamic>> jadwalObat = [];
    
    if (jadwalId != null) {
      List<Map<String, dynamic>> sesiList = await getSesiByJadwalId(jadwalId);
      
      for (var sesi in sesiList) {
        jadwalObat.add({
          'sesi': _capitalize(sesi['nama_sesi']),
          'namaObat': sesi['nama_obat'],
          'waktu': sesi['waktu'],
          'waktuMakan': sesi['waktu_makan'] ?? 'Setelah Makan',
          'keterangan': sesi['keterangan'] ?? '',
        });
      }
    }
    
    Map<String, String> dataDiri = {
      'nama': user['nama'],
      'umur': user['umur'].toString(),
      'tanggalDiagnosis': user['tanggal_diagnosis'],
      'tipeTbc': user['jenis_tbc'],
      'statusHiv': user['status_hiv'] ?? 'Tidak tahu',
      'tahapPengobatan': user['tahap_pengobatan'] ?? 'Tahap Intensif',
      'masaPengobatan': user['masa_pengobatan'] ?? '6 bulan',
    };
    
    return {
      'dataDiri': dataDiri,
      'jadwalObat': jadwalObat,
    };
  }

  // Untuk mengambil email user
  Future<String?> getUserEmail(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'user',
      where: 'id = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first['email'] : null;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<int> getKepatuhanStatus(int userId, String tanggal) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'kepatuhan',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, tanggal],
    );
    return result.isNotEmpty ? result.first['status'] as int? ?? 0 : 0;
  }

  // Tambahkan di DatabaseHelper

  Future<Map<String, dynamic>?> getUserById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'user',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }
}