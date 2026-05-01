class ScreeningMingguan {
  int? id;
  int userId;
  DateTime tanggalScreening;
  int mingguKe;
  int skor;
  String status; // 'ON TRACK', 'PERLU_PEMANTAUAN', 'WASPADA', 'RISIKO_TINGGI'
  String kesimpulanHasil;

  ScreeningMingguan({
    this.id,
    required this.userId,
    required this.tanggalScreening,
    required this.mingguKe,
    required this.skor,
    required this.status,
    required this.kesimpulanHasil,
  });

  factory ScreeningMingguan.fromMap(Map<String, dynamic> map) {
    return ScreeningMingguan(
      id: map['id'],
      userId: map['user_id'],
      tanggalScreening: DateTime.parse(map['tanggal_screening']),
      mingguKe: map['minggu_ke'],
      skor: map['skor'],
      status: map['status'],
      kesimpulanHasil: map['kesimpulan_hasil'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'tanggal_screening': tanggalScreening.toIso8601String(),
      'minggu_ke': mingguKe,
      'skor': skor,
      'status': status,
      'kesimpulan_hasil': kesimpulanHasil,
    };
  }
}