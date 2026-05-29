import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../pages/detail_efek_samping.dart';
import '../providers/home_provider.dart';
import '../theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../pages/riwayat_kesehatan_page.dart';
import '../pages/profile_page.dart';
import '../pages/home_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _navIndex = 1; 
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  Map<String, int> _kepatuhanBulan = {};
  final DatabaseHelper _db = DatabaseHelper();
  int? _userId;

  // Daftar efek samping dengan skor BAWAAN (skor sudah ditentukan, tidak bisa dipilih user)
  final List<Map<String, dynamic>> _daftarEfekSamping = [
    {'id': 1, 'nama': 'Mual / Muntah', 'skor': 1},
    {'id': 2, 'nama': 'Gatal / Ruam kulit', 'skor': 1},
    {'id': 3, 'nama': 'Pusing / Sakit kepala', 'skor': 1},
    {'id': 4, 'nama': 'Nyeri sendi', 'skor': 1},
    {'id': 5, 'nama': 'Kurang nafsu makan', 'skor': 1},
    {'id': 6, 'nama': 'Demam (tanpa sebab jelas)', 'skor': 2},
    {'id': 7, 'nama': 'Urine berwarna gelap', 'skor': 2},
    {'id': 8, 'nama': 'Kuning (kulit/mata menguning)', 'skor': 3},
    {'id': 9, 'nama': 'Gangguan penglihatan', 'skor': 3},
    {'id': 10, 'nama': 'Dahak berdarah', 'skor': 3},
    {'id': 11, 'nama': 'Kejang-kejang', 'skor': 3},
    {'id': 12, 'nama': 'Perdarahan (gusi/mimisan/memar)', 'skor': 3},
  ];
  
  // Set untuk menyimpan ID efek samping yang dipilih (tanpa skor, karena skor sudah ditentukan)
  Set<int> _efekDipilihIds = {};
  
  final Map<int, bool> _sesiStatus = {};

  @override
  void initState() {
    super.initState();
    _userId = _db.getCurrentUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<HomeProvider>().loadData();
      await _loadKepatuhanBulan();
      await _loadSesiStatus();
    });
  }

  Future<void> _loadSesiStatus() async {
    if (_userId == null) return;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final db = await _db.database;
    final jadwal = context.read<HomeProvider>().jadwalObat;
    final newStatus = <int, bool>{};
    for (int i = 0; i < jadwal.length; i++) {
      final rows = await db.query(
        'sesi_kepatuhan',
        where: 'user_id = ? AND tanggal = ? AND sesi_index = ?',
        whereArgs: [_userId, todayStr, i],
      );
      newStatus[i] = rows.isNotEmpty && (rows.first['status'] as int? ?? 0) == 1;
    }
    setState(() {
      _sesiStatus.clear();
      _sesiStatus.addAll(newStatus);
    });
  }

  Future<void> _loadKepatuhanBulan() async {
    if (_userId == null) return;
    final db = await _db.database;
    final bulanStr = '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}';
    final rows = await db.query(
      'kepatuhan',
      where: 'user_id = ? AND tanggal LIKE ?',
      whereArgs: [_userId, '$bulanStr%'],
    );
    final map = <String, int>{};
    for (final r in rows) {
      map[r['tanggal'] as String] = r['status'] as int? ?? 0;
    }
    setState(() => _kepatuhanBulan = map);
  }

  void _onNavBarTap(int index) {
    if (index == _navIndex) return;
    
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            email: '',
            name: '',
            userId: _userId,
          ),
        ),
      );
      return;
    }
    
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RiwayatKesehatanPage(userId: _userId),
        ),
      );
      return;
    }
    
    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilPage(userId: _userId),
        ),
      );
      return;
    }
    
    setState(() => _navIndex = index);
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
          'JADWAL MINUM OBAT',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKalender(),
                const SizedBox(height: 20),
                _buildObatHariIni(provider),
                const SizedBox(height: 20),
                _buildEfekSamping(),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildKalender() {
    const namaHari = ['M', 'S', 'S', 'R', 'K', 'J', 'S'];
    const namaBulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final startOffset = firstDay.weekday - 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${namaBulan[_focusedMonth.month]} ${_focusedMonth.year}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      setState(() => _focusedMonth = DateTime(
                          _focusedMonth.year, _focusedMonth.month - 1));
                      await _loadKepatuhanBulan();
                    },
                    child: const Icon(Icons.chevron_left,
                        size: 20, color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () async {
                      setState(() => _focusedMonth = DateTime(
                          _focusedMonth.year, _focusedMonth.month + 1));
                      await _loadKepatuhanBulan();
                    },
                    child: const Icon(Icons.chevron_right,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: namaHari
                .map((h) => Expanded(
                      child: Center(
                        child: Text(h,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          _buildGridTanggal(daysInMonth, startOffset),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendaDot(AppColors.success, 'Tepat'),
              const SizedBox(width: 16),
              _legendaDot(AppColors.error, 'Terlewat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendaDot(Color color, String label) => Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      );

  Widget _buildGridTanggal(int daysInMonth, int startOffset) {
    final cells = <Widget>[];
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox(height: 36));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(_tanggalCell(d));
    }

    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final end = (i + 7 > cells.length) ? cells.length : i + 7;
      final slice = List<Widget>.from(cells.sublist(i, end));
      while (slice.length < 7) {
        slice.add(const SizedBox.shrink());
      }
      rows.add(Row(
          children: slice.map((c) => Expanded(child: c)).toList()));
    }
    return Column(children: rows);
  }

  Widget _tanggalCell(int day) {
    final tanggalStr = '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    final status = _kepatuhanBulan[tanggalStr];
    final isTeratur = status == 1;
    final tanggalIni = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final isToday = tanggalIni.isAtSameMomentAs(todayOnly);
    final isTerlewat = isToday && !isTeratur;
    final isSelected = day == _selectedDate.day &&
        _focusedMonth.month == _selectedDate.month &&
        _focusedMonth.year == _selectedDate.year;

    Color? bgCell;
    Color textColor = AppColors.textPrimary;
    Border? border;

    if (isTerlewat) {
      bgCell = AppColors.error;
      textColor = Colors.white;
    } else if (isTeratur) {
      border = Border.all(color: AppColors.success, width: 1.5);
      textColor = AppColors.success;
    } else if (isSelected) {
      border = Border.all(color: AppColors.primary, width: 1.5);
      textColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedDate =
          DateTime(_focusedMonth.year, _focusedMonth.month, day)),
      child: Container(
        height: 34,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgCell,
          shape: BoxShape.circle,
          border: border,
        ),
        child: Center(
          child: Text('$day',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
        ),
      ),
    );
  }

  Widget _buildObatHariIni(HomeProvider provider) {
    final jadwal = provider.jadwalObat;

    final belumDiminum = List.generate(
      jadwal.length,
      (i) => _sesiStatus[i] ?? false,
    ).where((s) => !s).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Obat Hari Ini',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            Text(
              '$belumDiminum Tersisa',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (jadwal.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('Belum ada jadwal obat.',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...List.generate(jadwal.length, (i) {
            final obat = jadwal[i];
            final sudah = _sesiStatus[i] ?? false;
            return _kartuObat(
              index: i,
              namaObat: obat['namaObat'] ?? '',
              waktu: obat['waktu'] ?? '',
              waktuMakan: obat['waktuMakan'] ?? '',
              sudahDiminum: sudah,
            );
          }),
      ],
    );
  }

  Widget _kartuObat({
    required int index,
    required String namaObat,
    required String waktu,
    required String waktuMakan,
    required bool sudahDiminum,
  }) {
    final iconBg = sudahDiminum
        ? AppColors.success.withOpacity(0.12)
        : AppColors.error.withOpacity(0.10);
    final iconColor =
        sudahDiminum ? AppColors.success : const Color(0xFFFF9800);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.medication_rounded,
              color: iconColor, size: 24),
        ),
        title: Text(namaObat,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary)),
        subtitle: Text(
          '$waktu • $waktuMakan',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: _statusBadge(
          sudahDiminum: sudahDiminum,
        ),
      ),
    );
  }

  Widget _statusBadge({required bool sudahDiminum}) {
    if (sudahDiminum) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('SUDAH DIMINUM',
            style: TextStyle(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('BELUM DIMINUM',
          style: TextStyle(
              color: AppColors.error,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }

  // ========== EFEK SAMPING (TANPA DIALOG SKOR) ==========
  Widget _buildEfekSamping() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardObat,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Catat Efek Samping',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Text(
            'Pilih efek samping yang dirasakan hari ini:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._daftarEfekSamping.map((efek) => _chipEfek(efek)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _simpanLaporanEfekSamping,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Simpan Laporan',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _periksaDetail,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(
                    color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Periksa Detail',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  // Chip efek samping - TANPA dialog pilihan skor (skor sudah ditentukan)
  Widget _chipEfek(Map<String, dynamic> efek) {
    final int id = efek['id'];
    final String nama = efek['nama'];
    final bool dipilih = _efekDipilihIds.contains(id);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (dipilih) {
            _efekDipilihIds.remove(id);
          } else {
            _efekDipilihIds.add(id);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: dipilih ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dipilih ? AppColors.textPrimary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nama,
              style: TextStyle(
                fontSize: 12,
                color: dipilih ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (dipilih) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _efekDipilihIds.remove(id)),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _simpanLaporanEfekSamping() async {
    if (_efekDipilihIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu efek samping')),
      );
      return;
    }

    final dbHelper = DatabaseHelper();
    int? userId = _db.getCurrentUserId();
    
    if (userId != null) {
      final today = DateTime.now();
      
      // Simpan efek samping dengan skor BAWAAN (tidak perlu user pilih)
      for (var efekId in _efekDipilihIds) {
        // Cari efek samping berdasarkan ID untuk mendapatkan skor
        final efek = _daftarEfekSamping.firstWhere((e) => e['id'] == efekId);
        final skor = efek['skor'] as int;
        
        await dbHelper.saveEfekSampingPasien(
          userId, 
          today, 
          efekId, 
          skor, 
          null // keterangan opsional
        );
      }
    }

    // Tampilkan dialog sukses
    final efekTerpilih = _daftarEfekSamping.where((e) => _efekDipilihIds.contains(e['id'])).toList();
    
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.cardObat,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Laporan Efek Samping Berhasil Disimpan!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              if (efekTerpilih.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Efek samping yang dicatat:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 6),
                ...efekTerpilih.map((efek) {
                  final nama = efek['nama'];
                  final skor = efek['skor'];
                  final level = skor == 1 ? 'Ringan' : (skor == 2 ? 'Sedang' : 'Berat');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('$nama ($level)', 
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
              const Text(
                'Terima kasih sudah rutin memantau kondisi Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _efekDipilihIds.clear());
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _periksaDetail() async {
    final dbHelper = DatabaseHelper();
    int? userId = dbHelper.getCurrentUserId();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailEfekSampingPage(
          userId: userId,
          tahun: _focusedMonth.year,
          bulan: _focusedMonth.month,
        ),
      ),
    ).then((_) {
      _loadSesiStatus();
      _loadKepatuhanBulan();
    });
  }
}