class SesiRiwayat {
  int? id;
  String namaSesi; // 'pagi', 'siang', 'malam'
  int status; // 1 = aktif, 0 = tidak aktif
  int riwayatKepatuhanId;
  int reminderDikirim;

  SesiRiwayat({
    this.id,
    required this.namaSesi,
    this.status = 1,
    required this.riwayatKepatuhanId,
    required this.reminderDikirim
  });

  factory SesiRiwayat.fromMap(Map<String, dynamic> map) {
    return SesiRiwayat(
      id: map['id'],
      namaSesi: map['nama_sesi'],
      status: map['status'],
      riwayatKepatuhanId: map['riwayat_kepatuhan_id'],
      reminderDikirim: map['reminderDikirim']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_sesi': namaSesi,
      'status': status,
      'riwayat_kepatuhan_id': riwayatKepatuhanId,
      'reminderDikirim': reminderDikirim
    };
  }
}