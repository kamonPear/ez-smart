const List<String> kThaiMonthsShort = [
  'ม.ค.',
  'ก.พ.',
  'มี.ค.',
  'เม.ย.',
  'พ.ค.',
  'มิ.ย.',
  'ก.ค.',
  'ส.ค.',
  'ก.ย.',
  'ต.ค.',
  'พ.ย.',
  'ธ.ค.',
];

const List<String> kThaiMonthsFull = [
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];

/// "เดือน ปี พ.ศ." เต็ม เช่น กันยายน 2569 (ใช้กับหัวปฏิทิน/ตัวเลือกเดือนที่ไม่มีวัน)
String thaiMonthYear(DateTime date) {
  final thaiYear = date.year + 543;
  return '${kThaiMonthsFull[date.month - 1]} $thaiYear';
}

/// จัดรูปแบบวันที่เป็น "วันที่ เดือนย่อไทย ปี พ.ศ." เช่น 19 ส.ค. 2569
/// ใช้เป็นรูปแบบวันที่มาตรฐานของทั้งแอป
String thaiDate(DateTime date) {
  final thaiYear = date.year + 543;
  return '${date.day} ${kThaiMonthsShort[date.month - 1]} $thaiYear';
}

/// แปลงวันที่จาก String (ISO8601 หรือรูปแบบที่ DateTime.tryParse รองรับ)
/// เป็น "วันที่ เดือนย่อไทย ปี พ.ศ." ถ้าแปลงไม่ได้หรือเป็นค่าว่าง/ค่าว่างของ Go ("0001-01-01")
/// จะคืนค่า [fallback] แทน
String thaiDateFromIso(String? isoString, {String fallback = '-'}) {
  if (isoString == null || isoString.isEmpty) return fallback;
  final datePart = isoString.split('T').first;
  if (datePart == '0001-01-01' || datePart.isEmpty) return fallback;
  final date = DateTime.tryParse(isoString);
  if (date == null) return fallback;
  return thaiDate(date);
}
