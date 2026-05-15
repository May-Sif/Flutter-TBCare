class RiwayatKepatuhan {
  int? id;
  int userId;
  DateTime tanggalMinum;
  int status; // 1 = sudah, 0 = belum
  int reminderDikirim; // 1 = sudah, 0 = belum

  RiwayatKepatuhan({
    this.id,
    required this.userId,
    required this.tanggalMinum,
    this.status = 0,
    this.reminderDikirim = 0,
  });

  factory RiwayatKepatuhan.fromMap(Map<String, dynamic> map) {
    return RiwayatKepatuhan(
      id: map['id'],
      userId: map['user_id'],
      tanggalMinum: DateTime.parse(map['tanggal_minum']),
      status: map['status_centang'],
      reminderDikirim: map['reminder_dikirim'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'tanggal_minum': tanggalMinum.toIso8601String(),
      'status_centang': status,
      'reminder_dikirim': reminderDikirim,
    };
  }
}