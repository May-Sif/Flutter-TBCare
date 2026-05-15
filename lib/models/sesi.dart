class Sesi {
  int? id;
  int userId;
  String namaSesi; // 'pagi', 'siang', 'malam'
  String namaObat; // 'Rifampisin', 'INH', dll
  String waktu; // format 'HH:MM'
  int status; // 1 = aktif, 0 = tidak aktif
  int jadwal_Id;

  Sesi({
    this.id,
    required this.userId,
    required this.namaSesi,
    required this.namaObat,
    required this.waktu,
    this.status = 1,
    required this.jadwal_Id,
  });

  factory Sesi.fromMap(Map<String, dynamic> map) {
    return Sesi(
      id: map['id'],
      userId: map['user_id'],
      namaSesi: map['nama_sesi'],
      namaObat: map['nama_obat'],
      waktu: map['waktu'],
      status: map['status'],
      jadwal_Id: map['jadwal_Id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'nama_sesi': namaSesi,
      'nama_obat': namaObat,
      'waktu': waktu,
      'status': status,
      'jadwal_Id': jadwal_Id,
    };
  }
}