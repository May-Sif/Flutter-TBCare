import 'package:flutter/material.dart';
import 'package:tbc_app/pages/authentication/authentication.dart';
import 'package:tbc_app/pages/isi_datadiri.dart';
import 'package:tbc_app/theme.dart';
import 'package:tbc_app/database/database_helper.dart';
import 'isi_dataobat.dart';

class ProfilPage extends StatefulWidget {
  final Map<String, dynamic>? dataPasien;  // BISA NULL, karena nanti dari DB
  final int? userId;

  const ProfilPage({
    super.key,
    this.dataPasien,
    this.userId,
  });

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  late bool isNotifikasiOn;
  late Map<String, dynamic> dataPasienState;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    isNotifikasiOn = true;
    
    // Inisialisasi dataPasienState
    if (widget.dataPasien != null) {
      dataPasienState = Map.from(widget.dataPasien!);
      _isLoading = false;
    } else {
      dataPasienState = {};
      _loadDataFromDatabase();
    }
  }

  Future<void> _loadDataFromDatabase() async {
    try {
      if (widget.userId == null) return;
      
      final dbHelper = DatabaseHelper();
      final userData = await dbHelper.getCompleteUserData(widget.userId!);
      
      if (mounted) {
        setState(() {
          dataPasienState = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Fungsi untuk menyimpan perubahan ke database setelah edit
  Future<void> _saveToDatabase() async {
    if (widget.userId == null) return;
    
    try {
      final dbHelper = DatabaseHelper();
      
      // Ambil data diri dan jadwal obat dari dataPasienState
      final dataDiri = dataPasienState['dataDiri'] as Map<String, String>;
      final jadwalObat = dataPasienState['jadwalObat'] as List<Map<String, dynamic>>;
      
      await dbHelper.saveCompleteUserData(
        dataDiri,
        jadwalObat,
        email: await dbHelper.getUserEmail(widget.userId!),
      );
      
      print('Data berhasil disimpan ke database');
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Info Account', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Extract data diri dengan aman
    final dataDiriRaw = dataPasienState['dataDiri'];
    final Map<String, String> dataDiri;

    if (dataDiriRaw is Map<String, dynamic>) {
      dataDiri = Map<String, String>.from(dataDiriRaw);
    } else if (dataDiriRaw is Map<String, String>) {
      dataDiri = dataDiriRaw;
    } else {
      dataDiri = {};
    }

    // Extract jadwal obat dengan aman
    final jadwalObatRaw = dataPasienState['jadwalObat'];
    final List<Map<String, dynamic>> jadwalObat;

    if (jadwalObatRaw is List) {
      jadwalObat = jadwalObatRaw.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      jadwalObat = [];
    }

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Info Account',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        elevation: 0,
      ),

      body: Stack(
        children: [
          // ===== BACKGROUND CROSS =====
          Positioned(
            left: -100,
            top: 360,
            child: Transform.rotate(
              angle: -0.52,
              child: Container(
                width: 700,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFB88484),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: -100,
            top: 360,
            child: Transform.rotate(
              angle: 0.52,
              child: Container(
                width: 700,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFB88484),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===== CONTENT =====
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // ================= CARD PROFIL =================
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.82,
                    decoration: BoxDecoration(
                      color: AppColors.cardProfil,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // avatar
                          const Center(
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                Icons.person,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(
                            color: AppColors.borderProfil,
                            thickness: 1,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Nama:', dataDiri['nama'] ?? '-'),
                          const SizedBox(height: 10),
                          _buildInfoRow('Umur:', dataDiri['umur'] ?? '-'),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            'Tanggal diagnosis:',
                            dataDiri['tanggalDiagnosis'] ?? '-',
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            'Jenis TBC:',
                            dataDiri['tipeTbc'] ?? dataDiri['jenisTbc'] ?? '-',
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            'Status HIV:',
                            dataDiri['statusHiv'] ?? '-',
                          ),
                          const SizedBox(height: 20),
                          Divider(
                            color: AppColors.borderProfil,
                            thickness: 1,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 100,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => IsiDataDiriPage(
                                        existingData: {
                                          'nama': dataDiri['nama'] ?? '',
                                          'umur': dataDiri['umur'] ?? '',
                                          'tanggalDiagnosis': dataDiri['tanggalDiagnosis'] ?? '',
                                          'tipeTbc': dataDiri['tipeTbc'] ?? dataDiri['jenisTbc'] ?? '',
                                          'statusHiv': dataDiri['statusHiv'] ?? '',
                                          'tahapPengobatan': dataDiri['tahapPengobatan'] ?? 'Tahap Intensif',
                                          'masaPengobatan': dataDiri['masaPengobatan'] ?? '6 bulan',
                                        },
                                      ),
                                    ),
                                  );

                                  if (result != null && result is Map<String, dynamic>) {
                                    setState(() {
                                      dataPasienState['dataDiri'] = {
                                        'nama': result['nama'] ?? '',
                                        'umur': result['umur'] ?? '',
                                        'tanggalDiagnosis': result['tanggalDiagnosis'] ?? '',
                                        'tipeTbc': result['tipeTbc'] ?? '',
                                        'jenisTbc': result['tipeTbc'] ?? '',
                                        'statusHiv': result['statusHiv'] ?? '',
                                        'tahapPengobatan': result['tahapPengobatan'] ?? '',
                                        'masaPengobatan': result['masaPengobatan'] ?? '',
                                      };
                                    });
                                    // Simpan ke database setelah edit
                                    await _saveToDatabase();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'Edit Profil',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ================= CARD NOTIFIKASI =================
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.82,
                    decoration: BoxDecoration(
                      color: AppColors.cardPengingat,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.access_time,
                                      size: 22,
                                      color: AppColors.unguPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Notifikasi Pengingat',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: isNotifikasiOn,
                                onChanged: (value) {
                                  setState(() {
                                    isNotifikasiOn = value;
                                  });
                                },
                                activeColor: Colors.white,
                                activeTrackColor: const Color(0xFF38C5BA),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Jam minum obat :',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...jadwalObat.map((obat) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                bottom: 6,
                              ),
                              child: Text(
                                '• ${obat['waktu']} : ${obat['namaObat']}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }),
                          if (jadwalObat.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(left: 12),
                              child: Text(
                                'Belum ada jadwal obat',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 100,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => IsiDataObatPage(
                                        dataDiri: dataDiri,
                                        existingJadwalObat: jadwalObat,
                                        userId: widget.userId,
                                      ),
                                    ),
                                  );

                                  if (result != null && result is Map<String, dynamic>) {
                                    setState(() {
                                      dataPasienState['jadwalObat'] = result['jadwalObat'];
                                    });
                                    // Simpan ke database setelah edit
                                    await _saveToDatabase();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF168A92),
                                  elevation: 3,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'Edit Obat',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ================= RESET TRACK =================
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.shade300,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Reset Track Pengobatan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            Icon(
                              Icons.disabled_by_default,
                              color: Colors.red.shade200,
                              size: 32,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Menghapus seluruh riwayat pengobatan dan kepatuhan obat Anda.\nTindakan ini tidak dapat dibatalkan.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              onPressed: () {
                                _showResetConfirmationDialog(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC91014),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Reset Track',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ================= LOGOUT =================
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      // tombol abu memanjang
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade500,
                          ),
                          child: TextButton(
                            onPressed: () {
                              _showLogoutConfirmationDialog(context);
                            },
                            child: const Text(
                              'Log Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // panah
                      const Text(
                        '>>>',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // tombol bulat
                      GestureDetector(
                        onTap: () {
                          _showLogoutConfirmationDialog(context);
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Color(0xFF9EE7DF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.logout,
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // lebar tetap untuk label
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
    }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85, // 85% dari lebar layar
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Reset Track',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Data yang akan dihapus:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Riwayat kepatuhan minum obat\n'
                  '• Riwayat efek samping\n'
                  '• Riwayat screening mingguan',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '⚠️ Data profil dan jadwal obat akan tetap tersimpan',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tindakan ini tidak dapat dibatalkan!',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.red),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _resetProgress();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Ya, Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method untuk melakukan reset progress
  Future<void> _resetProgress() async {
    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Meriset data...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final dbHelper = DatabaseHelper();
      int? userId = widget.userId ?? dbHelper.getCurrentUserId();

      if (userId != null) {
        await dbHelper.resetUserProgress(userId);

        if (mounted) {
          Navigator.pop(context); // tutup loading

          // Tampilkan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Progress berhasil direset!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );

          // Refresh halaman profile (optional)
          setState(() {});
        }
      } else {
        throw Exception('User ID tidak ditemukan');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal reset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text(
            'Apakah Anda yakin ingin keluar?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final dbHelper = DatabaseHelper();
                await dbHelper.logout();
                // Kembali ke halaman login
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}