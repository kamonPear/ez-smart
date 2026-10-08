import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// แสดงไอคอนอุปกรณ์จาก SVG data URI ที่ backend ส่งมาตรงๆ (ฟิลด์ icon ของ
/// device/device_type) แทนที่จะเดาไอคอนจากชื่ออุปกรณ์เป็น Material Icon เอาเอง
/// แบบที่หน้าจอต่างๆ เคยทำ (เดาไม่ตรงกับที่เลือกไว้จริงฝั่งเว็บเลย เช่น "พัดลม"
/// เคยแมตช์กับ Icons.toys_outlined ซึ่งหน้าตาเหมือนของเล่น/รถ ไม่เหมือนพัดลม) -
/// ใช้ SVG ตัวเดียวกับที่เว็บเลือกไว้เป๊ะๆ เพราะมากับข้อมูล device ทุกตัวอยู่แล้ว
/// (ดู DEVICE_ICON_CHOICES ฝั่งเว็บ, src/app/shared/device-icon.util.ts) ไม่
/// override สีของ SVG เอง เพราะเว็บวาดด้วยสีเขียวคงที่ตัวเดียวอยู่แล้ว ให้มัน
/// ออกมาเหมือนกันเป๊ะๆ ทั้งสองแพลตฟอร์ม
class DeviceIcon extends StatelessWidget {
  const DeviceIcon({super.key, required this.iconDataUri, this.size = 20});

  final String? iconDataUri;
  final double size;

  // รูปแบบ "data:image/svg+xml;utf8,<url-encoded-svg>" ตัดส่วนหัวออกแล้ว decode
  // URI-encoding กลับเป็น SVG markup จริง - ฝั่งเว็บสร้างด้วย encodeURIComponent()
  // ครั้งเดียว (ดู svgIcon() ใน device-icon.util.ts) ไม่มี encode ซ้อนให้ต้อง
  // decode สองชั้น
  String? get _svgMarkup {
    final uri = iconDataUri;
    if (uri == null || uri.isEmpty) return null;
    const marker = ';utf8,';
    final idx = uri.indexOf(marker);
    if (!uri.startsWith('data:image/svg+xml') || idx == -1) return null;
    try {
      return Uri.decodeComponent(uri.substring(idx + marker.length));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final svg = _svgMarkup;
    if (svg == null) {
      // ยังไม่มีไอคอนมากับข้อมูล (เช่นแถวเก่าก่อนมีระบบนี้) - ใช้ไอคอนบอร์ดทั่วไป
      // แทนไว้ก่อน ดีกว่าไม่โชว์อะไรเลย
      return Icon(
        Icons.developer_board_outlined,
        size: size,
        color: Colors.grey,
      );
    }
    return SvgPicture.string(svg, width: size, height: size);
  }
}
