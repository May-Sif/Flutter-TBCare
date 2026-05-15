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
      userId: map['user_Id'],
      status: int.parse(map['status'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_Id': userId,
      'status': status.toString(),
    };
  }
}