import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';
import 'package:tbc_app/widgets/app_bottom_nav.dart';
import 'package:tbc_app/database/database_helper.dart';
import 'package:tbc_app/pages/profile_page.dart';
import 'package:tbc_app/pages/calendar_page.dart';
import 'package:tbc_app/pages/riwayat_kesehatan_page.dart';
import 'package:tbc_app/pages/form_screening.dart';
import 'package:tbc_app/pages/detail_efek_samping.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  final String name;
  final String? photoUrl;
  final int? userId;

  const HomeScreen({
    super.key,
    required this.email,
    this.name = '',
    this.photoUrl,
    this.userId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  
  bool _adaEfekSamping = false;
  String _latestEfekSamping = '';
  String _latestEfekSampingDate = '';
  int _latestEfekSampingSkor = 0;
  
  String _userName = '';
  String _userEmail = '';
  
  List<Map<String, dynamic>> _jadwalObat = [];
  List<bool> _sesiStatus = [];
  List<bool> _isTransitioning = [];
  int _currentSesiIndex = 0;
  PageController _pageController = PageController();
  Timer? _autoSwipeTimer;
  
  bool _sudahIsiSkrining = false;
  List<String> _gejalaTinggi = [];
  List<String> _gejalaSedang = [];
  
  double _beratBadan = 0;
  double _selisihBerat = 0;

  @override
  void initState() {
    super.initState();
    _loadDataFromDatabase();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoSwipeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDataFromDatabase() async {
    setState(() => _isLoading = true);
    
    try {
      final dbHelper = DatabaseHelper();
      int? userId = widget.userId ?? dbHelper.getCurrentUserId();
      
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final userData = await dbHelper.getCompleteUserData(userId);
      final dataDiri = userData['dataDiri'] as Map<String, String>? ?? {};

      _jadwalObat = List<Map<String, dynamic>>.from(userData['jadwalObat'] ?? []);
      _userName = dataDiri['nama'] ?? widget.name;
      _userEmail = widget.email;
      
      final today = DateTime.now().toIso8601String().split('T').first;
      final db = await dbHelper.database;
      
      _sesiStatus = List.filled(_jadwalObat.length, false);
      _isTransitioning = List.filled(_jadwalObat.length, false);
      
      for (int i = 0; i < _jadwalObat.length; i++) {
        final existing = await db.query(
          'sesi_kepatuhan',
          where: 'user_id = ? AND tanggal = ? AND sesi_index = ?',
          whereArgs: [userId, today, i],
        );
        _sesiStatus[i] = existing.isNotEmpty && (existing.first['status'] as int? ?? 0) == 1;
      }
      
      _currentSesiIndex = _getActiveSesiIndexByTime();
      
      await _loadLatestEfekSamping(userId);
      
      setState(() => _isLoading = false);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients && _currentSesiIndex < _jadwalObat.length) {
          _pageController.jumpToPage(_currentSesiIndex);
        }
      });
      
    } catch (e) {
      print('Error loading home data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLatestEfekSamping(int userId) async {
    final dbHelper = DatabaseHelper();
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    var efekList = await dbHelper.getEfekSampingPasienByDate(userId, today);
    
    if (efekList.isEmpty) {
      efekList = await dbHelper.getEfekSampingPasienByDate(userId, yesterday);
      if (efekList.isNotEmpty) {
        _latestEfekSampingDate = 'KEMARIN';
      } else {
        _latestEfekSampingDate = '';
        _adaEfekSamping = false;
        return;
      }
    } else {
      _latestEfekSampingDate = 'HARI INI';
    }
    
    if (efekList.isNotEmpty) {
      final efekTertinggi = efekList.reduce((a, b) => 
        (a['skor'] as int) > (b['skor'] as int) ? a : b
      );
      
      _latestEfekSampingSkor = efekTertinggi['skor'] as int;
      String namaEfek = efekTertinggi['nama_efek_samping'] as String;
      String level = _getSkorLabel(_latestEfekSampingSkor);
      _latestEfekSamping = '$namaEfek ($level)';
      _adaEfekSamping = _latestEfekSampingSkor >= 2;
    } else {
      _adaEfekSamping = false;
    }
    
    setState(() {});
  }

  String _getSkorLabel(int skor) {
    switch (skor) {
      case 1: return 'Ringan';
      case 2: return 'Sedang';
      case 3: return 'Berat';
      default: return '';
    }
  }

  bool _canCheckMedication(String sessionName) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    
    switch (sessionName.toLowerCase()) {
      case 'pagi':
        return true;
      case 'siang':
        return currentMinutes >= 11 * 60;
      case 'malam':
        return currentMinutes >= 15 * 60;
      default:
        return true;
    }
  }

  String _getCannotCheckMessage(String sessionName) {
    switch (sessionName.toLowerCase()) {
      case 'siang':
        return 'Belum waktunya minum obat SIANG.\nWaktu minum obat siang dimulai jam 11:00';
      case 'malam':
        return 'Belum waktunya minum obat MALAM.\nWaktu minum obat malam dimulai jam 15:00';
      default:
        return 'Belum waktunya minum obat';
    }
  }

  int _getActiveSesiIndexByTime() {
    if (_jadwalObat.isEmpty) return 0;
    
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    
    String targetSession = '';
    
    // Pagi: 00:00 - 10:59
    if (currentMinutes <= 10 * 60 + 59) {
      targetSession = 'pagi';
    }
    // Siang: 11:00 - 14:59
    else if (currentMinutes >= 11 * 60 && currentMinutes <= 14 * 60 + 59) {
      targetSession = 'siang';
    }
    // Malam: 15:00 - 23:59
    else if (currentMinutes >= 15 * 60) {
      targetSession = 'malam';
    }
    
    for (int i = 0; i < _jadwalObat.length; i++) {
      final sesi = _jadwalObat[i]['sesi']?.toLowerCase() ?? '';
      if (sesi == targetSession) {
        return i;
      }
    }
    
    return 0;
  }

  bool _isAllMedicationsInSessionChecked(int sessionIndex) {
    if (sessionIndex >= _jadwalObat.length) return false;
    
    String targetSession = _jadwalObat[sessionIndex]['sesi'] ?? '';
    List<int> sameSessionIndices = [];
    
    for (int i = 0; i < _jadwalObat.length; i++) {
      if (_jadwalObat[i]['sesi'] == targetSession) {
        sameSessionIndices.add(i);
      }
    }
    
    for (int index in sameSessionIndices) {
      if (!_sesiStatus[index]) {
        return false;
      }
    }
    return true;
  }

  int? _getNextUncheckedInSession(int currentIndex) {
    String targetSession = _jadwalObat[currentIndex]['sesi'] ?? '';
    
    for (int i = 0; i < _jadwalObat.length; i++) {
      if (_jadwalObat[i]['sesi'] == targetSession && !_sesiStatus[i]) {
        return i;
      }
    }
    return null;
  }

  Future<void> _konfirmasiMinum(int index) async {
    if (_sesiStatus[index]) {
      await _batalkanMinum(index);
      return;
    }

    String sesiName = _jadwalObat[index]['sesi'] ?? '';
    if (!_canCheckMedication(sesiName)) {
      String message = _getCannotCheckMessage(sesiName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_isTransitioning[index]) return;

    final dbHelper = DatabaseHelper();
    int? userId = widget.userId ?? dbHelper.getCurrentUserId();
    if (userId == null) return;

    final today = DateTime.now().toIso8601String().split('T').first;

    try {
      final db = await dbHelper.database;
      
      final existing = await db.query(
        'sesi_kepatuhan',
        where: 'user_id = ? AND tanggal = ? AND sesi_index = ?',
        whereArgs: [userId, today, index],
      );
      
      if (existing.isNotEmpty) {
        await db.update(
          'sesi_kepatuhan',
          {'status': 1},
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        await db.insert('sesi_kepatuhan', {
          'user_id': userId,
          'tanggal': today,
          'sesi_index': index,
          'status': 1,
        });
      }
      
      setState(() {
        _sesiStatus[index] = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_jadwalObat[index]['namaObat']} sudah diminum'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
        ),
      );
      
      if (!_isAllMedicationsInSessionChecked(index)) {
        int? nextInSession = _getNextUncheckedInSession(index);
        
        if (nextInSession != null && nextInSession != index) {
          setState(() {
            _isTransitioning[index] = true;
          });
          
          _autoSwipeTimer?.cancel();
          _autoSwipeTimer = Timer(const Duration(seconds: 3), () async {
            if (mounted && _pageController.hasClients) {
              await _pageController.animateToPage(
                nextInSession,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() {
                _currentSesiIndex = nextInSession!;
                _isTransitioning[index] = false;
              });
            }
          });
        }
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _batalkanMinum(int index) async {
    final dbHelper = DatabaseHelper();
    int? userId = widget.userId ?? dbHelper.getCurrentUserId();
    if (userId == null) return;

    final today = DateTime.now().toIso8601String().split('T').first;

    try {
      final db = await dbHelper.database;
      final existing = await db.query(
        'sesi_kepatuhan',
        where: 'user_id = ? AND tanggal = ? AND sesi_index = ?',
        whereArgs: [userId, today, index],
      );
      if (existing.isNotEmpty) {
        await db.update(
          'sesi_kepatuhan',
          {'status': 0},
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      }
      
      setState(() {
        _sesiStatus[index] = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status minum obat dibatalkan'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      debugPrint('Error membatalkan kepatuhan: $e');
    }
  }

  String get _greetingTime {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Pagi';
    if (hour < 15) return 'Siang';
    if (hour < 18) return 'Sore';
    return 'Malam';
  }

  String get _displayName {
    final n = _userName.isNotEmpty ? _userName : _userEmail;
    return n.split(' ').first.split('@').first;
  }

  String _getSesiName(String sesi) {
    switch (sesi.toLowerCase()) {
      case 'pagi': return 'PAGI';
      case 'siang': return 'SIANG';
      case 'malam': return 'MALAM';
      default: return sesi.toUpperCase();
    }
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;
    
    if (index == 0) {
      setState(() => _currentIndex = index);
      return;
    }
    
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CalendarPage()),
      ).then((_) async {
        if (mounted) {
          setState(() => _currentIndex = 0);
          await Future.delayed(const Duration(milliseconds: 200));
          _loadDataFromDatabase();
        }
      });
      return;
    }
    
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RiwayatKesehatanPage(userId: widget.userId),
        ),
      ).then((_) async {
        if (mounted) {
          setState(() => _currentIndex = 0);
          await _loadDataFromDatabase();
        }
      });
      return;
    }
    
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilPage(userId: widget.userId),
        ),
      ).then((_) async {
        if (mounted) {
          setState(() => _currentIndex = 0);
          await _loadDataFromDatabase();
        }
      });
      return;
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

    if (_jadwalObat.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Text(
            'Belum ada jadwal obat',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentIndex,
          onTap: _onNavBarTap,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              name: _userName.isNotEmpty ? _userName : _userEmail,
              photoUrl: widget.photoUrl,
              userId: widget.userId,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GreetingSection(
                      greeting: _greetingTime,
                      name: _displayName,
                    ),
                    const SizedBox(height: 16),

                    if (_adaEfekSamping) ...[
                      _PeringatanGabunganCard(
                        efekTerbaru: _latestEfekSamping,
                        tanggalLabel: _latestEfekSampingDate,
                        skor: _latestEfekSampingSkor,
                        onTapPeringatan: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailEfekSampingPage(
                                userId: widget.userId,
                                tahun: DateTime.now().year,
                                bulan: DateTime.now().month,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_jadwalObat.isNotEmpty)
                      SizedBox(
                        height: 380,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            _autoSwipeTimer?.cancel();
                            setState(() {
                              _currentSesiIndex = index;
                              for (int i = 0; i < _isTransitioning.length; i++) {
                                _isTransitioning[i] = false;
                              }
                            });
                          },
                          itemCount: _jadwalObat.length,
                          itemBuilder: (context, index) {
                            final obat = _jadwalObat[index];
                            final sudahDiminum = _sesiStatus[index];
                            final namaSesi = _getSesiName(obat['sesi'] ?? '');
                            
                            return _ObatCard(
                              namaSesi: namaSesi,
                              namaObat: obat['namaObat'] ?? '',
                              jam: obat['waktu'] ?? '',
                              waktuMakan: obat['waktuMakan'] ?? '',
                              sudahDiminum: sudahDiminum,
                              onKonfirmasi: () => _konfirmasiMinum(index),
                            );
                          },
                        ),
                      )
                    else
                      const SizedBox(height: 380, child: Center(child: Text('Tidak ada jadwal obat'))),
                    
                    if (_jadwalObat.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_jadwalObat.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentSesiIndex == index ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: _currentSesiIndex == index 
                                    ? AppColors.primary 
                                    : Colors.grey.shade300,
                              ),
                            );
                          }),
                        ),
                      ),

                    const SizedBox(height: 16),

                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _BeratBadanCard(
                              beratBadan: _beratBadan,
                              selisih: _selisihBerat,
                              onUpdate: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SkriningCard(
                              sudahIsi: _sudahIsiSkrining,
                              gejalaTinggi: _gejalaTinggi,
                              gejalaSedang: _gejalaSedang,
                              onIsi: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FormScreeningPage(
                                      userId: widget.userId,
                                    ),
                                  ),
                                );

                                if (result != null && result is Map) {
                                  setState(() {
                                    _sudahIsiSkrining = result['sudahIsi'] == true;
                                    _gejalaTinggi = List<String>.from(result['gejalaTinggi'] ?? []);
                                    _gejalaSedang = List<String>.from(result['gejalaSedang'] ?? []);
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final int? userId;

  const _TopBar({
    required this.name, 
    this.photoUrl,
    this.userId
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'TBCare',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilPage(
                    userId: userId,
                  ),
                ),
              );
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  final String greeting;
  final String name;
  const _GreetingSection({required this.greeting, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE4E0EC),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat $greeting, $name',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tetap semangat menjalani pengobatan!',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: _RibbonIcon(),
          ),
        ],
      ),
    );
  }
}

class _RibbonIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 40,
      child: CustomPaint(painter: _RibbonPainter()),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final leftPath = Path()
      ..moveTo(w * 0.5, h * 0.38)
      ..quadraticBezierTo(w * 0.0, h * 0.18, w * 0.08, 0)
      ..quadraticBezierTo(w * 0.35, h * 0.05, w * 0.5, h * 0.20)
      ..close();
    canvas.drawPath(leftPath, paint);

    final rightPath = Path()
      ..moveTo(w * 0.5, h * 0.38)
      ..quadraticBezierTo(w * 1.0, h * 0.18, w * 0.92, 0)
      ..quadraticBezierTo(w * 0.65, h * 0.05, w * 0.5, h * 0.20)
      ..close();
    canvas.drawPath(rightPath, paint);

    final tailPath = Path()
      ..moveTo(w * 0.5, h * 0.38)
      ..quadraticBezierTo(w * 0.28, h * 0.62, w * 0.22, h)
      ..lineTo(w * 0.78, h)
      ..quadraticBezierTo(w * 0.72, h * 0.62, w * 0.5, h * 0.38)
      ..close();
    canvas.drawPath(tailPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PeringatanGabunganCard extends StatelessWidget {
  final String efekTerbaru;
  final String tanggalLabel;
  final int skor;
  final VoidCallback? onTapPeringatan;

  const _PeringatanGabunganCard({
    required this.efekTerbaru,
    required this.tanggalLabel,
    required this.skor,
    this.onTapPeringatan,
  });

  @override
  Widget build(BuildContext context) {
    Color getWarningColor() {
      if (skor >= 3) return const Color(0xFFD32F2F);
      if (skor >= 2) return const Color(0xFFFF9800);
      return const Color(0xFFFFC107);
    }
    
    String getWarningText() {
      if (skor >= 3) return 'DARURAT: SEGERA KE PUSKESMAS / RS!';
      if (skor >= 2) return 'PERINGATAN: SEGERA KONSULTASI KE DOKTER';
      return 'PERHATIAN: PANTAU GEJALA ANDA';
    }
    
    String getLevelText() {
      if (skor >= 3) return 'BERAT';
      if (skor >= 2) return 'SEDANG';
      return 'RINGAN';
    }
    
    Color getLevelColor() {
      if (skor >= 3) return const Color(0xFFD32F2F);
      if (skor >= 2) return const Color(0xFFFF9800);
      return const Color(0xFFFFC107);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3CD),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFE65100), size: 16),
                const SizedBox(width: 6),
                const Text(
                  'PERINGATAN EFEK SAMPING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: getLevelColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    getLevelText(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tanggalLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8D6E63),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        efekTerbaru,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBF360C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTapPeringatan,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: getWarningColor(),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    skor >= 3 ? Icons.emergency : Icons.star_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    getWarningText(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObatCard extends StatelessWidget {
  final String namaSesi;
  final String namaObat;
  final String jam;
  final String waktuMakan;
  final bool sudahDiminum;
  final VoidCallback onKonfirmasi;

  const _ObatCard({
    required this.namaSesi,
    required this.namaObat,
    required this.jam,
    required this.waktuMakan,
    required this.sudahDiminum,
    required this.onKonfirmasi,
  });

  String getWaktuMakanText() {
    if (waktuMakan.isEmpty) return 'Informasi waktu makan tidak tersedia';
    
    final waktuMakanLower = waktuMakan.toLowerCase();
    
    if (waktuMakanLower.contains('sebelum')) {
      return 'Diminum sebelum makan';
    } else if (waktuMakanLower.contains('sesudah') || waktuMakanLower.contains('setelah')) {
      return 'Diminum setelah makan';
    }
    
    return waktuMakan;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: sudahDiminum ? AppColors.success.withOpacity(0.1) : const Color(0xFFDCEEFB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sudahDiminum ? AppColors.success : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  namaSesi,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  jam,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            namaObat,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onKonfirmasi,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sudahDiminum ? AppColors.success.withOpacity(0.08) : Colors.white,
                      border: Border.all(
                        color: sudahDiminum ? AppColors.success : AppColors.primary,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (sudahDiminum ? AppColors.success : AppColors.primary).withOpacity(0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      sudahDiminum ? Icons.check_circle_rounded : Icons.check_rounded,
                      size: 46,
                      color: sudahDiminum ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  sudahDiminum
                      ? 'Terima Kasih telah meminum obat!\nTekan lagi untuk membatalkan'
                      : 'Tekan tombol di atas untuk\nkonfirmasi minum obat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: sudahDiminum ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDE7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE082), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  waktuMakan.toLowerCase().contains('sebelum') 
                      ? Icons.free_breakfast_outlined 
                      : (waktuMakan.toLowerCase().contains('sesudah')
                          ? Icons.dinner_dining_outlined
                          : Icons.info_outline_rounded),
                  color: const Color(0xFFFF8F00),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    getWaktuMakanText(),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF795548)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BeratBadanCard extends StatelessWidget {
  final double beratBadan;
  final double selisih;
  final VoidCallback onUpdate;

  const _BeratBadanCard({
    required this.beratBadan,
    required this.selisih,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final turun = selisih < 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.monitor_weight_outlined, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 4),
              Text('Berat Badan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            beratBadan > 0 ? '${beratBadan.toStringAsFixed(1)}kg' : '-- kg',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          if (beratBadan > 0) ...[
            Row(
              children: [
                Icon(
                  turun ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 13,
                  color: turun ? const Color(0xFFD32F2F) : AppColors.success,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    '${selisih.abs().toStringAsFixed(1)} kg dari minggu lalu',
                    style: TextStyle(
                      fontSize: 11,
                      color: turun ? const Color(0xFFD32F2F) : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text(
              'Belum ada data',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onUpdate,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Perbarui',
                style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkriningCard extends StatelessWidget {
  final bool sudahIsi;
  final List<String> gejalaTinggi;
  final List<String> gejalaSedang;
  final VoidCallback onIsi;

  const _SkriningCard({
    required this.sudahIsi,
    required this.gejalaTinggi,
    required this.gejalaSedang,
    required this.onIsi,
  });

  @override
  Widget build(BuildContext context) {
    final adaTinggi = gejalaTinggi.isNotEmpty;
    final adaSedang = gejalaSedang.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: const [
                Icon(Icons.favorite_border_rounded, size: 16, color: Color(0xFFE57373)),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Screening Mingguan',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildKonten(adaTinggi, adaSedang),
          ),
          const Spacer(),

          if (!sudahIsi)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onIsi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Isi Sekarang',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildKonten(bool adaTinggi, bool adaSedang) {
    if (!sudahIsi) {
      return const Text(
        'ANDA BELUM MENGISI SKRINING MINGGU INI',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF97316),
          height: 1.6,
        ),
      );
    } else if (adaTinggi) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'HIGH RISK',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          _buildGejalaList(gejalaTinggi, const Color(0xFFDC2626)),
        ],
      );
    } else if (adaSedang) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'MEDIUM RISK',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          _buildGejalaList(gejalaSedang, const Color(0xFFF97316)),
        ],
      );
    } else {
      return const Text(
        'Kondisi kesehatan anda mengalami peningkatan!',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D9488),
          height: 1.4,
        ),
      );
    }
  }

  Widget _buildGejalaList(List<String> items, Color dotColor) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 120),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    g,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}