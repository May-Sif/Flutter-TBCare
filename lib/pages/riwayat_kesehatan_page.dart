import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';
import 'package:tbc_app/widgets/app_bottom_nav.dart';
import 'package:tbc_app/pages/calendar_page.dart';
import 'package:tbc_app/pages/profile_page.dart';
import 'package:tbc_app/pages/home_page.dart';

class RiwayatKesehatanPage extends StatefulWidget {
  final int? userId;

  const RiwayatKesehatanPage({super.key, this.userId});

  @override
  State<RiwayatKesehatanPage> createState() => _RiwayatKesehatanPageState();
}

class _RiwayatKesehatanPageState extends State<RiwayatKesehatanPage> {
  int _currentIndex = 2; // Index untuk Statistik

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;
    
    // Index 0: Beranda → HomeScreen
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            email: '',
            name: '',
            userId: widget.userId,
          ),
        ),
      );
      return;
    }
    
    // Index 1: Jadwal → CalendarPage
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CalendarPage()),
      );
      return;
    }
    
    // Index 3: Profil → ProfilPage
    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilPage(userId: widget.userId),
        ),
      );
      return;
    }
    
    // Index 2: Tetap di halaman ini
    setState(() => _currentIndex = index);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

  // ================= HEADER =================
  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Riwayat Kesehatan",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        Text(
          "Pantau kemajuan pengobatan dan kondisi fisik Anda secara berkala.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ================= SUMMARY =================
  Widget _summaryCard() {
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

          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: CircularProgressIndicator(
                  value: 0.95,
                  strokeWidth: 10,
                  backgroundColor: AppColors.divider,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const Column(
                children: [
                  Text(
                    "95%",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    "Patuh",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 16),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    "28",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text("Hari Tuntas",
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              Column(
                children: [
                  Text(
                    "2",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  Text("Terlewat",
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  // ================= PHASE =================
  Widget _phaseCard() {
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

          const Text("Intensif (Bulan 1-2)   75% Selesai"),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.75,
              minHeight: 10,
              backgroundColor: AppColors.divider,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),

          const SizedBox(height: 10),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Mulai: 21 Sep 2023",
                  style: TextStyle(color: AppColors.textSecondary)),
              Text("Estimasi: 21 Mar 2024",
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          )
        ],
      ),
    );
  }

  // ================= HISTORY =================
  Widget _history() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "HISTORI SCREENING MINGGUAN",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        _historyCard(
          "Minggu 4",
          "ON TRACK",
          AppColors.success,
          "Batuk berkurang, nafsu makan membaik secara signifikan.",
          "12 Okt 2023",
        ),

        _historyCard(
          "Minggu 3",
          "PERLU PANTAUAN",
          AppColors.error,
          "Demam ringan di malam hari. Keluhan mual setelah minum obat.",
          "05 Okt 2023",
        ),

        _historyCard(
          "Minggu 2",
          "ON TRACK",
          AppColors.success,
          "Tidak ada keluhan berarti. Berat badan mulai stabil.",
          "28 Sep 2023",
        ),

        _historyCard(
          "Minggu 1",
          "ON TRACK",
          AppColors.success,
          "Awal masa pengobatan. Penyesuaian jadwal konsumsi obat.",
          "21 Sep 2023",
        ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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