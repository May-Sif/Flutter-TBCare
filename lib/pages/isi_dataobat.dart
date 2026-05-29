// lib/pages/isi_dataobat.dart

import 'package:flutter/material.dart';
import 'package:tbc_app/pages/home_page.dart';
import 'package:tbc_app/theme.dart';
import 'profile_page.dart';
import '../database/database_helper.dart';

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
  final Map<String, String>? dataDiri;
  final List<Map<String, dynamic>>? existingJadwalObat;
  final int? userId;
  final String? email;
  final String? name;

  const IsiDataObatPage({
    super.key,
    this.dataDiri,
    this.existingJadwalObat,
    this.userId,
    this.email,
    this.name,
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
    
    _pagiMedications = SessionMedications(medications: []);
    _siangMedications = SessionMedications(medications: []);
    _malamMedications = SessionMedications(medications: []);
    
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

  // VALIDASI WAKTU BERDASARKAN SESI
  bool _isValidTimeForSession(String session, TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final totalMinutes = hour * 60 + minute;
    
    switch (session) {
      case 'Pagi':
        // Pagi: 00:00 - 10:59 (00:00 sampai 10:59)
        return totalMinutes <= 10 * 60 + 59;
        
      case 'Siang':
        // Siang: 11:00 - 14:59
        return totalMinutes >= 11 * 60 && totalMinutes <= 14 * 60 + 59;
        
      case 'Malam':
        // Malam: 15:00 - 23:59
        return totalMinutes >= 15 * 60;
        
      default:
        return true;
    }
  }

  String _getValidTimeRange(String session) {
    switch (session) {
      case 'Pagi':
        return '00:00 - 10:59';
      case 'Siang':
        return '11:00 - 14:59';
      case 'Malam':
        return '15:00 - 23:59';
      default:
        return '';
    }
  }

  Future<void> _selectTime(int sessionIndex, int medIndex) async {
    TimeOfDay currentTime = const TimeOfDay(hour: 7, minute: 0);
    String sessionName = '';
    
    if (sessionIndex == 0) {
      currentTime = _pagiMedications.medications[medIndex].time;
      sessionName = 'Pagi';
    } else if (sessionIndex == 1) {
      currentTime = _siangMedications.medications[medIndex].time;
      sessionName = 'Siang';
    } else if (sessionIndex == 2) {
      currentTime = _malamMedications.medications[medIndex].time;
      sessionName = 'Malam';
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
      // VALIDASI WAKTU
      if (!_isValidTimeForSession(sessionName, picked)) {
        final range = _getValidTimeRange(sessionName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Waktu untuk sesi $sessionName harus antara $range'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      
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

  Future<void> _saveRiwayatPerubahan(String obatLama, String obatBaru, String alasan) async {
    final dbHelper = DatabaseHelper();
    int? userId = widget.userId ?? dbHelper.getCurrentUserId();
    
    if (userId != null) {
      final tanggal = DateTime.now().toIso8601String().split('T').first;
      await dbHelper.insertRiwayatPerubahanObat(
        userId: userId,
        tanggal: tanggal,
        obatLama: obatLama,
        obatBaru: obatBaru,
        alasan: alasan,
      );
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

  // VALIDASI SEBELUM SUBMIT
  bool _validateAllTimes() {
    // Validasi sesi Pagi
    for (var med in _pagiMedications.medications) {
      if (med.name.isNotEmpty && !_isValidTimeForSession('Pagi', med.time)) {
        final range = _getValidTimeRange('Pagi');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Obat "${med.name}" (Pagi) harus antara $range'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    
    // Validasi sesi Siang
    for (var med in _siangMedications.medications) {
      if (med.name.isNotEmpty && !_isValidTimeForSession('Siang', med.time)) {
        final range = _getValidTimeRange('Siang');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Obat "${med.name}" (Siang) harus antara $range'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    
    // Validasi sesi Malam
    for (var med in _malamMedications.medications) {
      if (med.name.isNotEmpty && !_isValidTimeForSession('Malam', med.time)) {
        final range = _getValidTimeRange('Malam');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Obat "${med.name}" (Malam) harus antara $range'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    
    return true;
  }

  void _submit() async {
    // Validasi semua waktu terlebih dahulu
    if (!_validateAllTimes()) {
      return;
    }
    
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

    Map<String, dynamic> dataDiriDynamic = {};
    if (widget.dataDiri != null) {
      dataDiriDynamic = Map<String, dynamic>.from(widget.dataDiri!);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dbHelper = DatabaseHelper();
      
      int userId = await dbHelper.saveCompleteUserData(
        dataDiriDynamic,
        jadwalObat,
        email: widget.email,
      );
      
      dbHelper.setLoggedInUser(userId);
      
      if (!mounted) return;
      Navigator.pop(context);
      
      String namaPasien = '';
      if (widget.dataDiri != null && widget.dataDiri!['nama'] != null) {
        namaPasien = widget.dataDiri!['nama']!;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            email: widget.email ?? '',
            name: widget.name ?? namaPasien,
            photoUrl: null,
            userId: userId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data: $e'),
          backgroundColor: Colors.red,
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

// Widget untuk border putus-putus (sama seperti sebelumnya)
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