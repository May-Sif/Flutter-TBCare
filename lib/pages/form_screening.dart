import 'package:flutter/material.dart';
import 'package:tbc_app/database/database_helper.dart';
import 'package:tbc_app/pages/hasil_screening.dart';

class FormScreeningPage extends StatefulWidget {
  final int? userId;

  const FormScreeningPage({super.key, this.userId});

  @override
  State<FormScreeningPage> createState() => _FormScreeningPageState();
}

class _FormScreeningPageState extends State<FormScreeningPage> {
  int? _answer1;
  int? _answer2;
  int? _answer3;
  int? _answer4;
  int? _answer5;
  int? _answer6;

  static const Color _primaryColor = Color(0xFF0D9488);
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;

  int get _answeredCount {
    int count = 0;
    if (_answer1 != null) count++;
    if (_answer2 != null) count++;
    if (_answer3 != null) count++;
    if (_answer4 != null) count++;
    if (_answer5 != null) count++;
    if (_answer6 != null) count++;
    return count;
  }

  // ── Gejala berat ──
  List<String> get _gejalaTinggi {
    final list = <String>[];
    if (_answer1 == 2) list.add('Batuk sama / memburuk');
    if (_answer2 == 2) list.add('Nyeri dada sering / berat');
    if (_answer3 == 2) list.add('Ada darah saat batuk');
    if (_answer4 == 2) list.add('Demam / keringat malam sering');
    if (_answer5 == 2) list.add('Sesak napas berat / saat istirahat');
    if (_answer6 == 2) list.add('Berat badan turun drastis');
    return list;
  }

  // ── Gejala sedang ──
  List<String> get _gejalaSedang {
    final list = <String>[];
    if (_answer1 == 1) list.add('Batuk berkurang');
    if (_answer2 == 1) list.add('Nyeri dada kadang-kadang');
    if (_answer3 == 1) list.add('Dahak biasa');
    if (_answer4 == 1) list.add('Demam / keringat malam kadang');
    if (_answer5 == 1) list.add('Sesak napas ringan');
    if (_answer6 == 1) list.add('Berat badan turun sedikit');
    return list;
  }

  bool get _adaRisikoTinggi => _gejalaTinggi.isNotEmpty;

  Future<void> _submit() async {
    final dbHelper = DatabaseHelper();
    final uid = widget.userId ?? dbHelper.getCurrentUserId();
    final today = DateTime.now().toIso8601String().split('T').first;

    final skor = [_answer1, _answer2, _answer3, _answer4, _answer5, _answer6]
        .fold<int>(0, (sum, a) => sum + (a ?? 0));

    final hasilData = {
      'skor': skor,
      'gejalaTinggi': _gejalaTinggi,
      'gejalaSedang': _gejalaSedang,
      'highRisk': _adaRisikoTinggi,
      'beratBadan': _answer6 == 0
          ? 'Stabil dalam 2 minggu terakhir.'
          : _answer6 == 1
              ? 'Turun sedikit, perlu dipantau.'
              : 'Turun drastis, segera konsultasikan.',
      'efekSamping': 'Tidak ada laporan efek samping baru.',
      'assessment': skor <= 2
          ? 'Kondisi umum baik. Lanjutkan pengobatan sesuai jadwal.'
          : skor <= 4
              ? 'Kondisi umum baik, namun ada gejala yang perlu dipantau. Pantau 1 minggu lagi.'
              : 'Gejala cukup signifikan. Segera konsultasikan ke dokter atau puskesmas.',
    };

    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HasilScreeningPage(
          hasilData: hasilData,
        ),
      ),
    );

    if (context.mounted) {
      Navigator.pop(context, {
        'sudahIsi': true,
        'gejalaTinggi': _gejalaTinggi,
        'gejalaSedang': _gejalaSedang,
        'highRisk': _adaRisikoTinggi,
        'skor': skor,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildQuestion(
                      number: 1,
                      icon: Icons.masks_outlined,
                      iconColor: const Color(0xFF6B7280),
                      question: 'Apakah batuk masih\ndirasakan minggu ini?',
                      options: const ['Tidak', 'Berkurang', 'Sama / Memburuk'],
                      selectedIndex: _answer1,
                      onChanged: (val) => setState(() => _answer1 = val),
                    ),
                    const SizedBox(height: 12),
                    _buildQuestion(
                      number: 2,
                      icon: Icons.favorite_border,
                      iconColor: const Color(0xFFF59E0B),
                      question: 'Apakah Anda merasakan\nnyeri dada?',
                      options: const ['Tidak', 'Kadang-kadang', 'Sering / Berat'],
                      selectedIndex: _answer2,
                      onChanged: (val) => setState(() => _answer2 = val),
                    ),
                    const SizedBox(height: 12),
                    _buildQuestion(
                      number: 3,
                      icon: Icons.water_drop_outlined,
                      iconColor: const Color(0xFF3B82F6),
                      question: 'Apakah masih ada dahak\nsaat batuk?',
                      options: const ['Tidak ada', 'Dahak biasa', 'Ada darah'],
                      selectedIndex: _answer3,
                      onChanged: (val) => setState(() => _answer3 = val),
                    ),
                    const SizedBox(height: 12),
                    _buildQuestion(
                      number: 4,
                      icon: Icons.thermostat_outlined,
                      iconColor: const Color(0xFFF97316),
                      question: 'Apakah masih mengalami\ndemam atau keringat\nmalam?',
                      options: const ['Tidak', 'Kadang-kadang', 'Sering'],
                      selectedIndex: _answer4,
                      onChanged: (val) => setState(() => _answer4 = val),
                    ),
                    const SizedBox(height: 12),
                    _buildQuestion(
                      number: 5,
                      icon: Icons.air_outlined,
                      iconColor: const Color(0xFF14B8A6),
                      question: 'Apakah sesak napas\ndirasakan saat beraktivitas?',
                      options: const ['Tidak', 'Ya, ringan', 'Ya, berat / saat istirahat'],
                      selectedIndex: _answer5,
                      onChanged: (val) => setState(() => _answer5 = val),
                    ),
                    const SizedBox(height: 12),
                    _buildQuestion(
                      number: 6,
                      icon: Icons.monitor_weight_outlined,
                      iconColor: const Color(0xFF8B5CF6),
                      question: 'Bagaimana kondisi berat\nbadan dibanding awal sakit?',
                      options: const ['Stabil / Naik', 'Turun sedikit', 'Turun drastis'],
                      selectedIndex: _answer6,
                      onChanged: (val) => setState(() => _answer6 = val),
                    ),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
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

  Widget _buildHeader() {
    return Container(
      color: _cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
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
            'SCREENING MINGGUAN',
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

  Widget _buildProgressBar() {
    final progress = _answeredCount / 6;
    return Container(
      color: _cardColor,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Progress Screening',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _primaryColor,
                ),
              ),
              const Spacer(),
              Text(
                '$_answeredCount dari 6 Pertanyaan',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion({
    required int number,
    required IconData icon,
    required Color iconColor,
    required String question,
    required List<String> options,
    required int? selectedIndex,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$number. $question',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(options.length, (i) {
            final isSelected = selectedIndex == i;
            return GestureDetector(
              onTap: () => onChanged(isSelected ? null : i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _primaryColor.withOpacity(0.06)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? _primaryColor : const Color(0xFFE5E7EB),
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? _primaryColor : const Color(0xFFD1D5DB),
                          width: isSelected ? 5 : 1.5,
                        ),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        options[i],
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? _primaryColor : const Color(0xFF374151),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final allAnswered = _answeredCount == 6;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: allAnswered ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          disabledBackgroundColor: const Color(0xFFD1D5DB),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          allAnswered ? 'Kirim Screening' : 'Jawab semua pertanyaan ($_answeredCount/6)',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}