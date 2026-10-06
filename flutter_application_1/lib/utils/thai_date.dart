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

/// แปลง ISO string จาก backend เป็นวันที่ล้วนๆ (ตัดเวลาทิ้ง) ตามเวลาไทย (+7 เสมอ)
/// คืน null ถ้าแปลงไม่ได้/เป็นค่าว่าง/ค่าว่างของ Go ("0001-01-01")
///
/// ไม่ใช้ DateTime.parse(...).toLocal() ตรงๆ เพราะเครื่องผู้ใช้อาจไม่ได้ตั้งโซน
/// เวลาเป็นไทยเสมอไป - แปลงด้วย offset คงที่ +7 ชม. แทน (ไทยไม่มี DST) ซึ่งตรงกับ
/// models.DateKey ฝั่ง backend พอดี ทำให้ทั้งแอปกับเว็บโชว์วันเดียวกันเสมอ ไม่ว่า
/// ค่าที่เก็บมาจะมีเวลาที่ไม่ใช่เที่ยงคืนติดมาหรือไม่ก็ตาม (เช่นแถวเก่าที่เคยถูก
/// บั๊กของเว็บเขียนด้วย Date.toISOString() ตรงๆ ซึ่งแปลงเที่ยงคืนไทยเป็น UTC จริง)
DateTime? thaiDateOnlyFromIso(String? isoString) {
  if (isoString == null || isoString.isEmpty) return null;
  if (isoString.startsWith('0001-01-01')) return null;
  final parsed = DateTime.tryParse(isoString);
  if (parsed == null) return null;
  final thai = parsed.isUtc
      ? parsed.add(const Duration(hours: 7))
      : parsed;
  return DateTime(thai.year, thai.month, thai.day);
}

/// แปลงวันที่จาก String (ISO8601 หรือรูปแบบที่ DateTime.tryParse รองรับ)
/// เป็น "วันที่ เดือนย่อไทย ปี พ.ศ." ถ้าแปลงไม่ได้หรือเป็นค่าว่าง/ค่าว่างของ Go ("0001-01-01")
/// จะคืนค่า [fallback] แทน
String thaiDateFromIso(String? isoString, {String fallback = '-'}) {
  final d = thaiDateOnlyFromIso(isoString);
  if (d == null) return fallback;
  return thaiDate(d);
}

/// อายุไก่นับจากวันเกิดถึงวันนี้ แบบอ่านง่าย เช่น "2 เดือน 1 สัปดาห์ 3 วัน"
/// (สูตรเดียวกับ formatChickenAge ฝั่งเว็บ - ดู coop-summary.util.ts) คืนค่าว่าง
/// ถ้าไม่มีวันเกิดหรือแปลงไม่ได้
String chickenAgeFromIso(String? birthdayIso) {
  final birth = thaiDateOnlyFromIso(birthdayIso);
  if (birth == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final totalDays = today.difference(birth).inDays;
  if (totalDays < 0) return '';

  final months = totalDays ~/ 30;
  final afterMonths = totalDays % 30;
  final weeks = afterMonths ~/ 7;
  final days = afterMonths % 7;

  final parts = <String>[];
  if (months > 0) parts.add('$months เดือน');
  if (weeks > 0) parts.add('$weeks สัปดาห์');
  if (days > 0 || parts.isEmpty) parts.add('$days วัน');
  return parts.join(' ');
}
