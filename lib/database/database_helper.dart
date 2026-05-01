import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/jadwal_obat.dart';
import '../models/sesi.dart';
import '../models/list_efek_samping.dart';
import '../models/efek_samping_pasien.dart';
import '../models/screening_mingguan.dart';
import '../models/kuesioner_gejala.dart';
import '../models/riwayat_kepatuhan.dart';
import '../models/sesi_riwayat.dart';

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
    // Tabel user
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        nama TEXT NOT NULL,
        umur INTEGER NOT NULL,
        tanggal_diagnosis TEXT NOT NULL,
        jenis_tbc TEXT NOT NULL,
        status_hiv TEXT
      )
    ''');

    // Tabel jadwal
    await db.execute('''
      CREATE TABLE jadwal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    // Tabel sesi (langsung ke user, tanpa jadwal_obat)
    await db.execute('''
      CREATE TABLE sesi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        nama_sesi TEXT NOT NULL,
        nama_obat TEXT NOT NULL,
        waktu TEXT NOT NULL,
        status INTEGER DEFAULT 1,
        jadwal_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE
        FOREIGN KEY (jadwal_id) REFERENCES jadwal (id) ON DELETE CASCADE
      )
    ''');

    // Tabel list_efek_samping (master)
    await db.execute('''
      CREATE TABLE list_efek_samping (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_efek_samping TEXT NOT NULL,
        skor INTEGER NOT NULL
      )
    ''');

    // Tabel efek_samping_pasien
    await db.execute('''
      CREATE TABLE efek_samping_pasien (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        efek_samping_id INTEGER NOT NULL,
        skor INTEGER NOT NULL,
        keterangan TEXT,
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE,
        FOREIGN KEY (efek_samping_id) REFERENCES list_efek_samping (id)
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
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE
      )
    ''');

    // Tabel kuesioner_gejala
    await db.execute('''
      CREATE TABLE kuesioner_gejala (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        skrining_id INTEGER NOT NULL,
        skor_batuk INTEGER NOT NULL,
        skor_dahak INTEGER NOT NULL,
        skor_demam INTEGER NOT NULL,
        skor_sesak INTEGER NOT NULL,
        skor_berat_badan INTEGER NOT NULL,
        total_skor_mentah INTEGER NOT NULL,
        skor INTEGER NOT NULL,
        status_risiko TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE,
        FOREIGN KEY (skrining_id) REFERENCES screening_mingguan (id) ON DELETE CASCADE
      )
    ''');

    // Tabel riwayat_kepatuhan
    await db.execute('''
      CREATE TABLE riwayat_kepatuhan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        tanggal_minum TEXT NOT NULL,
        status INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE,
        UNIQUE(user_id, tanggal_minum)
      )
    ''');

    // Tabel detail sesi riwayat
    await db.execute('''
      CREATE TABLE detail_sesi_riwayat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        riwayat_kepatuhan_id INTEGER NOT NULL,
        nama_sesi TEXT NOT NULL,
        status INTEGER DEFAULT 0,
        reminder_dikirim INTEGER DEFAULT 0,
        FOREIGN KEY (riwayat_kepatuhan_id) REFERENCES riwayat_kepatuhan (id) ON DELETE CASCADE
      )
    ''');

    // Insert data master list_efek_samping
    // 1 = ringan, 2 = sedang, 3 = berat
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Mual', 'skor': 1});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Gatal', 'skor': 1});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Pusing', 'skor': 1});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Sakit kepala', 'skor': 1});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Nyeri sendi', 'skor': 1});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Demam', 'skor': 2});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Urine berwarna gelap', 'skor': 2});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Kuning', 'skor': 3});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Gangguan penglihatan', 'skor': 3});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Dahak berdarah', 'skor': 3});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Kejang', 'skor': 3});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Memar', 'skor': 3});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Mimisan', 'skor': 3});
    await db.insert('list_efek_samping', {'nama_efek_samping': 'Gusi berdarah', 'skor': 3});
  }

  // ========== CRUD User ==========
  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert('user', user.toMap());
  }

  Future<User?> getUserById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'user',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'user',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<User?> getUserByPassword(String password) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'user',
      where: 'password = ?',
      whereArgs: [password],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<User?> loginUser(String email, String password) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'user',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    Database db = await database;
    return await db.update(
      'user',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    Database db = await database;
    return await db.delete('user', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD Jadwal ==========
  Future<int> insertJadwal(JadwalObat jadwal) async {
    Database db = await database;
    return await db.insert('jadwal', jadwal.toMap());
  }

  Future<JadwalObat?> getJadwalByUserId(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'jadwal',
      where: 'user_id = ?',
      whereArgs: [userId.toString()],
    );
    if (result.isNotEmpty) {
      return JadwalObat.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateJadwal(JadwalObat jadwal) async {
    Database db = await database;
    return await db.update(
      'jadwal',
      jadwal.toMap(),
      where: 'id = ?',
      whereArgs: [jadwal.id],
    );
  }

  Future<int> deleteJadwal(int id) async {
    Database db = await database;
    return await db.delete('jadwal', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD Sesi ==========
  Future<int> insertSesi(Sesi sesi) async {
    Database db = await database;
    return await db.insert('sesi', sesi.toMap());
  }

  Future<List<Sesi>> getSesiByJadwalId(int jadwalId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'sesi',
      where: 'jadwal_id = ?',
      whereArgs: [jadwalId],
      orderBy: """
        CASE nama_sesi 
          WHEN 'pagi' THEN 1 
          WHEN 'siang' THEN 2 
          WHEN 'malam' THEN 3 
          ELSE 4 
        END
      """,
    );
    return result.map((e) => Sesi.fromMap(e)).toList();
  }

  Future<List<Sesi>> getSesiByUserId(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'sesi',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.map((e) => Sesi.fromMap(e)).toList();
  }  

  Future<int> updateSesi(Sesi sesi) async {
    Database db = await database;
    return await db.update(
      'sesi',
      sesi.toMap(),
      where: 'id = ?',
      whereArgs: [sesi.id],
    );
  }

  Future<int> deleteSesi(int id) async {
    Database db = await database;
    return await db.delete('sesi', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSesiByJadwalId(int jadwalId) async {
    Database db = await database;
    return await db.delete('sesi', where: 'jadwal_id = ?', whereArgs: [jadwalId]);
  }  

  // ========== CRUD Master List Efek Samping ==========
  Future<List<Map<String, dynamic>>> getAllEfekSamping() async {
    Database db = await database;
    return await db.query('list_efek_samping', orderBy: 'skor ASC, nama_efek_samping ASC');
  }

  Future<List<Map<String, dynamic>>> getEfekSampingBySkor(int skor) async {
    Database db = await database;
    return await db.query(
      'list_efek_samping',
      where: 'skor = ?',
      whereArgs: [skor],
    );
  }

  Future<Map<String, dynamic>?> getEfekSampingById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'list_efek_samping',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // ========== CRUD Efek Samping Pasien ==========
  Future<int> insertEfekSampingPasien(EfekSampingPasien efekSamping) async {
    Database db = await database;
    return await db.insert('efek_samping_pasien', efekSamping.toMap());
  }

  Future<List<EfekSampingPasien>> getEfekSampingByUserId(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'efek_samping_pasien',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tanggal DESC',
    );
    return result.map((e) => EfekSampingPasien.fromMap(e)).toList();
  }

  Future<List<EfekSampingPasien>> getEfekSampingByDateRange(
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'efek_samping_pasien',
      where: 'user_id = ? AND tanggal >= ? AND tanggal <= ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'tanggal DESC',
    );
    return result.map((e) => EfekSampingPasien.fromMap(e)).toList();
  }

  Future<List<EfekSampingPasien>> getEfekSampingByDate(int userId, DateTime tanggal) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'efek_samping_pasien',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, tanggal.toIso8601String()],
    );
    return result.map((e) => EfekSampingPasien.fromMap(e)).toList();
  }

  Future<EfekSampingPasien?> getLatestEfekSamping(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'efek_samping_pasien',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tanggal DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return EfekSampingPasien.fromMap(result.first);
    }
    return null;
  }

  Future<int> deleteEfekSampingPasien(int id) async {
    Database db = await database;
    return await db.delete('efek_samping_pasien', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD Screening Mingguan ==========
  Future<int> insertScreeningMingguan(ScreeningMingguan screening) async {
    Database db = await database;
    return await db.insert('screening_mingguan', screening.toMap());
  }

  Future<List<ScreeningMingguan>> getScreeningByUserId(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'screening_mingguan',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tanggal_screening DESC',
    );
    return result.map((e) => ScreeningMingguan.fromMap(e)).toList();
  }

  Future<ScreeningMingguan?> getLatestScreening(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'screening_mingguan',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tanggal_screening DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return ScreeningMingguan.fromMap(result.first);
    }
    return null;
  }

  Future<ScreeningMingguan?> getScreeningByMingguKe(int userId, int mingguKe) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'screening_mingguan',
      where: 'user_id = ? AND minggu_ke = ?',
      whereArgs: [userId, mingguKe],
    );
    if (result.isNotEmpty) {
      return ScreeningMingguan.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateScreeningMingguan(ScreeningMingguan screening) async {
    Database db = await database;
    return await db.update(
      'screening_mingguan',
      screening.toMap(),
      where: 'id = ?',
      whereArgs: [screening.id],
    );
  }

  Future<int> deleteScreeningMingguan(int id) async {
    Database db = await database;
    return await db.delete('screening_mingguan', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD Kuesioner Gejala ==========
  Future<int> insertKuesionerGejala(KuesionerGejala kuesioner) async {
    Database db = await database;
    return await db.insert('kuesioner_gejala', kuesioner.toMap());
  }

  Future<List<KuesionerGejala>> getKuesionerByUserId(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'kuesioner_gejala',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return result.map((e) => KuesionerGejala.fromMap(e)).toList();
  }

  Future<KuesionerGejala?> getKuesionerBySkriningId(int skriningId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'kuesioner_gejala',
      where: 'skrining_id = ?',
      whereArgs: [skriningId],
    );
    if (result.isNotEmpty) {
      return KuesionerGejala.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateKuesionerGejala(KuesionerGejala kuesioner) async {
    Database db = await database;
    return await db.update(
      'kuesioner_gejala',
      kuesioner.toMap(),
      where: 'id = ?',
      whereArgs: [kuesioner.id],
    );
  }

  Future<int> deleteKuesionerGejala(int id) async {
    Database db = await database;
    return await db.delete('kuesioner_gejala', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD Riwayat Kepatuhan ==========
  Future<int> insertRiwayatKepatuhan(RiwayatKepatuhan riwayat) async {
    Database db = await database;
    return await db.insert('riwayat_kepatuhan', riwayat.toMap());
  }

  Future<RiwayatKepatuhan?> getRiwayatKepatuhanByDate(int userId, DateTime tanggal) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'riwayat_kepatuhan',
      where: 'user_id = ? AND tanggal_minum = ?',
      whereArgs: [userId, tanggal.toIso8601String()],
    );
    if (result.isNotEmpty) {
      return RiwayatKepatuhan.fromMap(result.first);
    }
    return null;
  }

  Future<List<RiwayatKepatuhan>> getRiwayatKepatuhanByMonth(
    int userId,
    int tahun,
    int bulan,
  ) async {
    Database db = await database;
    String startDate = DateTime(tahun, bulan, 1).toIso8601String();
    String endDate = DateTime(tahun, bulan + 1, 0).toIso8601String();
    
    List<Map<String, dynamic>> result = await db.query(
      'riwayat_kepatuhan',
      where: 'user_id = ? AND tanggal_minum >= ? AND tanggal_minum <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'tanggal_minum ASC',
    );
    return result.map((e) => RiwayatKepatuhan.fromMap(e)).toList();
  }

  Future<int> updateRiwayatKepatuhan(RiwayatKepatuhan riwayat) async {
    Database db = await database;
    return await db.update(
      'riwayat_kepatuhan',
      riwayat.toMap(),
      where: 'id = ?',
      whereArgs: [riwayat.id],
    );
  }

  Future<Map<String, int>> getKepatuhanBulanan(int userId, int tahun, int bulan) async {
    List<RiwayatKepatuhan> riwayat = await getRiwayatKepatuhanByMonth(userId, tahun, bulan);
    
    int total = riwayat.length;
    int patuh = riwayat.where((r) => r.status == 1).length;
    
    return {'total': total, 'patuh': patuh};
  }

  Future<int> deleteRiwayatKepatuhan(int id) async {
    Database db = await database;
    return await db.delete('riwayat_kepatuhan', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD Detail Sesi Riwayat ==========
  Future<int> insertDetailSesiRiwayat(SesiRiwayat detail) async {
    Database db = await database;
    return await db.insert('detail_sesi_riwayat', detail.toMap());
  }

  Future<List<SesiRiwayat>> getDetailSesiByRiwayatId(int riwayatKepatuhanId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'detail_sesi_riwayat',
      where: 'riwayat_kepatuhan_id = ?',
      whereArgs: [riwayatKepatuhanId],
    );
    return result.map((e) => SesiRiwayat.fromMap(e)).toList();
  }

  Future<SesiRiwayat?> getDetailSesiByRiwayatIdAndSesi(
    int riwayatKepatuhanId,
    String namaSesi,
  ) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'detail_sesi_riwayat',
      where: 'riwayat_kepatuhan_id = ? AND nama_sesi = ?',
      whereArgs: [riwayatKepatuhanId, namaSesi],
    );
    if (result.isNotEmpty) {
      return SesiRiwayat.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateDetailSesiRiwayat(SesiRiwayat detail) async {
    Database db = await database;
    return await db.update(
      'detail_sesi_riwayat',
      detail.toMap(),
      where: 'id = ?',
      whereArgs: [detail.id],
    );
  }

  Future<int> deleteDetailSesiRiwayat(int id) async {
    Database db = await database;
    return await db.delete('detail_sesi_riwayat', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDetailSesiByRiwayatId(int riwayatKepatuhanId) async {
    Database db = await database;
    return await db.delete(
      'detail_sesi_riwayat',
      where: 'riwayat_kepatuhan_id = ?',
      whereArgs: [riwayatKepatuhanId],
    );
  }

  // ========== Helper Methods ==========
  Future<Map<String, dynamic>> getDashboardData(int userId) async {
    // Ambil screening terbaru
    ScreeningMingguan? latestScreening = await getLatestScreening(userId);
    
    // Ambil efek samping 24 jam terakhir yang berat (skor = 3)
    DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
    List<EfekSampingPasien> efekBerat = await getEfekSampingByDateRange(
      userId,
      yesterday,
      DateTime.now(),
    );
    efekBerat = efekBerat.where((e) => e.skor == 3).toList();
    
    // Ambil kepatuhan bulan ini
    DateTime now = DateTime.now();
    Map<String, int> kepatuhan = await getKepatuhanBulanan(userId, now.year, now.month);
    
    // Ambil user
    User? user = await getUserById(userId);
    
  int totalHari = kepatuhan['total'] ?? 0;
  int totalPatuh = kepatuhan['patuh'] ?? 0;

  int persentase = 0;
  if (totalHari > 0) {
    persentase = (totalPatuh / totalHari * 100).round();
  }
    return {
      'user': user,
      'latestScreening': latestScreening,
      'adaEfekBerat': efekBerat.isNotEmpty,
      'totalPatuhBulanIni': totalPatuh,
      'totalHariBulanIni': totalHari,
      'persentaseKepatuhan': persentase,
    };
  }

  Future<void> insertOrUpdateKepatuhanHarian(
    int userId,
    DateTime tanggal,
    List<Map<String, dynamic>> sesiStatusList,
  ) async {
    // Cek apakah sudah ada riwayat untuk tanggal ini
    RiwayatKepatuhan? existing = await getRiwayatKepatuhanByDate(userId, tanggal);
    
    int riwayatId;
    if (existing == null) {
      // Buat riwayat baru
      RiwayatKepatuhan newRiwayat = RiwayatKepatuhan(
        userId: userId,
        tanggalMinum: tanggal,
        status: sesiStatusList.any((s) => s['status'] == 1) ? 1 : 0,
      );
      riwayatId = await insertRiwayatKepatuhan(newRiwayat);
    } else {
      riwayatId = existing.id!;
      // Update status utama (1 jika minimal 1 sesi sudah centang)
      int newStatus = sesiStatusList.any((s) => s['status'] == 1) ? 1 : 0;
      if (existing.status != newStatus) {
        existing.status = newStatus;
        await updateRiwayatKepatuhan(existing);
      }
    }
    
    // Hapus detail lama
    await deleteDetailSesiByRiwayatId(riwayatId);
    
    // Insert detail sesi baru
    for (var sesi in sesiStatusList) {
      SesiRiwayat detail = SesiRiwayat(
        riwayatKepatuhanId: riwayatId,
        namaSesi: sesi['nama_sesi'],
        status: sesi['status'],
        reminderDikirim: sesi['reminder_dikirim'] ?? 0,
      );
      await insertDetailSesiRiwayat(detail);
    }
  }

  Future<List<SesiRiwayat>> getKepatuhanHarian(int userId, DateTime tanggal) async {
    RiwayatKepatuhan? riwayat = await getRiwayatKepatuhanByDate(userId, tanggal);
    if (riwayat == null) return [];
    return await getDetailSesiByRiwayatId(riwayat.id!);
  }

  Future<void> close() async {
    Database db = await database;
    await db.close();
  }
}