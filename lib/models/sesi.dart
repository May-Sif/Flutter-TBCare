class Sesi {
  int? id;
  int jadwalId;        // Ganti dari userId dan jadwal_Id
  String namaSesi;     // 'pagi', 'siang', 'malam'
  String namaObat;     // 'Rifampisin', 'INH', dll
  String waktu;        // format 'HH:MM'
  String? waktuMakan;  // 'Sebelum Makan' / 'Setelah Makan'
  String? keterangan;  // keterangan tambahan
  int status;          // 1 = aktif, 0 = tidak aktif (optional)

  Sesi({
    this.id,
    required this.jadwalId,
    required this.namaSesi,
    required this.namaObat,
    required this.waktu,
    this.waktuMakan,
    this.keterangan,
    this.status = 1,
  });

  factory Sesi.fromMap(Map<String, dynamic> map) {
    return Sesi(
      id: map['id'],
      jadwalId: map['jadwal_id'],
      namaSesi: map['nama_sesi'],
      namaObat: map['nama_obat'],
      waktu: map['waktu'],
      waktuMakan: map['waktu_makan'],
      keterangan: map['keterangan'],
      status: map['status'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jadwal_id': jadwalId,
      'nama_sesi': namaSesi,
      'nama_obat': namaObat,
      'waktu': waktu,
      'waktu_makan': waktuMakan,
      'keterangan': keterangan,
      'status': status,
    };
  }
}