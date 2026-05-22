import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';
import 'package:tbc_app/widgets/app_bottom_nav.dart';

class DetailEfekSampingPage extends StatefulWidget {
  final int? userId;

  const DetailEfekSampingPage({super.key, this.userId});

  @override
  State<DetailEfekSampingPage> createState() => _DetailEfekSampingPageState();
}

class _DetailEfekSampingPageState extends State<DetailEfekSampingPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER - DIPERKECIL
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                        child: const Icon(
                          Icons.arrow_back,
                          size: 24,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "DETAIL EFEK SAMPING",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // BULAN - DIPERKECIL
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Oktober 2023",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // DATE LIST - TINGGI DIKURANGI
              SizedBox(
                height: 95,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: const [
                    DateCard(
                      dayName: "Ming",
                      date: "12",
                      isChecked: true,
                    ),
                    SizedBox(width: 8),
                    DateCard(
                      dayName: "Sen",
                      date: "13",
                      isWarning: true,
                    ),
                    SizedBox(width: 8),
                    DateCard(
                      dayName: "Sel",
                      date: "14",
                      isWarning: true,
                    ),
                    SizedBox(width: 8),
                    DateCard(
                      dayName: "Rab",
                      date: "15",
                      isSelected: true,
                    ),
                    SizedBox(width: 8),
                    DateCard(
                      dayName: "Kam",
                      date: "16",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // GEJALA HARI INI - DIPERKECIL
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
                    children: const [
                      Text(
                        "Gejala Hari ini",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 14),
                      SymptomCard(
                        title: "Mual Ringan",
                      ),
                      SizedBox(height: 12),
                      SymptomCard(
                        title: "Pusing",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // RIWAYAT - DIPERKECIL
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Riwayat Perubahan Obat",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Text(
                          "Lihat Semua",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // TIMELINE
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 220,
                              color: AppColors.primaryLight,
                            ),
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            children: const [
                              HistoryCard(
                                date: "10 Mei 2024",
                                title: "Perubahan Protokol Fase Lanjutan",
                                description:
                                    "Rifampisin diganti ke Isoniazid karena mual berat yang tidak kunjung reda selama 3 hari berturut-turut.",
                              ),
                              SizedBox(height: 20),
                              HistoryCard(
                                date: "22 April 2024",
                                title: "Penyesuaian Dosis",
                                description:
                                    "Dosis Ethambutol dikurangi 250mg sesuai dengan berat badan pasien yang menurun.",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// DateCard - UKURAN LEBIH KECIL
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
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryLight,
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayName,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          if (isChecked)
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 20,
            )
          else if (isWarning)
            const Icon(
              Icons.sync_problem,
              color: Colors.orange,
              size: 18,
            )
          else
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// SymptomCard - UKURAN LEBIH KECIL
class SymptomCard extends StatelessWidget {
  final String title;

  const SymptomCard({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardProfil, // Menggunakan warna yang sudah ada di AppColors
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// HistoryCard - UKURAN LEBIH KECIL
class HistoryCard extends StatelessWidget {
  final String date;
  final String title;
  final String description;

  const HistoryCard({
    super.key,
    required this.date,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardProfil,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}