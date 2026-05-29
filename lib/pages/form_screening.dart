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
  int? _answer1; // batuk: 0=Tidak, 1=Berkurang, 2=Sama/memburuk
  int? _answer2; // nyeri dada: 0=Tidak, 1=Kadang, 2=Sering
  int? _answer3; // dahak: 0=Tidak ada, 1=Dahak biasa, 3=Ada darah (special!)
  int? _answer4; // demam: 0=Tidak, 1=Kadang, 2=Sering
  int? _answer5; // sesak: 0=Tidak, 1=Ringan, 2=Berat
  int? _answer6; // berat badan: 0=Stabil, 1=Turun sedikit, 2=Turun drastis
  bool _isSubmitting = false;

  static const Color _primaryColor = Color(0xFF0D9488);
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;

  // Bobot persentase (dalam desimal) - Hanya untuk perhitungan internal
  double get _bobot1 => 0.15;
  double get _bobot2 => 0.10;
  double get _bobot3 => 0.20;
  double get _bobot4 => 0.15;
  double get _bobot5 => 0.10;
  double get _bobot6 => 0.15;

  bool get _adaDahakBerdarah => _answer3 == 3;

  double get _weightedScore {
    double score = 0;
    
    if (_answer1 != null) score += (_answer1! * _bobot1);
    if (_answer2 != null) score += (_answer2! * _bobot2);
    if (_answer3 != null) score += (_answer3! * _bobot3);
    if (_answer4 != null) score += (_answer4! * _bobot4);
    if (_answer5 != null) score += (_answer5! * _bobot5);
    if (_answer6 != null) score += (_answer6! * _bobot6);
    
    return score;
  }

  double get _maxWeightedScore => 1.9;
  
  double get _severityPercentage => (_weightedScore / _maxWeightedScore) * 100;

  String get _finalStatus {
    if (_adaDahakBerdarah) return 'RISIKO_TINGGI';
    
    double percentage = _severityPercentage;
    if (percentage <= 25) return 'ON_TRACK';
    if (percentage <= 50) return 'PERLU_PEMANTAUAN';
    if (percentage <= 75) return 'WASPADA';
    return 'RISIKO_TINGGI';
  }

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

  List<String> get _gejalaTinggi {
    final list = <String>[];
    if (_answer1 == 2) list.add('Batuk sama / memburuk');
    if (_answer2 == 2) list.add('Nyeri dada sering / berat');
    if (_answer3 == 3) list.add('Ada darah saat batuk ⚠️');
    if (_answer4 == 2) list.add('Demam / keringat malam sering');
    if (_answer5 == 2) list.add('Sesak napas berat / saat istirahat');
    if (_answer6 == 2) list.add('Berat badan turun drastis');
    return list;
  }

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

  bool get _adaRisikoTinggi => _gejalaTinggi.isNotEmpty || _adaDahakBerdarah;

  String _getKesimpulanHasil() {
    if (_adaDahakBerdarah) {
      return '⚠️ Ditemukan dahak berdarah! Segera konsultasikan ke dokter.';
    }
    
    double percentage = _severityPercentage;
    if (percentage <= 25) {
      return 'Kondisi umum baik. Batuk berkurang, nafsu makan membaik secara signifikan.';
    } else if (percentage <= 50) {
      String gejala = _gejalaSedang.isNotEmpty ? _gejalaSedang.join(', ') : 'Beberapa gejala masih terasa';
      return '$gejala. Perlu pemantauan lebih lanjut.';
    } else if (percentage <= 75) {
      String gejala = _gejalaTinggi.isNotEmpty ? _gejalaTinggi.join(', ') : 'Gejala cukup signifikan';
      return '$gejala. Segera konsultasikan ke dokter.';
    } else {
      return '⚠️ Risiko tinggi! Segera konsultasikan ke dokter.';
    }
  }

  Future<void> _submit() async {
    if (_answeredCount < 6) return;
    
    setState(() => _isSubmitting = true);
    
    final dbHelper = DatabaseHelper();
    final uid = widget.userId ?? dbHelper.getCurrentUserId();
    
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User tidak ditemukan')),
      );
      setState(() => _isSubmitting = false);
      return;
    }
    
    final now = DateTime.now();
    final today = now.toIso8601String().split('T').first;
    final skor = _weightedScore;
    final status = _finalStatus;
    final kesimpulanHasil = _getKesimpulanHasil();
    
    int mingguKe = 1;
    final user = await dbHelper.getUserById(uid);
    if (user != null && user['tanggal_diagnosis'] != null) {
      try {
        String tglDiagnosisStr = user['tanggal_diagnosis'];
        DateTime tglDiagnosis;
        
        if (tglDiagnosisStr.contains('/')) {
          List<String> parts = tglDiagnosisStr.split('/');
          if (parts.length == 3) {
            int day = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int year = int.parse(parts[2]);
            if (year < 100) year += 2000;
            tglDiagnosis = DateTime(year, month, day);
          } else {
            tglDiagnosis = now;
          }
        } else if (tglDiagnosisStr.contains('-')) {
          tglDiagnosis = DateTime.parse(tglDiagnosisStr);
        } else {
          tglDiagnosis = now;
        }
        
        mingguKe = (now.difference(tglDiagnosis).inDays / 7).floor() + 1;
        mingguKe = mingguKe.clamp(1, 24);
      } catch (e) {
        print('Error parsing tanggal diagnosis: $e');
        mingguKe = 1;
      }
    }
    
    try {
      final db = await dbHelper.database;
      await db.insert('screening_mingguan', {
        'user_id': uid,
        'tanggal_screening': today,
        'minggu_ke': mingguKe,
        'skor': skor,
        'status': status,
        'kesimpulan_hasil': kesimpulanHasil,
      });
      
      if (_gejalaTinggi.isNotEmpty || _gejalaSedang.isNotEmpty) {
        final semuaGejala = [..._gejalaTinggi, ..._gejalaSedang];
        for (var gejala in semuaGejala) {
          await db.insert('efek_samping', {
            'user_id': uid,
            'tanggal': today,
            'efek': gejala,
          });
        }
      }
      
      final hasilData = {
        'skor': _severityPercentage.toStringAsFixed(1),
        'skorMentah': _weightedScore.toStringAsFixed(2),
        'maxSkor': _maxWeightedScore.toStringAsFixed(2),
        'gejalaTinggi': _gejalaTinggi,
        'gejalaSedang': _gejalaSedang,
        'highRisk': _adaRisikoTinggi,
        'adaDahakBerdarah': _adaDahakBerdarah,
        'beratBadan': _answer6 == 0
            ? 'Stabil dalam 2 minggu terakhir.'
            : _answer6 == 1
                ? 'Turun sedikit, perlu dipantau.'
                : 'Turun drastis, segera konsultasikan.',
        'gejala': _gejalaTinggi.isNotEmpty 
            ? _gejalaTinggi.join(', ')
            : (_gejalaSedang.isNotEmpty ? _gejalaSedang.join(', ') : 'Tidak ada gejala yang dilaporkan'),
        'assessment': kesimpulanHasil,
      };

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HasilScreeningPage(
            hasilData: hasilData,
          ),
        ),
      );

      if (mounted) {
        Navigator.pop(context, {
          'sudahIsi': true,
          'gejalaTinggi': _gejalaTinggi,
          'gejalaSedang': _gejalaSedang,
          'highRisk': _adaRisikoTinggi,
          'skor': _severityPercentage,
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
                      options: const ['Tidak ada', 'Dahak biasa', '⚠️ Ada darah'],
                      selectedIndex: _answer3,
                      onChanged: (val) => setState(() => _answer3 = val),
                      isHighlight: true,
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
    bool isHighlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isHighlight && selectedIndex == 2 && options[2].contains('Darah')
            ? Border.all(color: Colors.red, width: 1.5)
            : null,
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
            final isDangerOption = isHighlight && i == 2;
            
            return GestureDetector(
              onTap: () => onChanged(isSelected ? null : i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDangerOption ? Colors.red.withOpacity(0.1) : _primaryColor.withOpacity(0.06))
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? (isDangerOption ? Colors.red : _primaryColor)
                        : const Color(0xFFE5E7EB),
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
                          color: isSelected
                              ? (isDangerOption ? Colors.red : _primaryColor)
                              : const Color(0xFFD1D5DB),
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
                          color: isSelected
                              ? (isDangerOption ? Colors.red : _primaryColor)
                              : const Color(0xFF374151),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
        onPressed: allAnswered && !_isSubmitting ? _submit : null,
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
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                allAnswered 
                    ? 'Kirim Screening' 
                    : 'Jawab semua pertanyaan ($_answeredCount/6)',
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