class EfekSampingPasien {
  int? id;
  int userId;
  DateTime tanggal;
  int efekSampingId; // FK ke ListEfekSamping
  int skor;
  String? keterangan;

  EfekSampingPasien({
    this.id,
    required this.userId,
    required this.tanggal,
    required this.efekSampingId,
    required this.skor,
    this.keterangan,
  });

  factory EfekSampingPasien.fromMap(Map<String, dynamic> map) {
    return EfekSampingPasien(
      id: map['id'],
      userId: map['user_id'],
      tanggal: DateTime.parse(map['tanggal']),
      efekSampingId: map['efek_samping_id'],
      skor:map['skor'],
      keterangan: map['keterangan'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'tanggal': tanggal.toIso8601String(),
      'efek_samping_id': efekSampingId,
      'skor': skor,
      'keterangan': keterangan,
    };
  }
}