import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';
import 'package:tbc_app/widgets/app_bottom_nav.dart';
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
  
  Map<String, List<String>> _efekSampingMap = {};
  bool _isLoading = true;
  List<Map<String, dynamic>> _riwayatPerubahan = [];
  bool _isLoadingHistory = true;
  
  // ScrollController untuk mengontrol scroll horizontal
  final ScrollController _scrollController = ScrollController();
  
  // Flag untuk menandai apakah sudah pernah scroll ke today
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
    _loadEfekSamping();
    _loadRiwayatPerubahan();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Fungsi untuk scroll ke tanggal tertentu
  void _scrollToDate(DateTime targetDate, List<DateTime> days) {
    if (!mounted) return;
    
    // Cari index tanggal target
    final targetIndex = days.indexWhere((date) => 
      date.year == targetDate.year && 
      date.month == targetDate.month && 
      date.day == targetDate.day
    );
    
    // Jika ditemukan, scroll ke posisi tersebut
    if (targetIndex != -1 && _scrollController.hasClients) {
      // Hitung offset scroll (lebar item 65 + padding 4 = 69)
      // plus padding horizontal 20
      final offset = (targetIndex * 69.0) - 20;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(offset > 0 ? offset : 0);
        }
      });
    }
  }

  Future<void> _loadEfekSamping() async {
    setState(() => _isLoading = true);
    
    final dbHelper = DatabaseHelper();
    int? userId = widget.userId ?? dbHelper.getCurrentUserId();
    
    if (userId != null) {
      _efekSampingMap = await dbHelper.getEfekSampingByMonth(userId, _selectedYear, _selectedMonth);
    }
    
    setState(() => _isLoading = false);
    _hasScrolledToToday = false; // Reset flag saat loading ulang
  }

  Future<void> _loadRiwayatPerubahan() async {
    setState(() => _isLoadingHistory = true);
    
    final dbHelper = DatabaseHelper();
    int? userId = widget.userId ?? dbHelper.getCurrentUserId();
    
    if (userId != null) {
      _riwayatPerubahan = await dbHelper.getRiwayatPerubahanObatByMonth(
        userId, 
        _selectedYear, 
        _selectedMonth
      );
    }
    setState(() => _isLoadingHistory = false);
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
    _hasScrolledToToday = false; // Reset flag saat ganti bulan
    await _loadEfekSamping();
    await _loadRiwayatPerubahan();
    
    // Setelah ganti bulan, pilih tanggal yang sesuai
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      setState(() {
        _selectedDate = now;
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

  List<String> _getGejalaForDate(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _efekSampingMap[dateStr] ?? [];
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
    final hasEfek = (date) => _getGejalaForDate(date).isNotEmpty;
    
    // Cek apakah bulan yang ditampilkan adalah bulan berjalan
    final isCurrentMonth = _selectedYear == today.year && _selectedMonth == today.month;

    // Scroll ke tanggal hari ini jika:
    // 1. Belum pernah scroll ke today
    // 2. Controller sudah tersedia
    // 3. Ini adalah bulan berjalan
    if (!_hasScrolledToToday && _scrollController.hasClients && isCurrentMonth) {
      _hasScrolledToToday = true;
      _scrollToDate(today, days);
    }

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

            // DATE LIST
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
                  final isChecked = hasEfek(date);
                  final isWarning = false;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: DateCard(
                        dayName: _getDayName(date.weekday),
                        date: date.day.toString(),
                        isSelected: isSelected,
                        isChecked: isChecked,
                        isWarning: isWarning,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // GEJALA HARI INI
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
                    Text(
                      "Gejala ${_selectedDate.day} ${_namaBulan[_selectedDate.month - 1]} $_selectedYear",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    ..._getGejalaForDate(_selectedDate).map((gejala) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SymptomCard(title: gejala),
                    )),
                    if (_getGejalaForDate(_selectedDate).isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Tidak ada gejala yang dicatat pada hari ini',
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
                    Row(
                      children: const [
                        Text(
                          "Lihat Semua",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                      ],
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

// DateCard (sama seperti sebelumnya)
class DateCard extends StatelessWidget {
  final String dayName;
  final String date;
  final bool isSelected;
  final bool isChecked;
  final bool isWarning;

  const DateCard({
    super.key,
    required this.dayName,
    required this.date,
    this.isSelected = false,
    this.isChecked = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight, width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(dayName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(date, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? AppColors.textPrimary : AppColors.textPrimary)),
          const SizedBox(height: 2),
          if (isChecked)
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18)
          else if (isWarning)
            const Icon(Icons.sync_problem, color: Colors.orange, size: 16)
          else
            Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5))),
        ],
      ),
    );
  }
}

// SymptomCard
class SymptomCard extends StatelessWidget {
  final String title;
  const SymptomCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardProfil,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ],
      ),
    );
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