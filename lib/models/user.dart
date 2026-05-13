class User {
  int? id;
  String email;
  String password;
  String nama;
  int umur;
  DateTime tanggalDiagnosis;
  String jenisTbc; // 'paru_bta_positif', 'paru_bta_negatif', 'kelenjar', 'lainnya'
  String? statusHiv; // 'positif', 'negatif', 'tidak_tahu'

  User({
    this.id,
    required this.email,
    required this.password,
    required this.nama,
    required this.umur,
    required this.tanggalDiagnosis,
    required this.jenisTbc,
    this.statusHiv,
  });

  // Konversi dari Map (hasil query SQLite) ke Object User
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      password: map['password'],
      nama: map['nama'],
      umur: map['umur'],
      tanggalDiagnosis: DateTime.parse(map['tanggal_diagnosis']),
      jenisTbc: map['jenis_tbc'],
      statusHiv: map['status_hiv'],
    );
  }

  // Konversi dari Object User ke Map (untuk insert/update ke SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'nama': nama,
      'umur': umur,
      'tanggal_diagnosis': tanggalDiagnosis.toIso8601String(),
      'jenis_tbc': jenisTbc,
      'status_hiv': statusHiv,
    };
  }
}