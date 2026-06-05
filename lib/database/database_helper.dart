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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    // Tabel efek_samping (LAMA - untuk kompatibilitas)
    await db.execute('''
      CREATE TABLE efek_samping (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        efek TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE,
        UNIQUE(user_id, tanggal, efek)
      )
    ''');

    // tabel sesi_kepatuhan
    await db.execute('''
      CREATE TABLE sesi_kepatuhan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        sesi_index INTEGER NOT NULL,
        status INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE,
        UNIQUE(user_id, tanggal, sesi_index)
      )
    ''');

    // Tabel riwayat perubahan obat
    await db.execute('''
      CREATE TABLE riwayat_perubahan_obat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        obat_lama TEXT NOT NULL,
        obat_baru TEXT NOT NULL,
        alasan TEXT,
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE
      )
    ''');

    // Tabel screening_mingguan
    await db.execute('''
      CREATE TABLE screening_mingguan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        tanggal_screening TEXT NOT NULL,
        minggu_ke INTEGER NOT NULL,
        skor INTEGER NOT NULL,
        status TEXT NOT NULL,
        kesimpulan_hasil TEXT NOT NULL,
        berat_badan_saat_ini REAL,
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE
      )
    ''');

    // ========== TABEL BARU UNTUK EFEK SAMPING DENGAN SKOR ==========
    
    // Tabel list_efek_samping (master data efek samping)
    await db.execute('''
      CREATE TABLE list_efek_samping (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_efek_samping TEXT NOT NULL,
        skor_default INTEGER NOT NULL
      )
    ''');

    // Insert data efek samping default
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Mual / Muntah', 'skor_default': 1});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Gatal / Ruam kulit', 'skor_default': 1});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Pusing / Sakit kepala', 'skor_default': 1});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Nyeri sendi', 'skor_default': 1});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Kurang nafsu makan', 'skor_default': 1});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Demam (tanpa sebab jelas)', 'skor_default': 2});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Urine berwarna gelap', 'skor_default': 2});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Kuning (kulit/mata menguning)', 'skor_default': 3});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Gangguan penglihatan', 'skor_default': 3});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Dahak berdarah', 'skor_default': 3});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Kejang-kejang', 'skor_default': 3});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Perdarahan (gusi/mimisan/memar)', 'skor_default': 3});

    // Tabel efek_samping_pasien (menyimpan efek samping yang dipilih pasien)
    await db.execute('''
      CREATE TABLE efek_samping_pasien (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        efek_samping_id INTEGER NOT NULL,
        skor INTEGER NOT NULL,
        keterangan TEXT,
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE,
        FOREIGN KEY (efek_samping_id) REFERENCES list_efek_samping (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Tambahkan tabel list_efek_samping
      await db.execute('''
        CREATE TABLE IF NOT EXISTS list_efek_samping (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama_efek_samping TEXT NOT NULL,
          skor_default INTEGER NOT NULL
        )
      ''');

      try {
        await db.execute('ALTER TABLE screening_mingguan ADD COLUMN berat_badan_saat_ini REAL');
        print('Berhasil menambah kolom berat_badan_saat_ini');
      } catch (e) {
        print('Error saat migrasi: $e');
      }
      
      // Insert data efek samping default (hanya jika tabel kosong)
      final List<Map<String, dynamic>> existing = await db.query('list_efek_samping');
      if (existing.isEmpty) {
        await db.insert('list_efek_samping', {'nama_efek_samping': 'Mual / Muntah', 'skor_default': 1});
        await db.insert('list_efek_samping', {'nama_efek_samping': 'Gatal / Ruam kulit', 'skor_default': 1});
        await db.insert('list_efek_samping', {'nama_efek_samping': 'Pusing / Sakit kepala', 'skor_default': 1});
        await db.insert('list_efek_samping', {'nama_efek_samping': 'Nyeri sendi', 'skor_default': 1});
        await db.insert('list_efek_samping', {'nama_efek_samping': 'Kurang nafsu makan', 'skor_default': 1});
        await db.insert('list_efek_samping', {'nama_efek_samping': 'Demam (tanpa sebab jelas)', 'skor_default': 2});
        await db.insert('list_efek_samping', {'nama_efek_samping': 'Urine berwarna gelap', 'skor_default': 2});
        await db.insert('list_efek_samping', {'nama_efek_samping': 'Kuning (kulit/mata menguning)', 'skor_default': 3});
        await db.insert('list_efek_samping', {'nama_efek_samping': 'Gangguan penglihatan', 'skor_default': 3});
        await db.insert('list_efek_samping', {'nama_efek_samping': 'Dahak berdarah', 'skor_default': 3});
        await db.insert('list_efek_samping', {'nama_efek_samping': 'Kejang-kejang', 'skor_default': 3});
        await db.insert('list_efek_samping', {'nama_efek_samping': 'Perdarahan (gusi/mimisan/memar)', 'skor_default': 3});
      }
      
      // Tambahkan tabel efek_samping_pasien
      await db.execute('''
        CREATE TABLE IF NOT EXISTS efek_samping_pasien (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          tanggal TEXT NOT NULL,
          efek_samping_id INTEGER NOT NULL,
          skor INTEGER NOT NULL,
          keterangan TEXT,
          FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE,
          FOREIGN KEY (efek_samping_id) REFERENCES list_efek_samping (id) ON DELETE CASCADE
        )
      ''');
    }
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
    
    List<Map<String, dynamic>> existing = await db.query(
      'kepatuhan',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, tanggal],
    );
    
    if (existing.isNotEmpty) {
      return await db.update(
        'kepatuhan',
        {'status': status},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
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
      String userEmail = email ?? dataDiri['nama'].toLowerCase().replaceAll(' ', '.') + '@tbcare.com';
      Map<String, dynamic>? existingUser = await getUserByEmail(userEmail);
      
      int userId;
      
      if (existingUser != null) {
        userId = existingUser['id'];
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
      
      int? jadwalId = await getJadwalIdByUserId(userId);
      if (jadwalId != null) {
        await deleteSesiByJadwalId(jadwalId);
      } else {
        jadwalId = await insertJadwal(userId);
      }
      
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

  Future<Map<String, dynamic>> getCompleteUserData(int userId) async {
    Database db = await database;
    
    List<Map<String, dynamic>> userResult = await db.query(
      'user',
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    if (userResult.isEmpty) return {};
    
    final user = userResult.first;
    
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

  Future<Map<String, dynamic>?> getUserById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'user',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // ========== EFEK SAMPING (LAMA) ==========
  Future<void> saveEfekSamping(int userId, String tanggal, List<String> efekList) async {
    Database db = await database;
    
    await db.delete(
      'efek_samping',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, tanggal],
    );
    
    for (var efek in efekList) {
      await db.insert('efek_samping', {
        'user_id': userId,
        'tanggal': tanggal,
        'efek': efek.toLowerCase(),
      });
    }
  }

  // Tambahkan method ini di DatabaseHelper class
  Future<List<Map<String, dynamic>>> getLatestEfekSampingByUserId(int userId, {int limit = 5}) async {
    Database db = await database;
    
    return await db.rawQuery('''
      SELECT esp.*, les.nama_efek_samping 
      FROM efek_samping_pasien esp
      JOIN list_efek_samping les ON esp.efek_samping_id = les.id
      WHERE esp.user_id = ?
      ORDER BY esp.tanggal DESC, esp.skor DESC
      LIMIT ?
    ''', [userId, limit]);
  }

  Future<List<String>> getEfekSampingByDate(int userId, String tanggal) async {
    Database db = await database;
    final result = await db.query(
      'efek_samping',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, tanggal],
    );
    return result.map((e) => e['efek'] as String).toList();
  }

  Future<Map<String, List<String>>> getEfekSampingByMonth(int userId, int tahun, int bulan) async {
    Database db = await database;
    final bulanStr = '$tahun-${bulan.toString().padLeft(2, '0')}';
    final result = await db.query(
      'efek_samping',
      where: 'user_id = ? AND tanggal LIKE ?',
      whereArgs: [userId, '$bulanStr%'],
      orderBy: 'tanggal DESC',
    );
    
    final Map<String, List<String>> map = {};
    for (var row in result) {
      final tanggal = row['tanggal'] as String;
      final efek = row['efek'] as String;
      if (!map.containsKey(tanggal)) {
        map[tanggal] = [];
      }
      map[tanggal]!.add(efek);
    }
    return map;
  }

  // ========== EFEK SAMPING DENGAN SKOR (BARU) ==========

  // Ambil semua daftar efek samping yang tersedia
  Future<List<Map<String, dynamic>>> getAllListEfekSamping() async {
    Database db = await database;
    return await db.query('list_efek_samping', orderBy: 'id');
  }

  // Simpan efek samping pasien dengan skor
  Future<int> saveEfekSampingPasien(int userId, DateTime tanggal, int efekSampingId, int skor, String? keterangan) async {
    Database db = await database;
    final dateStr = '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';
    
    return await db.insert('efek_samping_pasien', {
      'user_id': userId,
      'tanggal': dateStr,
      'efek_samping_id': efekSampingId,
      'skor': skor,
      'keterangan': keterangan,
    });
  }

  // Simpan multiple efek samping sekaligus
  Future<void> saveMultipleEfekSampingPasien(int userId, DateTime tanggal, List<Map<String, dynamic>> efekList) async {
    Database db = await database;
    final dateStr = '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';
    
    await db.delete(
      'efek_samping_pasien',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, dateStr],
    );
    
    for (var efek in efekList) {
      await db.insert('efek_samping_pasien', {
        'user_id': userId,
        'tanggal': dateStr,
        'efek_samping_id': efek['efek_samping_id'],
        'skor': efek['skor'],
        'keterangan': efek['keterangan'],
      });
    }
  }

  // Ambil efek samping pasien berdasarkan tanggal
  Future<List<Map<String, dynamic>>> getEfekSampingPasienByDate(int userId, DateTime tanggal) async {
    Database db = await database;
    final dateStr = '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';
    
    return await db.rawQuery('''
      SELECT esp.*, les.nama_efek_samping 
      FROM efek_samping_pasien esp
      JOIN list_efek_samping les ON esp.efek_samping_id = les.id
      WHERE esp.user_id = ? AND esp.tanggal = ?
      ORDER BY esp.skor DESC
    ''', [userId, dateStr]);
  }

  // Ambil semua efek samping pasien dalam bulan tertentu (LENGKAP dengan nama efek)
  Future<Map<String, List<Map<String, dynamic>>>> getEfekSampingPasienByMonth(int userId, int tahun, int bulan) async {
    Database db = await database;
    final bulanStr = '$tahun-${bulan.toString().padLeft(2, '0')}';
    
    final result = await db.rawQuery('''
      SELECT esp.*, les.nama_efek_samping 
      FROM efek_samping_pasien esp
      JOIN list_efek_samping les ON esp.efek_samping_id = les.id
      WHERE esp.user_id = ? AND esp.tanggal LIKE ?
      ORDER BY esp.tanggal DESC, esp.skor DESC
    ''', [userId, '$bulanStr%']);
    
    final Map<String, List<Map<String, dynamic>>> map = {};
    for (var row in result) {
      final tanggal = row['tanggal'] as String;
      if (!map.containsKey(tanggal)) {
        map[tanggal] = [];
      }
      map[tanggal]!.add(row);
    }
    return map;
  }

  // Hapus efek samping pasien pada tanggal tertentu
  Future<int> deleteEfekSampingPasienByDate(int userId, DateTime tanggal) async {
    Database db = await database;
    final dateStr = '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';
    
    return await db.delete(
      'efek_samping_pasien',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, dateStr],
    );
  }

  // Hitung total skor efek samping pada bulan tertentu
  Future<int> getTotalSkorEfekSampingByMonth(int userId, int tahun, int bulan) async {
    Database db = await database;
    final bulanStr = '$tahun-${bulan.toString().padLeft(2, '0')}';
    
    final result = await db.rawQuery('''
      SELECT SUM(skor) as total_skor
      FROM efek_samping_pasien
      WHERE user_id = ? AND tanggal LIKE ?
    ''', [userId, '$bulanStr%']);
    
    return (result.first['total_skor'] as int? ?? 0);
  }

  // Ambil efek samping dengan skor tertinggi pada bulan tertentu
  Future<List<Map<String, dynamic>>> getEfekSampingTertinggiByMonth(int userId, int tahun, int bulan) async {
    Database db = await database;
    final bulanStr = '$tahun-${bulan.toString().padLeft(2, '0')}';
    
    return await db.rawQuery('''
      SELECT les.nama_efek_samping, esp.skor, COUNT(*) as jumlah
      FROM efek_samping_pasien esp
      JOIN list_efek_samping les ON esp.efek_samping_id = les.id
      WHERE esp.user_id = ? AND esp.tanggal LIKE ?
      GROUP BY esp.efek_samping_id
      ORDER BY esp.skor DESC
      LIMIT 5
    ''', [userId, '$bulanStr%']);
  }

  // ========== SESI KEPATUHAN ==========
  Future<void> updateSesiKepatuhan(int userId, String tanggal, int sesiIndex, int status) async {
    Database db = await database;
    
    final existing = await db.query(
      'sesi_kepatuhan',
      where: 'user_id = ? AND tanggal = ? AND sesi_index = ?',
      whereArgs: [userId, tanggal, sesiIndex],
    );
    
    if (existing.isNotEmpty) {
      await db.update(
        'sesi_kepatuhan',
        {'status': status},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('sesi_kepatuhan', {
        'user_id': userId,
        'tanggal': tanggal,
        'sesi_index': sesiIndex,
        'status': status,
      });
    }
  }

  Future<Map<int, int>> getSesiKepatuhanByDate(int userId, String tanggal) async {
    Database db = await database;
    final result = await db.query(
      'sesi_kepatuhan',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, tanggal],
    );
    
    final Map<int, int> map = {};
    for (var row in result) {
      map[row['sesi_index'] as int] = row['status'] as int;
    }
    return map;
  }

  // ========== RIWAYAT PERUBAHAN OBAT ==========
  Future<int> insertRiwayatPerubahanObat({
    required int userId,
    required String tanggal,
    required String obatLama,
    required String obatBaru,
    String? alasan,
  }) async {
    Database db = await database;
    return await db.insert('riwayat_perubahan_obat', {
      'user_id': userId,
      'tanggal': tanggal,
      'obat_lama': obatLama,
      'obat_baru': obatBaru,
      'alasan': alasan,
    });
  }

  Future<List<Map<String, dynamic>>> getRiwayatPerubahanObat(int userId) async {
    Database db = await database;
    return await db.query(
      'riwayat_perubahan_obat',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tanggal DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getRiwayatPerubahanObatByMonth(
    int userId, 
    int tahun, 
    int bulan
  ) async {
    Database db = await database;
    final bulanStr = '$tahun-${bulan.toString().padLeft(2, '0')}';
    return await db.query(
      'riwayat_perubahan_obat',
      where: 'user_id = ? AND tanggal LIKE ?',
      whereArgs: [userId, '$bulanStr%'],
      orderBy: 'tanggal DESC',
    );
  }

  // ========== SCREENING MINGGUAN ==========
  Future<int> insertScreeningMingguan(Map<String, dynamic> screening) async {
    Database db = await database;
    return await db.insert('screening_mingguan', screening);
  }

  Future<List<Map<String, dynamic>>> getScreeningMingguanByUserId(int userId) async {
    Database db = await database;
    return await db.query(
      'screening_mingguan',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'minggu_ke DESC',
    );
  }

  Future<Map<String, dynamic>?> getLatestScreening(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'screening_mingguan',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tanggal_screening DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // ========== KEPATUHAN HARIAN (CEK SEMUA SESI) ==========
  Future<bool> isAllSesiObatDiminum(int userId, DateTime date) async {
    Database db = await database;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    final jadwalId = await getJadwalIdByUserId(userId);
    if (jadwalId == null) return false;
    
    final sesiList = await getSesiByJadwalId(jadwalId);
    final totalSesi = sesiList.length;
    
    if (totalSesi == 0) return false;
    
    final result = await db.query(
      'sesi_kepatuhan',
      where: 'user_id = ? AND tanggal = ? AND status = 1',
      whereArgs: [userId, dateStr],
    );
    
    return result.length == totalSesi;
  }

  Future<int> getJumlahSesiDiminum(int userId, DateTime date) async {
    Database db = await database;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    final result = await db.query(
      'sesi_kepatuhan',
      where: 'user_id = ? AND tanggal = ? AND status = 1',
      whereArgs: [userId, dateStr],
    );
    
    return result.length;
  }

  Future<int> getTotalSesiObat(int userId) async {
    final jadwalId = await getJadwalIdByUserId(userId);
    if (jadwalId == null) return 0;
    
    final sesiList = await getSesiByJadwalId(jadwalId);
    return sesiList.length;
  }

  // Reset semua data kepatuhan dan efek samping user
  Future<void> resetUserProgress(int userId) async {
    Database db = await database;
    
    // Hapus semua data kepatuhan (sesi_kepatuhan)
    await db.delete(
      'sesi_kepatuhan',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    // Hapus semua data kepatuhan harian (kepatuhan)
    await db.delete(
      'kepatuhan',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    // Hapus semua data efek samping pasien
    await db.delete(
      'efek_samping_pasien',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    // Hapus semua data screening mingguan
    await db.delete(
      'screening_mingguan',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    await db.delete(
      'riwayat_perubahan_obat',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}