// lib/pages/isi_dataobat.dart

import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';
import 'profile_page.dart';

class Medication {
  String name;
  TimeOfDay time;
  String? mealTiming;
  String? keterangan;
  
  Medication({
    required this.name,
    required this.time,
    this.mealTiming,
    this.keterangan,
  });
}

class SessionMedications {
  List<Medication> medications;
  
  SessionMedications({
    required this.medications,
  });
}

class IsiDataObatPage extends StatefulWidget {
  final Map<String, String> dataDiri;
  final List<Map<String, dynamic>>? existingJadwalObat;

  const IsiDataObatPage({
    super.key,
    required this.dataDiri,
    this.existingJadwalObat,
  });

  @override
  State<IsiDataObatPage> createState() => _IsiDataObatPageState();
}

class _IsiDataObatPageState extends State<IsiDataObatPage> {
  late SessionMedications _pagiMedications;
  late SessionMedications _siangMedications;
  late SessionMedications _malamMedications;
  
  @override
  void initState() {
    super.initState();
    
    // Start with empty medications
    _pagiMedications = SessionMedications(medications: []);
    _siangMedications = SessionMedications(medications: []);
    _malamMedications = SessionMedications(medications: []);
    
    // Jika ada jadwal obat yang sudah ada, load datanya
    if (widget.existingJadwalObat != null && widget.existingJadwalObat!.isNotEmpty) {
      _loadExistingJadwal(widget.existingJadwalObat!);
    }
  }

  void _loadExistingJadwal(List<Map<String, dynamic>> existingJadwal) {
    for (var obat in existingJadwal) {
      String sesi = obat['sesi'] ?? '';
      String namaObat = obat['namaObat'] ?? '';
      String waktuStr = obat['waktu'] ?? '07:00 AM';
      String waktuMakan = obat['waktuMakan'] ?? 'Setelah Makan';
      String keterangan = obat['keterangan'] ?? '';
      
      // Parse waktu string ke TimeOfDay
      TimeOfDay time = _parseTimeString(waktuStr);
      
      Medication newMed = Medication(
        name: namaObat,
        time: time,
        mealTiming: waktuMakan,
        keterangan: keterangan,
      );
      
      if (sesi == 'Pagi') {
        _pagiMedications.medications.add(newMed);
      } else if (sesi == 'Siang') {
        _siangMedications.medications.add(newMed);
      } else if (sesi == 'Malam') {
        _malamMedications.medications.add(newMed);
      }
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      // Format: "7:00 AM" atau "1:00 PM"
      List<String> parts = timeStr.split(' ');
      if (parts.length != 2) return const TimeOfDay(hour: 7, minute: 0);
      
      String timePart = parts[0];
      String period = parts[1];
      
      List<String> hourMinute = timePart.split(':');
      if (hourMinute.length != 2) return const TimeOfDay(hour: 7, minute: 0);
      
      int hour = int.parse(hourMinute[0]);
      int minute = int.parse(hourMinute[1]);
      
      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 7, minute: 0);
    }
  }

  Future<void> _selectTime(int sessionIndex, int medIndex) async {
    TimeOfDay currentTime = const TimeOfDay(hour: 7, minute: 0);
    
    if (sessionIndex == 0) {
      currentTime = _pagiMedications.medications[medIndex].time;
    } else if (sessionIndex == 1) {
      currentTime = _siangMedications.medications[medIndex].time;
    } else if (sessionIndex == 2) {
      currentTime = _malamMedications.medications[medIndex].time;
    }
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (sessionIndex == 0) {
          _pagiMedications.medications[medIndex].time = picked;
        } else if (sessionIndex == 1) {
          _siangMedications.medications[medIndex].time = picked;
        } else {
          _malamMedications.medications[medIndex].time = picked;
        }
      });
    }
  }

  void _addMedication(int sessionIndex) {
    setState(() {
      Medication newMed = Medication(
        name: '',
        time: const TimeOfDay(hour: 7, minute: 0),
        mealTiming: 'Setelah Makan',
        keterangan: '',
      );
      
      if (sessionIndex == 0) {
        _pagiMedications.medications.add(newMed);
      } else if (sessionIndex == 1) {
        _siangMedications.medications.add(newMed);
      } else if (sessionIndex == 2) {
        _malamMedications.medications.add(newMed);
      }
    });
  }

  void _removeMedication(int sessionIndex, int medIndex) {
    setState(() {
      if (sessionIndex == 0) {
        _pagiMedications.medications.removeAt(medIndex);
      } else if (sessionIndex == 1) {
        _siangMedications.medications.removeAt(medIndex);
      } else if (sessionIndex == 2) {
        _malamMedications.medications.removeAt(medIndex);
      }
    });
  }

  void _submit() {
    List<Map<String, dynamic>> jadwalObat = [];

    // Kumpulkan obat pagi
    for (var med in _pagiMedications.medications) {
      if (med.name.isNotEmpty) {
        jadwalObat.add({
          'sesi': 'Pagi',
          'namaObat': med.name,
          'waktu': _formatTimeOfDay(med.time),
          'waktuMakan': med.mealTiming ?? 'Setelah Makan',
          'keterangan': med.keterangan ?? '',
        });
      }
    }

    // Kumpulkan obat siang
    for (var med in _siangMedications.medications) {
      if (med.name.isNotEmpty) {
        jadwalObat.add({
          'sesi': 'Siang',
          'namaObat': med.name,
          'waktu': _formatTimeOfDay(med.time),
          'waktuMakan': med.mealTiming ?? 'Setelah Makan',
          'keterangan': med.keterangan ?? '',
        });
      }
    }

    // Kumpulkan obat malam
    for (var med in _malamMedications.medications) {
      if (med.name.isNotEmpty) {
        jadwalObat.add({
          'sesi': 'Malam',
          'namaObat': med.name,
          'waktu': _formatTimeOfDay(med.time),
          'waktuMakan': med.mealTiming ?? 'Setelah Makan',
          'keterangan': med.keterangan ?? '',
        });
      }
    }

    final semuaData = {
      'dataDiri': widget.dataDiri,
      'jadwalObat': jadwalObat,
    };

    // Jika sedang edit (ada existingJadwalObat), kembali ke halaman sebelumnya
    if (widget.existingJadwalObat != null) {
      Navigator.pop(context, semuaData);
    } else {
      // Jika baru, langsung ke halaman profil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilPage(dataPasien: semuaData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingJadwalObat != null;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          isEditing ? 'Edit Jadwal Obat' : 'Isi Data Obat',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jadwal Obat',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            
            // PAGI SECTION 
            const Text(
              'Pagi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            DashedBorderContainer(
              color: AppColors.textSecondary.withOpacity(0.5),
              strokeWidth: 1.5,
              dashLength: 6,
              dashGap: 4,
              radius: 12,
              child: _buildPagiSection(),
            ),
            const SizedBox(height: 24),
            
            // SIANG SECTION
            const Text(
              'Siang',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            DashedBorderContainer(
              color: AppColors.textSecondary.withOpacity(0.5),
              strokeWidth: 1.5,
              dashLength: 6,
              dashGap: 4,
              radius: 12,
              child: _buildSiangSection(),
            ),
            const SizedBox(height: 24),
            
            // MALAM SECTION
            const Text(
              'Malam',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            DashedBorderContainer(
              color: AppColors.textSecondary.withOpacity(0.5),
              strokeWidth: 1.5,
              dashLength: 6,
              dashGap: 4,
              radius: 12,
              child: _buildMalamSection(),
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing ? 'Simpan Perubahan' : 'Submit',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPagiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._pagiMedications.medications.asMap().entries.map((entry) {
          int medIndex = entry.key;
          Medication med = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 205, 225, 238),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: med.name,
                          decoration: const InputDecoration(
                            hintText: 'Nama Obat',
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,  
                            ),
                          ),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          onChanged: (value) {
                            setState(() {
                              _pagiMedications.medications[medIndex].name = value;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeMedication(0, medIndex),
                        icon: const Icon(Icons.close, size: 20, color: Color.fromARGB(255, 96, 26, 26)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => _selectTime(0, medIndex),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimeOfDay(med.time),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildRadioOption(
                                'Sebelum Makan',
                                med.mealTiming ?? 'Setelah Makan',
                                (value) {
                                  setState(() {
                                    _pagiMedications.medications[medIndex].mealTiming = value;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildRadioOption(
                                'Setelah Makan',
                                med.mealTiming ?? 'Setelah Makan',
                                (value) {
                                  setState(() {
                                    _pagiMedications.medications[medIndex].mealTiming = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: med.keterangan,
                    decoration: const InputDecoration(
                      hintText: 'Keterangan (Optional)',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                    onChanged: (value) {
                      setState(() {
                        _pagiMedications.medications[medIndex].keterangan = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        Center(
          child: TextButton.icon(
            onPressed: () => _addMedication(0),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Tambah Obat'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSiangSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._siangMedications.medications.asMap().entries.map((entry) {
          int medIndex = entry.key;
          Medication med = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 205, 225, 238),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: med.name,
                          decoration: const InputDecoration(
                            hintText: 'Nama Obat',
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,  
                            ),
                          ),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          onChanged: (value) {
                            setState(() {
                              _siangMedications.medications[medIndex].name = value;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeMedication(1, medIndex),
                        icon: const Icon(Icons.close, size: 20, color: Color.fromARGB(255, 96, 26, 26)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => _selectTime(1, medIndex),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimeOfDay(med.time),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildRadioOption(
                                'Sebelum Makan',
                                med.mealTiming ?? 'Setelah Makan',
                                (value) {
                                  setState(() {
                                    _siangMedications.medications[medIndex].mealTiming = value;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildRadioOption(
                                'Setelah Makan',
                                med.mealTiming ?? 'Setelah Makan',
                                (value) {
                                  setState(() {
                                    _siangMedications.medications[medIndex].mealTiming = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: med.keterangan,
                    decoration: const InputDecoration(
                      hintText: 'Keterangan (Optional)',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                    onChanged: (value) {
                      setState(() {
                        _siangMedications.medications[medIndex].keterangan = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        Center(
          child: TextButton.icon(
            onPressed: () => _addMedication(1),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Tambah Obat'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMalamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._malamMedications.medications.asMap().entries.map((entry) {
          int medIndex = entry.key;
          Medication med = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 205, 225, 238),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: med.name,
                          decoration: const InputDecoration(
                            hintText: 'Nama Obat',
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,  
                            ),
                          ),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          onChanged: (value) {
                            setState(() {
                              _malamMedications.medications[medIndex].name = value;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeMedication(2, medIndex),
                        icon: const Icon(Icons.close, size: 20, color: Color.fromARGB(255, 96, 26, 26)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => _selectTime(2, medIndex),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimeOfDay(med.time),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildRadioOption(
                                'Sebelum Makan',
                                med.mealTiming ?? 'Setelah Makan',
                                (value) {
                                  setState(() {
                                    _malamMedications.medications[medIndex].mealTiming = value;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildRadioOption(
                                'Setelah Makan',
                                med.mealTiming ?? 'Setelah Makan',
                                (value) {
                                  setState(() {
                                    _malamMedications.medications[medIndex].mealTiming = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: med.keterangan,
                    decoration: const InputDecoration(
                      hintText: 'Keterangan (Optional)',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                    onChanged: (value) {
                      setState(() {
                        _malamMedications.medications[medIndex].keterangan = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        Center(
          child: TextButton.icon(
            onPressed: () => _addMedication(2),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Tambah Obat'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRadioOption(String label, String groupValue, Function(String) onChanged) {
    return Row(
      children: [
        Radio<String>(
          value: label,
          groupValue: groupValue,
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
          activeColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
  
  String _formatTimeOfDay(TimeOfDay time) {
    int hour = time.hour;
    int minute = time.minute;
    String period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }
}

// Widget untuk border putus-putus
class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  
  const DashedBorderContainer({
    super.key,
    required this.child,
    this.radius = 12,
    this.color = Colors.grey,
    this.strokeWidth = 1,
    this.dashLength = 5,
    this.dashGap = 5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        dashGap: dashGap,
        radius: radius,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: AppColors.surface,
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  final double radius;
  
  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
    required this.radius,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    final path = Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ),
    );
    
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double start = 0;
      while (start < metric.length) {
        final extent = dashLength;
        final segment = metric.extractPath(start, start + extent);
        canvas.drawPath(segment, paint);
        start += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}