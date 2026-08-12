class Coop {
  final String id;
  final String name;
  final String importDate;
  final String count;
  final String birthDate;
  final String note;

  Coop({
    required this.id,
    required this.name,
    required this.importDate,
    required this.count,
    required this.birthDate,
    required this.note,
  });

  factory Coop.fromJson(Map<String, dynamic> json) {
    String id =
        json['CoopID']?.toString() ??
        json['coop_id']?.toString() ??
        json['id']?.toString() ??
        '';
    String name =
        json['name_coop']?.toString() ?? json['NameCoop']?.toString() ?? '';
    return Coop(
      id: id,
      name: name.trim().isNotEmpty ? name : id,
      importDate:
          json['date_adopt_animals']?.toString() ??
          json['DateAdoptAnimals']?.toString() ??
          json['importDate']?.toString() ??
          '',
      count:
          json['amount']?.toString() ??
          json['Amount']?.toString() ??
          json['count']?.toString() ??
          '',
      birthDate:
          json['birthday']?.toString() ??
          json['Birthday']?.toString() ??
          json['birthDate']?.toString() ??
          '',
      note: json['note']?.toString() ?? json['Note']?.toString() ?? '',
    );
  }

  // 🌟 แก้ให้ parse จาก id (String) เป็น int จริง ๆ แทนการ return null
  int? get coopId => int.tryParse(id);

  // 🌟 แก้ให้สร้างข้อความแสดงผลใน Dropdown จริง ๆ แทนการ return null
  String get displayLabel => 'คอก $name  (จำนวน $count ตัว)';

  Map<String, String> toMap() => {
    'id': id,
    'name': name,
    'importDate': importDate,
    'count': count,
    'birthDate': birthDate,
    'note': note,
  };
}
