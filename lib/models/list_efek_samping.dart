class ListEfekSamping {
  int? id;
  String namaEfekSamping;
  int skor; // FK ke SkorEfekSamping

  ListEfekSamping({
    this.id,
    required this.namaEfekSamping,
    required this.skor,
  });

  factory ListEfekSamping.fromMap(Map<String, dynamic> map) {
    return ListEfekSamping(
      id: map['id'],
      namaEfekSamping: map['nama_efek_samping'],
      skor: map['skor'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_efek_samping': namaEfekSamping,
      'skor': skor,
    };
  }
}