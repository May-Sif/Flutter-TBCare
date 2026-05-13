// lib/pages/isi_datadiri.dart

import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';
import 'isi_dataobat.dart';

class IsiDataDiriPage extends StatefulWidget {
  final Map<String, String>? existingData;
  
  const IsiDataDiriPage({
    super.key,
    this.existingData,
  });

  @override
  State<IsiDataDiriPage> createState() => _IsiDataDiriPageState();
}

class _IsiDataDiriPageState extends State<IsiDataDiriPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _umurController;
  late TextEditingController _tanggalDiagnosisController;

  late String _selectedTipeTbc;
  late String _selectedStatusHiv;
  late String _selectedTahapPengobatan;
  late String _selectedMasaPengobatan;

  final List<String> _tipeTbcOptions = [
    'TBC Paru (BTA positif)',
    'TBC Paru (BTA negatif)',
    'TBC Kelenjar',
    'TBC Tulang',
    'TBC Lainnya',
  ];

  final List<String> _statusHivOptions = [
    'Negatif',
    'Positif',
    'Tidak tahu',
  ];

  final List<String> _tahapPengobatanOptions = [
    'Tahap Intensif',
    'Tahap Lanjutan',
    'Selesai Pengobatan',
  ];

  final List<String> _masaPengobatanOptions = [
    '6 bulan',
    '9 bulan',
    '12 bulan',
    '18 bulan',
  ];

  @override
  void initState() {
    super.initState();
    
    // Inisialisasi controller dengan data yang ada (jika ada)
    _namaController = TextEditingController(text: widget.existingData?['nama'] ?? '');
    _umurController = TextEditingController(text: widget.existingData?['umur'] ?? '');
    _tanggalDiagnosisController = TextEditingController(text: widget.existingData?['tanggalDiagnosis'] ?? '');
    
    // Ambil nilai dari existing data
    String existingTipeTbc = widget.existingData?['tipeTbc'] ?? 
                             widget.existingData?['jenisTbc'] ?? 
                             'TBC Paru (BTA positif)';
    
    String existingStatusHiv = widget.existingData?['statusHiv'] ?? 'Negatif';
    String existingTahapPengobatan = widget.existingData?['tahapPengobatan'] ?? 'Tahap Intensif';
    String existingMasaPengobatan = widget.existingData?['masaPengobatan'] ?? '6 bulan';

    // Inisialisasi pilihan dengan data yang ada
    _selectedTipeTbc = _tipeTbcOptions.contains(existingTipeTbc) 
        ? existingTipeTbc 
        : 'TBC Paru (BTA positif)';
        
    _selectedStatusHiv = _statusHivOptions.contains(existingStatusHiv) 
        ? existingStatusHiv 
        : 'Negatif';
        
    _selectedTahapPengobatan = _tahapPengobatanOptions.contains(existingTahapPengobatan) 
        ? existingTahapPengobatan 
        : 'Tahap Intensif';
        
    _selectedMasaPengobatan = _masaPengobatanOptions.contains(existingMasaPengobatan) 
        ? existingMasaPengobatan 
        : '6 bulan';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _umurController.dispose();
    _tanggalDiagnosisController.dispose();
    super.dispose();
  }

  Future<void> _selectTanggalDiagnosis(BuildContext context) async {
    // Parse tanggal yang ada untuk initial date
    DateTime initialDate = DateTime.now();
    if (_tanggalDiagnosisController.text.isNotEmpty) {
      try {
        List<String> parts = _tanggalDiagnosisController.text.split('/');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (e) {
        // Jika parsing gagal, gunakan tanggal sekarang
      }
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
        _tanggalDiagnosisController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Kumpulkan data yang sudah diisi
    final updatedData = {
      'nama': _namaController.text,
      'umur': _umurController.text,
      'tanggalDiagnosis': _tanggalDiagnosisController.text,
      'tipeTbc': _selectedTipeTbc,
      'statusHiv': _selectedStatusHiv,
      'tahapPengobatan': _selectedTahapPengobatan,
      'masaPengobatan': _selectedMasaPengobatan,
    };

    // Jika ada data existing (sedang edit), kembali ke halaman sebelumnya dengan data baru
    if (widget.existingData != null) {
      Navigator.pop(context, updatedData);
    } else {
      // Jika tidak ada data existing (tambah baru), lanjut ke halaman obat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IsiDataObatPage(
            dataDiri: updatedData,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingData != null;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          isEditing ? 'Edit Data Diri' : 'Isi Data Diri',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nama Lengkap',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan Nama Lengkap',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Umur',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _umurController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Tahun',
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Umur tidak boleh kosong';
                            if (int.tryParse(v) == null) return 'Masukkan angka yang valid';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal Diagnosis',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _selectTanggalDiagnosis(context),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: _tanggalDiagnosisController,
                              decoration: const InputDecoration(
                                hintText: 'dd/mm/yyyy',
                                hintStyle: TextStyle(color: AppColors.textSecondary),
                                suffixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Tanggal diagnosis tidak boleh kosong' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Status Medis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'TIPE TBC',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTipeTbc,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: _tipeTbcOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTipeTbc = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'STATUS HIV',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatusHiv,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: _statusHivOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStatusHiv = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'TAHAP PENGOBATAN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTahapPengobatan,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: _tahapPengobatanOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTahapPengobatan = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'MASA PENGOBATAN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMasaPengobatan,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: _masaPengobatanOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMasaPengobatan = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 48),

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
      ),
    );
  }
}