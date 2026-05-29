import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';
import 'package:tbc_app/widgets/app_bottom_nav.dart';
import 'package:tbc_app/pages/calendar_page.dart';
import 'package:tbc_app/pages/profile_page.dart';
import 'package:tbc_app/pages/home_page.dart';
import 'package:tbc_app/database/database_helper.dart';

class RiwayatKesehatanPage extends StatefulWidget {
  final int? userId;

  const RiwayatKesehatanPage({super.key, this.userId});

  @override
  State<RiwayatKesehatanPage> createState() => _RiwayatKesehatanPageState();
}

class _RiwayatKesehatanPageState extends State<RiwayatKesehatanPage> {
  int _currentIndex = 2;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _screeningHistory = [];
  int _totalPatuh = 0;
  int _totalTerlewat = 0;
  double _kepatuhanPersen = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final userId = widget.userId ?? _dbHelper.getCurrentUserId();
    
    if (userId != null) {
      final user = await _dbHelper.getUserById(userId);
      if (user != null) {
        setState(() {
          _userData = user;
        });
      }
      
      await _loadScreeningHistory(userId);
      await _calculateKepatuhan(userId);
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadScreeningHistory(int userId) async {
    try {
      final db = await _dbHelper.database;
      
      // Cek apakah tabel ada
      final tables = await db.query('sqlite_master', 
        where: 'type = ? AND name = ?', 
        whereArgs: ['table', 'screening_mingguan']
      );
      
      if (tables.isEmpty) {
        // Buat tabel jika belum ada
        await db.execute('''
          CREATE TABLE IF NOT EXISTS screening_mingguan (
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
        setState(() {
          _screeningHistory = [];
        });
        return;
      }
      
      final result = await db.query(
        'screening_mingguan',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'minggu_ke DESC',
        limit: 4,
      );
      
      setState(() {
        _screeningHistory = result;
      });
    } catch (e) {
      print('Error loading screening history: $e');
      setState(() {
        _screeningHistory = [];
      });
    }
  }

  Future<void> _calculateKepatuhan(int userId) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      
      // Ambil tanggal mulai pengobatan
      DateTime? tglMulai;
      final user = await _dbHelper.getUserById(userId);
      if (user != null && user['tanggal_diagnosis'] != null) {
        tglMulai = _parseDateSafely(user['tanggal_diagnosis']);
      }
      
      if (tglMulai == null) {
        setState(() {
          _totalPatuh = 0;
          _totalTerlewat = 0;
          _kepatuhanPersen = 0;
        });
        return;
      }
      
      // Ambil jadwal obat user
      final jadwalObat = await db.query(
        'jadwal_obat',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      final int sesiPerHari = jadwalObat.length;
      
      // Hitung total hari
      final int totalHari = now.difference(tglMulai).inDays + 1;
      
      // Ambil data kepatuhan
      final String startDate = tglMulai.toIso8601String().split('T').first;
      final String todayStr = now.toIso8601String().split('T').first;
      
      final patuhRecords = await db.query(
        'sesi_kepatuhan',
        where: 'user_id = ? AND tanggal >= ? AND tanggal <= ? AND status = 1',
        whereArgs: [userId, startDate, todayStr],
      );
      
      // Hitung hari tuntas
      int totalHariTuntas = 0;
      
      for (int i = 0; i < totalHari; i++) {
        final tanggalLoop = DateTime(tglMulai.year, tglMulai.month, tglMulai.day + i);
        final tanggalStr = tanggalLoop.toIso8601String().split('T').first;
        
        int patuhPadaHariIni = 0;
        for (var record in patuhRecords) {
          final recordTanggal = record['tanggal']?.toString() ?? '';
          if (recordTanggal == tanggalStr) {
            patuhPadaHariIni++;
          }
        }
        
        if (patuhPadaHariIni == sesiPerHari && sesiPerHari > 0) {
          totalHariTuntas++;
        }
      }
      
      if (mounted) {
        setState(() {
          _totalPatuh = totalHariTuntas;
          _totalTerlewat = totalHari - totalHariTuntas;
          _kepatuhanPersen = totalHari > 0 ? totalHariTuntas / totalHari : 0;
        });
      }
    } catch (e, stacktrace) {
      print('ERROR di _calculateKepatuhan: $e');
      print('Stacktrace: $stacktrace');
      if (mounted) {
        setState(() {
          _totalPatuh = 0;
          _totalTerlewat = 0;
          _kepatuhanPersen = 0;
        });
      }
    }
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;
    
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            email: '',
            name: _userData['nama'] ?? '',
            userId: widget.userId,
          ),
        ),
      );
      return;
    }
    
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CalendarPage()),
      );
      return;
    }
    
    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilPage(userId: widget.userId),
        ),
      );
      return;
    }
    
    setState(() => _currentIndex = index);
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ON_TRACK':
        return 'ON TRACK';
      case 'PERLU_PEMANTAUAN':
        return 'PERLU PANTAUAN';
      case 'WASPADA':
        return 'WASPADA';
      case 'RISIKO_TINGGI':
        return 'RISIKO TINGGI';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ON_TRACK':
        return AppColors.success;
      case 'PERLU_PEMANTAUAN':
        return AppColors.warning;
      case 'WASPADA':
        return AppColors.error;
      case 'RISIKO_TINGGI':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  // Helper function untuk parse tanggal dengan aman
  DateTime? _parseDateSafely(dynamic dateValue) {
    if (dateValue == null) return null;
    
    try {
      String dateString = dateValue.toString();
      
      // Jika format sudah YYYY-MM-DD
      if (dateString.contains('-') && dateString.length == 10) {
        return DateTime.parse(dateString);
      }
      
      // Jika format DD/MM/YYYY
      if (dateString.contains('/')) {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
      
      // Coba parse langsung
      return DateTime.parse(dateString);
    } catch (e) {
      print('Error parsing date: $dateValue - $e');
      return null;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return "${date.day} ${_getMonthName(date.month)} ${date.year}";
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'RIWAYAT KESEHATAN',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  _summaryCard(),
                  const SizedBox(height: 16),
                  _phaseCard(),
                  const SizedBox(height: 16),
                  _history(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Halo, ${_userData['nama'] ?? 'Pasien'}",
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Pantau kemajuan pengobatan dan kondisi fisik Anda secara berkala.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _summaryCard() {
    final bool hasData = _totalPatuh > 0 || _totalTerlewat > 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Text(
            "RINGKASAN KEPATUHAN",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (!hasData) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 8),
                  Text(
                    "Belum ada data kepatuhan",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    "Mulai minum obat untuk melihat ringkasan",
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ] else ...[
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    value: _kepatuhanPersen,
                    strokeWidth: 10,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "${(_kepatuhanPersen * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text(
                      "Patuh",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      "$_totalPatuh",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const Text("Hari Tuntas",
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "$_totalTerlewat",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const Text("Terlewat",
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Total Hari: ${_totalPatuh + _totalTerlewat}",
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _phaseCard() {
    // Parse tanggal diagnosis dengan aman
    DateTime? tglDiagnosis;
    final tglDiagnosisRaw = _userData['tanggal_diagnosis'];
    
    if (tglDiagnosisRaw != null) {
      tglDiagnosis = _parseDateSafely(tglDiagnosisRaw);
    }
    
    final now = DateTime.now();
    final int totalHariPengobatan = 180; // 6 bulan × 30 hari
    int hariTerlewati = 0;
    
    if (tglDiagnosis != null) {
      hariTerlewati = now.difference(tglDiagnosis).inDays;
      hariTerlewati = hariTerlewati.clamp(0, totalHariPengobatan);
    }
    
    final double progres = hariTerlewati / totalHariPengobatan;
    final int bulanBerjalan = (hariTerlewati / 30).floor() + 1;
    final tglSelesai = tglDiagnosis?.add(Duration(days: totalHariPengobatan));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "FASE PENGOBATAN (6 BULAN)",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text("$bulanBerjalan Bulan Berjalan"),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progres,
              minHeight: 10,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tglDiagnosis != null 
                    ? "Mulai: ${_formatDate(tglDiagnosis)}"
                    : "Mulai: -",
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                tglSelesai != null 
                    ? "Estimasi: ${_formatDate(tglSelesai)}"
                    : "Estimasi: -",
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Hari ke-$hariTerlewati dari $totalHariPengobatan",
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _history() {
    if (_screeningHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            "Belum ada riwayat screening",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "HISTORI SCREENING MINGGUAN",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ..._screeningHistory.map((screening) {
          final tglScreening = _parseDateSafely(screening['tanggal_screening']);
          return _historyCard(
            "Minggu ${screening['minggu_ke']}",
            _getStatusText(screening['status']),
            _getStatusColor(screening['status']),
            screening['kesimpulan_hasil'] ?? "Tidak ada catatan",
            tglScreening != null ? _formatDate(tglScreening) : "-",
          );
        }),
      ],
    );
  }

  Widget _historyCard(
    String title,
    String status,
    Color color,
    String desc,
    String date,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(desc,
              style: const TextStyle(color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(date,
              style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}