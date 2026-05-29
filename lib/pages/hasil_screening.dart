import 'package:flutter/material.dart';

class HasilScreeningPage extends StatelessWidget {
  final Map<String, dynamic> hasilData;

  const HasilScreeningPage({
    super.key,
    required this.hasilData,
  });

  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;

  double get _severity => hasilData['skor'] as double? ?? 0;
  
  bool get _adaDahakBerdarah => hasilData['adaDahakBerdarah'] as bool? ?? false;

  _StatusInfo get _statusInfo {
    if (_adaDahakBerdarah) {
      return _StatusInfo(
        label: '⚠️ DARURAT: SEGERA KE PUSKESMAS',
        warna: const Color(0xFFDC2626),
        warnaRing: const Color(0xFFDC2626),
        warnaBg: const Color(0xFFFEE2E2),
        icon: Icons.emergency,
        pesan: 'Ditemukan dahak berdarah! Segera konsultasikan ke dokter atau puskesmas terdekat.',
      );
    }
    
    if (_severity <= 25) {
      return _StatusInfo(
        label: 'Status: Baik',
        warna: const Color(0xFF0D9488),
        warnaRing: const Color(0xFF0D9488),
        warnaBg: const Color(0xFFE6F7F6),
        icon: Icons.check_circle_outline,
        pesan: 'Kondisi Anda membaik.\nTeruskan pengobatan secara teratur.',
      );
    } else if (_severity <= 50) {
      return _StatusInfo(
        label: 'Status: Perlu Pemantauan',
        warna: const Color(0xFFD97706),
        warnaRing: const Color(0xFFD97706),
        warnaBg: const Color(0xFFFEF3C7),
        icon: Icons.warning_amber_rounded,
        pesan: 'Ada gejala yang belum membaik.\nSaran: pantau 1 minggu lagi.',
      );
    } else if (_severity <= 75) {
      return _StatusInfo(
        label: 'Status: Waspada',
        warna: const Color(0xFFEA580C),
        warnaRing: const Color(0xFFEA580C),
        warnaBg: const Color(0xFFFFEDD5),
        icon: Icons.notification_important,
        pesan: 'Gejala cukup signifikan.\nSegera konsultasikan ke dokter.',
      );
    } else {
      return _StatusInfo(
        label: 'Status: Risiko Tinggi',
        warna: const Color(0xFFDC2626),
        warnaRing: const Color(0xFFDC2626),
        warnaBg: const Color(0xFFFEE2E2),
        icon: Icons.local_hospital_outlined,
        pesan: 'Gejala berat! Segera hubungi dokter atau puskesmas.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo;
    final beratBadan = hasilData['beratBadan'] as String? ?? '-';
    final gejala = hasilData['efekSamping'] as String? ?? '-';
    final assessment = hasilData['assessment'] as String? ?? '-';

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkorCard(info),
                    const SizedBox(height: 24),
                    const Text(
                      'Kesimpulan Hasil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildKesimpulanCard(beratBadan, gejala, assessment),
                    const SizedBox(height: 28),
                    _buildKembaliButton(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF374151)),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'HASIL SCREENING',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkorCard(_StatusInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: info.warnaRing, width: 8),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_severity.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Severity',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: info.warnaBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(info.icon, color: info.warna, size: 18),
                const SizedBox(width: 8),
                Text(
                  info.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: info.warna,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(color: info.warna, width: 3),
              ),
            ),
            child: Text(
              info.pesan,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKesimpulanCard(String beratBadan, String gejala, String assessment) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
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
        children: [
          _buildKesimpulanItem(
            icon: Icons.monitor_weight_outlined,
            iconBg: const Color(0xFFDBEAFE),
            iconColor: const Color(0xFF2563EB),
            judul: 'Berat Badan',
            isi: beratBadan,
            showDivider: true,
          ),
          _buildKesimpulanItem(
            icon: Icons.list_alt_outlined, // Icon yang valid
            iconBg: const Color(0xFFFFEDD5),
            iconColor: const Color(0xFFEA580C),
            judul: 'Gejala yang Dilaporkan',
            isi: gejala.isEmpty || gejala == '-' ? 'Tidak ada gejala yang dilaporkan' : gejala,
            showDivider: true,
          ),
          _buildKesimpulanItem(
            icon: Icons.assignment_turned_in_outlined,
            iconBg: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
            judul: 'Assessment',
            isi: assessment,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildKesimpulanItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String judul,
    required String isi,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isi,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE5E7EB)),
      ],
    );
  }

  Widget _buildKembaliButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D9488),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Kembali ke Home',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final Color warna;
  final Color warnaRing;
  final Color warnaBg;
  final IconData icon;
  final String pesan;

  const _StatusInfo({
    required this.label,
    required this.warna,
    required this.warnaRing,
    required this.warnaBg,
    required this.icon,
    required this.pesan,
  });
}