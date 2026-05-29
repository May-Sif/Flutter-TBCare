import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';
import 'package:tbc_app/database/database_helper.dart';

class DetailEfekSampingPage extends StatefulWidget {
  final int? userId;
  final int? tahun;
  final int? bulan;

  const DetailEfekSampingPage({
    super.key, 
    this.userId,
    this.tahun,
    this.bulan,
  });

  @override
  State<DetailEfekSampingPage> createState() => _DetailEfekSampingPageState();
}

class _DetailEfekSampingPageState extends State<DetailEfekSampingPage> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  DateTime _selectedDate = DateTime.now();
  
  // Map untuk menyimpan efek samping per tanggal (dengan skor)
  Map<String, List<Map<String, dynamic>>> _efekSampingMap = {};
  
  // Map untuk menyimpan status kepatuhan obat per tanggal
  // true = semua sesi diminum, false = ada yang terlewat
  Map<String, bool> _kepatuhanMap = {};
  
  // Map untuk menyimpan jumlah sesi yang diminum per tanggal
  Map<String, int> _jumlahSesiDiminumMap = {};
  
  // Map untuk menyimpan total sesi obat per user
  int _totalSesiObat = 0;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _riwayatPerubahan = [];
  bool _isLoadingHistory = true;
  
  // Daftar efek samping yang tersedia (dari database)
  List<Map<String, dynamic>> _listEfekSamping = [];
  
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToToday = false;
  
  final List<String> _namaBulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.tahun ?? DateTime.now().year;
    _selectedMonth = widget.bulan ?? DateTime.now().month;
    _selectedDate = DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final dbHelper = DatabaseHelper();
    int? userId = widget.userId ?? dbHelper.getCurrentUserId();
    
    if (userId != null) {
      // Ambil total sesi obat untuk user ini
      _totalSesiObat = await dbHelper.getTotalSesiObat(userId);
      
      await Future.wait([
        _loadListEfekSamping(dbHelper),
        _loadEfekSamping(userId),
        _loadKepatuhanBulanan(userId),
        _loadRiwayatPerubahan(userId),
      ]);
    }
    
    setState(() => _isLoading = false);
    
    // Scroll ke tanggal hari ini
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasScrolledToToday) {
        final days = _getDaysInMonth();
        final today = DateTime.now();
        final isCurrentMonth = _selectedYear == today.year && _selectedMonth == today.month;
        
        if (isCurrentMonth) {
          _scrollToToday(days);
          _hasScrolledToToday = true;
        }
      }
    });
  }

  Future<void> _loadListEfekSamping(DatabaseHelper dbHelper) async {
    final result = await dbHelper.getAllListEfekSamping();
    setState(() {
      _listEfekSamping = result;
    });
  }

  Future<void> _loadEfekSamping(int userId) async {
    final dbHelper = DatabaseHelper();
    _efekSampingMap = await dbHelper.getEfekSampingPasienByMonth(userId, _selectedYear, _selectedMonth);
  }

  Future<void> _loadKepatuhanBulanan(int userId) async {
    final dbHelper = DatabaseHelper();
    final days = _getDaysInMonth();
    
    _kepatuhanMap.clear();
    _jumlahSesiDiminumMap.clear();
    
    for (var date in days) {
      final semuaDiminum = await dbHelper.isAllSesiObatDiminum(userId, date);
      _kepatuhanMap[_getDateKey(date)] = semuaDiminum;
      
      final jumlahDiminum = await dbHelper.getJumlahSesiDiminum(userId, date);
      _jumlahSesiDiminumMap[_getDateKey(date)] = jumlahDiminum;
    }
  }

  Future<void> _loadRiwayatPerubahan(int userId) async {
    final dbHelper = DatabaseHelper();
    _riwayatPerubahan = await dbHelper.getRiwayatPerubahanObatByMonth(
      userId, 
      _selectedYear, 
      _selectedMonth
    );
    setState(() => _isLoadingHistory = false);
  }

  void _scrollToToday(List<DateTime> days) {
    if (!mounted || !_scrollController.hasClients) return;
    
    final today = DateTime.now();
    final todayIndex = days.indexWhere((date) => 
      date.year == today.year && 
      date.month == today.month && 
      date.day == today.day
    );
    
    if (todayIndex != -1) {
      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth = 69.0;
      final targetOffset = (todayIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetOffset > 0 ? targetOffset : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _changeMonth(int delta) async {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      }
    });
    
    _hasScrolledToToday = false;
    
    final dbHelper = DatabaseHelper();
    int? userId = widget.userId ?? dbHelper.getCurrentUserId();
    
    if (userId != null) {
      setState(() => _isLoading = true);
      await Future.wait([
        _loadEfekSamping(userId),
        _loadKepatuhanBulanan(userId),
        _loadRiwayatPerubahan(userId),
      ]);
      setState(() => _isLoading = false);
    }
    
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      setState(() {
        _selectedDate = now;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final days = _getDaysInMonth();
          _scrollToToday(days);
        }
      });
    } else {
      setState(() {
        _selectedDate = DateTime(_selectedYear, _selectedMonth, 1);
      });
    }
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    final lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0);
    final days = <DateTime>[];
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_selectedYear, _selectedMonth, i));
    }
    return days;
  }

  List<Map<String, dynamic>> _getEfekSampingForDate(DateTime date) {
    final dateStr = _getDateKey(date);
    return _efekSampingMap[dateStr] ?? [];
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Cek apakah semua sesi obat diminum
  bool _isAllObatDiminum(DateTime date) {
    return _kepatuhanMap[_getDateKey(date)] ?? false;
  }
  
  // Dapatkan jumlah sesi yang diminum
  int _getJumlahSesiDiminum(DateTime date) {
    return _jumlahSesiDiminumMap[_getDateKey(date)] ?? 0;
  }

  // Dapatkan nama efek samping berdasarkan ID
  String _getNamaEfekSamping(int id) {
    final efek = _listEfekSamping.firstWhere(
      (e) => e['id'] == id,
      orElse: () => {'nama_efek_samping': 'Tidak diketahui'},
    );
    return efek['nama_efek_samping'] as String;
  }

  // Dapatkan warna berdasarkan skor
  Color _getSkorColor(int skor) {
    switch (skor) {
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  // Dapatkan label skor
  String _getSkorLabel(int skor) {
    switch (skor) {
      case 1: return 'Ringan';
      case 2: return 'Sedang';
      case 3: return 'Berat';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final days = _getDaysInMonth();
    final today = DateTime.now();
    final isCurrentMonth = _selectedYear == today.year && _selectedMonth == today.month;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surface,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.arrow_back, size: 24, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "DETAIL EFEK SAMPING",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // BULAN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _changeMonth(-1),
                    child: const Icon(Icons.chevron_left, size: 28, color: AppColors.primary),
                  ),
                  Text(
                    "${_namaBulan[_selectedMonth - 1]} $_selectedYear",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => _changeMonth(1),
                    child: const Icon(Icons.chevron_right, size: 28, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // DATE LIST - Menampilkan status KEPATUHAN OBAT
            SizedBox(
              height: 100,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final date = days[index];
                  final isSelected = _selectedDate.year == date.year && 
                                     _selectedDate.month == date.month && 
                                     _selectedDate.day == date.day;
                  final isAllObatDiminum = _isAllObatDiminum(date);
                  final jumlahDiminum = _getJumlahSesiDiminum(date);
                  final isToday = date.year == today.year && 
                                  date.month == today.month && 
                                  date.day == today.day;
                  
                  // Tentukan status kepatuhan untuk ditampilkan di DateCard
                  KepatuhanStatus status;
                  if (isAllObatDiminum) {
                    status = KepatuhanStatus.selesai; // Centang hijau
                  } else if (jumlahDiminum > 0) {
                    status = KepatuhanStatus.sebagian; // Warning orange (ada yang diminum tapi belum semua)
                  } else {
                    status = KepatuhanStatus.kosong; // Belum ada yang diminum
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: DateCard(
                        dayName: _getDayName(date.weekday),
                        date: date.day.toString(),
                        isSelected: isSelected,
                        status: status,
                        isToday: isToday,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // EFEK SAMPING HARI INI (dengan skor)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Efek Samping ${_selectedDate.day} ${_namaBulan[_selectedDate.month - 1]} $_selectedYear",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        // Tampilkan status kepatuhan obat hari ini
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isAllObatDiminum(_selectedDate) 
                                ? AppColors.success.withOpacity(0.1) 
                                : (_getJumlahSesiDiminum(_selectedDate) > 0
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isAllObatDiminum(_selectedDate) 
                                    ? Icons.check_circle 
                                    : (_getJumlahSesiDiminum(_selectedDate) > 0
                                        ? Icons.warning_amber_rounded
                                        : Icons.access_time),
                                size: 14,
                                color: _isAllObatDiminum(_selectedDate) 
                                    ? AppColors.success 
                                    : (_getJumlahSesiDiminum(_selectedDate) > 0
                                        ? Colors.orange
                                        : Colors.grey),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isAllObatDiminum(_selectedDate) 
                                    ? "Patuh (${_getJumlahSesiDiminum(_selectedDate)}/$_totalSesiObat)" 
                                    : (_getJumlahSesiDiminum(_selectedDate) > 0
                                        ? "Sebagian (${_getJumlahSesiDiminum(_selectedDate)}/$_totalSesiObat)"
                                        : "Belum minum obat"),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _isAllObatDiminum(_selectedDate) 
                                      ? AppColors.success 
                                      : (_getJumlahSesiDiminum(_selectedDate) > 0
                                          ? Colors.orange
                                          : Colors.grey),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    
                    // Tampilkan daftar efek samping dengan skor
                    ..._getEfekSampingForDate(_selectedDate).map((efek) {
                      final efekSampingId = efek['efek_samping_id'] as int;
                      final namaEfek = _getNamaEfekSamping(efekSampingId);
                      final skor = efek['skor'] as int;
                      final keterangan = efek['keterangan'] ?? '';
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: EfekSampingCard(
                          namaEfek: namaEfek,
                          skor: skor,
                          skorLabel: _getSkorLabel(skor),
                          skorColor: _getSkorColor(skor),
                          keterangan: keterangan,
                        ),
                      );
                    }),
                    
                    if (_getEfekSampingForDate(_selectedDate).isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Tidak ada efek samping yang dicatat pada hari ini',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // RIWAYAT PERUBAHAN OBAT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Riwayat Perubahan Obat",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigasi ke halaman riwayat perubahan obat lengkap
                      },
                      child: Row(
                        children: const [
                          Text(
                            "Lihat Semua",
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _isLoadingHistory
                          ? const Center(child: CircularProgressIndicator())
                          : _riwayatPerubahan.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Belum ada riwayat perubahan obat',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _riwayatPerubahan.length,
                                  itemBuilder: (context, index) {
                                    final item = _riwayatPerubahan[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: HistoryCard(
                                        date: _formatTanggal(item['tanggal']),
                                        title: "${item['obat_lama']} → ${item['obat_baru']}",
                                        description: item['alasan'] ?? 'Tidak ada keterangan',
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[weekday - 1];
  }

  String _formatTanggal(String tanggal) {
    final parts = tanggal.split('-');
    if (parts.length != 3) return tanggal;
    return '${parts[2]} ${_getNamaBulan(int.parse(parts[1]))} ${parts[0]}';
  }

  String _getNamaBulan(int bulan) {
    const namaBulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return namaBulan[bulan - 1];
  }
}

// Enum untuk status kepatuhan
enum KepatuhanStatus {
  selesai,    // Centang hijau (semua sesi diminum)
  sebagian,   // Warning orange (ada yang diminum tapi belum semua)
  kosong,     // Lingkaran kosong (belum ada yang diminum)
}

// DateCard - untuk menampilkan status KEPATUHAN OBAT per hari
class DateCard extends StatelessWidget {
  final String dayName;
  final String date;
  final bool isSelected;
  final KepatuhanStatus status;
  final bool isToday;

  const DateCard({
    super.key,
    required this.dayName,
    required this.date,
    this.isSelected = false,
    this.status = KepatuhanStatus.kosong,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? AppColors.primary : AppColors.primaryLight, 
          width: isToday ? 2 : 0.8,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayName, 
            style: TextStyle(
              fontSize: 12, 
              color: isToday ? AppColors.primary : Colors.grey,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date, 
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: isSelected ? AppColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          _buildStatusIcon(),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case KepatuhanStatus.selesai:
        // Centang hijau - semua sesi obat diminum
        return const Icon(Icons.check_circle, color: AppColors.success, size: 18);
        
      case KepatuhanStatus.sebagian:
        // Warning orange - ada yang diminum tapi belum semua
        return const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18);
        
      case KepatuhanStatus.kosong:
        // Lingkaran kosong - belum ada yang diminum
        if (isToday) {
          return Container(
            width: 16, 
            height: 16, 
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              color: AppColors.primary,
            ),
            child: const Icon(Icons.circle, size: 8, color: Colors.white),
          );
        } else {
          return Container(
            width: 16, 
            height: 16, 
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
          );
        }
    }
  }
}

// EfekSampingCard - untuk menampilkan EFEK SAMPING dengan skor
class EfekSampingCard extends StatelessWidget {
  final String namaEfek;
  final int skor;
  final String skorLabel;
  final Color skorColor;
  final String keterangan;

  const EfekSampingCard({
    super.key,
    required this.namaEfek,
    required this.skor,
    required this.skorLabel,
    required this.skorColor,
    this.keterangan = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardProfil,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: skorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForEfek(namaEfek),
                  color: skorColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaEfek,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (keterangan.isNotEmpty)
                      Text(
                        keterangan,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: skorColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: skorColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      skorLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: skorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForEfek(String namaEfek) {
    if (namaEfek.contains('Mual')) return Icons.sick;
    if (namaEfek.contains('Gatal')) return Icons.sanitizer;
    if (namaEfek.contains('Pusing')) return Icons.water_damage;
    if (namaEfek.contains('Nyeri')) return Icons.favorite_border;
    if (namaEfek.contains('Demam')) return Icons.thermostat;
    if (namaEfek.contains('Kuning')) return Icons.warning_amber_rounded;
    if (namaEfek.contains('Penglihatan')) return Icons.visibility_off;
    if (namaEfek.contains('Dahak')) return Icons.water_drop;
    if (namaEfek.contains('Kejang')) return Icons.medical_services;
    if (namaEfek.contains('Urine')) return Icons.water_drop;
    if (namaEfek.contains('Perdarahan')) return Icons.bloodtype;
    if (namaEfek.contains('Nafsu')) return Icons.restaurant;
    return Icons.medication;
  }
}

// HistoryCard
class HistoryCard extends StatelessWidget {
  final String date;
  final String title;
  final String description;
  const HistoryCard({super.key, required this.date, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.cardProfil, borderRadius: BorderRadius.circular(20)),
            child: Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 12, height: 1.3, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}