import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';
import 'package:tbc_app/widgets/app_bottom_nav.dart';
import 'package:tbc_app/database/database_helper.dart';
import 'package:tbc_app/pages/profile_page.dart';
import 'package:tbc_app/pages/calendar_page.dart';
import 'package:tbc_app/pages/form_screening.dart';
import 'package:tbc_app/pages/hasil_screening.dart';

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
  bool _obatSudahDiminum = false;
  bool _adaEfekSamping = false;
  double _beratBadan = 0;
  double _selisihBerat = 0;
  String _namaObat = '';
  String _jamObat = '';
  String _efekKemarin = '';
  String _efekHariIni = '';
  bool _sudahIsiSkrining = false;
  List<String> _gejalaTinggi = [];
  List<String> _gejalaSedang = [];
  Map<String, dynamic> _hasilSkrining = {};

  bool _showTerimaKasih = false;
  int _obatAktifIndex = 0;

  String _userName = '';
  String _userEmail = '';
  List<Map<String, dynamic>> _jadwalObat = [];

  @override
  void initState() {
    super.initState();
    _loadDataFromDatabase();
  }

  Future<void> _loadDataFromDatabase() async {
    setState(() => _isLoading = true);
    
    try {
      final dbHelper = DatabaseHelper();
      int? userId = widget.userId ?? dbHelper.getCurrentUserId();
      
      if (userId == null) {
        print('User ID tidak ditemukan');
        setState(() => _isLoading = false);
        return;
      }
      
      final userData = await dbHelper.getCompleteUserData(userId);
      final dataDiri = userData['dataDiri'] as Map<String, String>? ?? {};

      _jadwalObat = List<Map<String, dynamic>>.from(userData['jadwalObat'] ?? []);
      _userName = dataDiri['nama'] ?? widget.name;
      _userEmail = widget.email;
      
      if (_jadwalObat.isNotEmpty) {
        final firstObat = _jadwalObat.first;
        _namaObat = firstObat['namaObat'] ?? '';
        _jamObat = firstObat['waktu'] ?? '';
      } else {
        _namaObat = 'Belum ada jadwal obat';
        _jamObat = '--:--';
      }
      
      final today = DateTime.now().toIso8601String().split('T').first;
      final db = await dbHelper.database;
      final sesiRows = await db.query(
        'sesi_kepatuhan',
        where: 'user_id = ? AND tanggal = ? AND sesi_index = ?',
        whereArgs: [userId, today, _obatAktifIndex],
      );
      _obatSudahDiminum = sesiRows.isNotEmpty && (sesiRows.first['status'] as int? ?? 0) == 1;
      _adaEfekSamping = false; 
      _sudahIsiSkrining = false;
      
      setState(() => _isLoading = false);
      
    } catch (e) {
      print('Error loading home data: $e');
      setState(() => _isLoading = false);
    }
  }

  int _konfirmasiToken = 0;

  Future<void> _konfirmasiMinum() async {
    if (_showTerimaKasih) {
      _batalkanMinum();
      return;
    }

    final dbHelper = DatabaseHelper();
    int? userId = widget.userId ?? dbHelper.getCurrentUserId();
    if (userId == null) return;

    final today = DateTime.now().toIso8601String().split('T').first;

    try {
      final db = await dbHelper.database;
      final existing = await db.query(
        'sesi_kepatuhan',
        where: 'user_id = ? AND tanggal = ? AND sesi_index = ?',
        whereArgs: [userId, today, _obatAktifIndex],
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
          'sesi_index': _obatAktifIndex,
          'status': 1,
        });
      }
      final allSesi = await db.query(
        'sesi_kepatuhan',
        where: 'user_id = ? AND tanggal = ?',
        whereArgs: [userId, today],
      );
      final totalObat = _jadwalObat.length;
      final sudahSemua = allSesi.where((r) => (r['status'] as int? ?? 0) == 1).length == totalObat;
      await dbHelper.updateKepatuhan(userId, today, sudahSemua ? 1 : 0);

      final token = ++_konfirmasiToken;
      setState(() {
        _obatSudahDiminum = true;
        _showTerimaKasih = true;
      });

      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        if (_konfirmasiToken != token) return;
        setState(() {
          _showTerimaKasih = false;
          _obatSudahDiminum = false;
          if (_jadwalObat.isNotEmpty) {
            _obatAktifIndex = (_obatAktifIndex + 1) % _jadwalObat.length;
            _namaObat = _jadwalObat[_obatAktifIndex]['namaObat'] ?? '';
            _jamObat = _jadwalObat[_obatAktifIndex]['waktu'] ?? '';
          }
        });
      });
    } catch (e) {
      debugPrint('Error updating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _batalkanMinum() async {
    final dbHelper = DatabaseHelper();
    int? userId = widget.userId ?? dbHelper.getCurrentUserId();
    if (userId == null) return;

    final today = DateTime.now().toIso8601String().split('T').first;

    try {
      final db = await dbHelper.database;
      final existing = await db.query(
        'sesi_kepatuhan',
        where: 'user_id = ? AND tanggal = ? AND sesi_index = ?',
        whereArgs: [userId, today, _obatAktifIndex],
      );
      if (existing.isNotEmpty) {
        await db.update(
          'sesi_kepatuhan',
          {'status': 0},
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      }
      await dbHelper.updateKepatuhan(userId, today, 0);
      _konfirmasiToken++;
      setState(() {
        _obatSudahDiminum = false;
        _showTerimaKasih = false;
      });
    } catch (e) {
      debugPrint('Error membatalkan kepatuhan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membatalkan status'),
          backgroundColor: Colors.red,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
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
                    // ── Greeting ──────────────────────────
                    _GreetingSection(
                      greeting: _greetingTime,
                      name: _displayName,
                    ),
                    const SizedBox(height: 16),

                    // ── Card peringatan gabungan ───────────
                    if (_adaEfekSamping) ...[
                      _PeringatanGabunganCard(
                        efekKemarin: _efekKemarin,
                        efekHariIni: _efekHariIni,
                        onTapPeringatan: () {
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Card obat ──────────────────────────
                    _ObatCard(
                      namaObat: _namaObat,
                      jam: _jamObat,
                      sudahDiminum: _obatSudahDiminum,
                      onKonfirmasi: _konfirmasiMinum,
                    ),
                    const SizedBox(height: 16),

                    // ── Card bawah ──
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _BeratBadanCard(
                              beratBadan: _beratBadan,
                              selisih: _selisihBerat,
                              onUpdate: () {
                              },
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
        onTap: (i) {
          if (i == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalendarPage()),
            ).then((_) {
              setState(() => _currentIndex = 0);
            });
          } else {
            setState(() => _currentIndex = i);
          }
        },
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

// ── Greeting Section ──
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

// ── PeringatanGabunganCard ──
class _PeringatanGabunganCard extends StatelessWidget {
  final String efekKemarin;
  final String efekHariIni;
  final VoidCallback? onTapPeringatan;

  const _PeringatanGabunganCard({
    required this.efekKemarin,
    required this.efekHariIni,
    this.onTapPeringatan,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: const Color(0xFFFF8F00),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'WASPADA',
                    style: TextStyle(
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
                      const Text(
                        'KEMARIN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8D6E63),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        efekKemarin,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBF360C),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: const Color(0xFFE0E0E0),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HARI INI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8D6E63),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        efekHariIni,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8D6E63),
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
              decoration: const BoxDecoration(
                color: Color(0xFFD32F2F),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.star_rounded, color: Colors.white, size: 15),
                  SizedBox(width: 8),
                  Text(
                    'PERINGATAN: SEGERA KE PUSKESMAS / RSI',
                    style: TextStyle(
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

// ── ObatCard  ──
class _ObatCard extends StatelessWidget {
  final String namaObat;
  final String jam;
  final bool sudahDiminum;
  final VoidCallback onKonfirmasi;

  const _ObatCard({
    required this.namaObat,
    required this.jam,
    required this.sudahDiminum,
    required this.onKonfirmasi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEEFB),
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
              const Text(
                'Obat Selanjutnya:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
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
          const SizedBox(height: 4),
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
                      color: sudahDiminum
                          ? AppColors.success.withOpacity(0.08)
                          : Colors.white,
                      border: Border.all(
                        color: sudahDiminum ? AppColors.success : AppColors.primary,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (sudahDiminum ? AppColors.success : AppColors.primary)
                              .withOpacity(0.18),
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
                      ? 'Terima Kasih telah rutin meminum obat!\nTekan lagi untuk membatalkan'
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
              children: const [
                Icon(Icons.info_outline_rounded, color: Color(0xFFFF8F00), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pastikan diminum saat perut kosong atau sesuai anjuran dokter.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
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

// ── BeratBadanCard  ──
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

// ── SkriningCard ──
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