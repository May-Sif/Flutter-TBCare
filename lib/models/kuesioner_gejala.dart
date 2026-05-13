class KuesionerGejala {
  int? id;
  int userId;
  int skorBatuk; // 0,1,2
  int skorDahak; // 0,1,3
  int skorDemam; // 0,1,2
  int skorSesak; // 0,1,2
  int skorBeratBadan; // 0,1,2
  int totalSkorMentah;
  
  KuesionerGejala({
    this.id,
    required this.userId,
    required this.skorBatuk,
    required this.skorDahak,
    required this.skorDemam,
    required this.skorSesak,
    required this.skorBeratBadan,
    required this.totalSkorMentah,
  });

  factory KuesionerGejala.fromMap(Map<String, dynamic> map) {
    return KuesionerGejala(
      id: map['id'],
      userId: map['user_id'],
      skorBatuk: map['skor_batuk'],
      skorDahak: map['skor_dahak'],
      skorDemam: map['skor_demam'],
      skorSesak: map['skor_sesak'],
      skorBeratBadan: map['skor_berat_badan'],
      totalSkorMentah: map['total_skor_mentah'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'skor_batuk': skorBatuk,
      'skor_dahak': skorDahak,
      'skor_demam': skorDemam,
      'skor_sesak': skorSesak,
      'skor_berat_badan': skorBeratBadan,
      'total_skor_mentah': totalSkorMentah,
    };
  }
}