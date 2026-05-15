import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';
import 'package:tbc_app/widgets/app_bottom_nav.dart';
import 'package:tbc_app/database/database_helper.dart'; // IMPORT DATABASE
import 'package:tbc_app/pages/profile_page.dart';

// ─────────────────────────────────────────────
//  HomeScreen
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final String email;
  final String name;
  final String? photoUrl;
  final int? userId;  // TAMBAHKAN parameter userId

  const HomeScreen({
    super.key,
    required this.email,
    this.name = '',
    this.photoUrl,
    this.userId,  // TAMBAHKAN
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  // ── State untuk data dari database ──
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
  List<String> _gejala = [];
  
  // Data tambahan
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
        print('❌ User ID tidak ditemukan');
        setState(() => _isLoading = false);
        return;
      }
      
      // Ambil data lengkap user dari database
      final userData = await dbHelper.getCompleteUserData(userId);
      
      // Ambil data diri
      final dataDiri = userData['dataDiri'] as Map<String, String>? ?? {};
      
      // Ambil jadwal obat
      _jadwalObat = List<Map<String, dynamic>>.from(userData['jadwalObat'] ?? []);
      
      // Update user info
      _userName = dataDiri['nama'] ?? widget.name;
      _userEmail = widget.email;
      
      // Ambil jadwal minum obat hari ini (cari obat dengan sesi sesuai jam sekarang atau terdekat)
      if (_jadwalObat.isNotEmpty) {
        // Ambil obat pertama sebagai contoh, nanti bisa disesuaikan dengan jam
        final firstObat = _jadwalObat.first;
        _namaObat = firstObat['namaObat'] ?? '';
        _jamObat = firstObat['waktu'] ?? '';
      } else {
        _namaObat = 'Belum ada jadwal obat';
        _jamObat = '--:--';
      }
      
      // Cek status kepatuhan hari ini
      final today = DateTime.now().toIso8601String().split('T').first;
      final kepatuhan = await dbHelper.getKepatuhanStatus(userId, today);
      _obatSudahDiminum = kepatuhan == 1;
      
      // TODO: Ambil data efek samping dari tabel efek_samping_pasien
      // Untuk sementara pakai dummy
      _adaEfekSamping = false; // Ganti dengan data real nanti
      
      // TODO: Ambil data skrining mingguan
      _sudahIsiSkrining = false;
      
      setState(() => _isLoading = false);
      
    } catch (e) {
      print('Error loading home data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _konfirmasiMinum() async {
    final dbHelper = DatabaseHelper();
    int? userId = widget.userId ?? dbHelper.getCurrentUserId();
    
    if (userId == null) return;
    
    final today = DateTime.now().toIso8601String().split('T').first;
    final newStatus = _obatSudahDiminum ? 0 : 1;
    
    try {
      await dbHelper.updateKepatuhan(userId, today, newStatus);
      setState(() => _obatSudahDiminum = !_obatSudahDiminum);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _obatSudahDiminum 
              ? '✅ Terima kasih telah meminum obat hari ini!' 
              : '⚠️ Konfirmasi dibatalkan',
          ),
          backgroundColor: _obatSudahDiminum ? AppColors.success : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error updating kepatuhan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan status'),
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
                          // Navigasi ke halaman efek samping
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

                    // ── Baris bawah ──
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _BeratBadanCard(
                              beratBadan: _beratBadan,
                              selisih: _selisihBerat,
                              onUpdate: () {
                                // Navigasi ke halaman input berat badan
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SkriningCard(
                              sudahIsi: _sudahIsiSkrining,
                              gejala: _gejala,
                              onIsi: () {
                                // Navigasi ke halaman skrining
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
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Top Bar (sama seperti sebelumnya)
// ─────────────────────────────────────────────
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
              // Navigasi ke profile
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

// ── Greeting Section (sama seperti sebelumnya) ──
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
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(16),
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

// ── PeringatanGabunganCard (sama) ──
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

// ── ObatCard (sama) ──
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
                      color: Colors.white,
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
                      ? 'Terima Kasih telah rutin \nmeminum obat hari ini!'
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

// ── BeratBadanCard (dengan onUpdate callback) ──
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

// ── SkriningCard (sama) ──
class _SkriningCard extends StatelessWidget {
  final bool sudahIsi;
  final List<String> gejala;
  final VoidCallback onIsi;

  const _SkriningCard({
    required this.sudahIsi,
    required this.gejala,
    required this.onIsi,
  });

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 12),
          if (sudahIsi) ...[
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
            ...gejala.map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF9A9A)),
                    ),
                    const SizedBox(width: 8),
                    Text(g, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Text(
              'ANDA BELUM\nMENGISI SKRINING\nMINGGU INI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
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
          ],
        ],
      ),
    );
  }
}