import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../pages/detail_efek_samping.dart';
import '../providers/home_provider.dart';
import '../theme.dart';
import '../widgets/app_bottom_nav.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with RouteAware {
  int _navIndex = 1; 
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  Map<String, int> _kepatuhanBulan = {};
  final DatabaseHelper _db = DatabaseHelper();
  int? _userId;

  final List<String> _semuaEfek = [
    'muntah', 'demam', 'pusing', 'urine gelap',
    'nyeri sendi', 'kejang', 'mimisan',
  ];
  final Set<String> _efekDipilih = {};

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadSesiStatus();
    _loadKepatuhanBulan();
  }

  Future<void> _loadSesiStatus() async {
    if (_userId == null) return;
    final today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    final db = await _db.database;
    final jadwal = context.read<HomeProvider>().jadwalObat;
    final newStatus = <int, bool>{};
    for (int i = 0; i < jadwal.length; i++) {
      final rows = await db.query(
        'sesi_kepatuhan',
        where: 'user_id = ? AND tanggal = ? AND sesi_index = ?',
        whereArgs: [_userId, today, i],
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
    final bulanStr =
        '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}';
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
        onTap: (i) {
          if (i == 0) {
            Navigator.of(context).pop();
          } else {
            setState(() => _navIndex = i);
          }
        },
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
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
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
    final tanggalStr =
        '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._semuaEfek.map((e) => _chipEfek(e)),
              GestureDetector(
                onTap: _showTambahEfekDialog,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(Icons.add,
                      size: 20, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _simpanLaporan,
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

  Widget _chipEfek(String efek) {
    final dipilih = _efekDipilih.contains(efek);
    return GestureDetector(
      onTap: () => setState(() =>
          dipilih ? _efekDipilih.remove(efek) : _efekDipilih.add(efek)),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: dipilih ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  dipilih ? AppColors.textPrimary : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(efek,
                style: TextStyle(
                    fontSize: 12,
                    color: dipilih
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
            if (dipilih) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () =>
                    setState(() => _efekDipilih.remove(efek)),
                child: const Icon(Icons.close,
                    size: 14, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _simpanLaporan() async{
    final gejalaList = _efekDipilih.toList();
    final dbHelper = DatabaseHelper();
    int? userId = _db.getCurrentUserId();
    
    if (userId != null) {
      final tanggal = DateTime.now().toIso8601String().split('T').first;
      await dbHelper.saveEfekSamping(userId, tanggal, gejalaList);
    }

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
                'Skrining harian berhasil disimpan!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              if (gejalaList.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Gejala yang dicatat:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 6),
                ...gejalaList.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(g, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    ],
                  ),
                )),
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
                    setState(() => _efekDipilih.clear());
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
    // Ambil userId dari DatabaseHelper
    final dbHelper = DatabaseHelper();
    int? userId = dbHelper.getCurrentUserId();
    
    // Navigasi ke halaman detail efek samping
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
      // Ketika kembali dari halaman detail, reload data
      _loadSesiStatus();
      _loadKepatuhanBulan();
    });
  }

  void _showTambahEfekDialog() {
    final controller = TextEditingController();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Efek Samping',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    child: const Text('Kembali'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {
                      final val = controller.text.trim().toLowerCase();
                      if (val.isNotEmpty && !_semuaEfek.contains(val)) {
                        setState(() {
                          _semuaEfek.add(val);
                          _efekDipilih.add(val);
                        });
                      }
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    child: const Text('Tambah'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}