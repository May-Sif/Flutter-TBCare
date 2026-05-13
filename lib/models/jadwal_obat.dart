class JadwalObat {
  int? id;
  int userId;
  int status;

  JadwalObat({
    this.id,
    required this.userId,
    this.status = 1,
  });

  factory JadwalObat.fromMap(Map<String, dynamic> map) {
    return JadwalObat(
      id: map['id'],
      userId: map['userId'],
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'status': status,
    };
  }
}