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
  // ✅ อ่านปี-เดือน-วันตรงๆ จากสตริง ไม่ผ่าน DateTime.parse
  // เพราะ backend ส่งวันที่แบบมี offset เช่น "+07:00" ซึ่ง Dart จะแปลงเป็น UTC
  // ภายในให้อัตโนมัติ (เลื่อนถอยหลัง 7 ชม.) ทำให้ .day ที่อ่านได้ผิดไปวันนึง
  // ถ้าไม่เรียก .toLocal() ก่อน — ตัดปัญหานี้ทิ้งไปเลยด้วยการไม่พึ่ง DateTime
  final parts = datePart.split('-');
  if (parts.length != 3) return fallback;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return fallback;
  if (month < 1 || month > 12) return fallback;
  final thaiYear = year + 543;
  return '$day ${kThaiMonthsShort[month - 1]} $thaiYear';
}
