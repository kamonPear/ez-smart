import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/ez_header.dart';
import '../utils/thai_date.dart';

const Color kCalendarGreen = Color(0xFF66E07A);
const Color kCalendarRed = Color(0xFFE53935);
const Color kCalendarAmber = Color(0xFFFFA726);

/// ประเภทของรายการในปฏิทิน ใช้กำหนดไอคอน/ป้ายกำกับให้ดูออกทันทีว่าเป็นเรื่องอะไร
enum CalendarItemCategory { vaccine, health, birthday, adopt, appointment }

extension CalendarItemCategoryX on CalendarItemCategory {
  String get label => switch (this) {
    CalendarItemCategory.vaccine => 'วัคซีน',
    CalendarItemCategory.health => 'ตรวจสุขภาพ',
    CalendarItemCategory.birthday => 'วันเกิดไก่',
    CalendarItemCategory.adopt => 'รับเข้าเลี้ยง',
    CalendarItemCategory.appointment => 'นัดตรวจสุขภาพ',
  };

  IconData get icon => switch (this) {
    CalendarItemCategory.vaccine => Icons.vaccines_rounded,
    CalendarItemCategory.health => Icons.medical_services_rounded,
    CalendarItemCategory.birthday => Icons.cake_rounded,
    CalendarItemCategory.adopt => Icons.home_rounded,
    CalendarItemCategory.appointment => Icons.event_available_rounded,
  };
}

/// สถานะของรายการ ใช้แยกให้ชัดว่า "ทำแล้ว/แจ้งให้ทราบ" (เขียว), "นัดล่วงหน้า
/// ยังไม่ถึงกำหนด" (เหลือง) หรือ "เกินกำหนด ยังไม่ทำ" (แดง) เพื่อไม่ให้สับสน
/// กับวันที่ในอนาคตที่ยังไม่ถึงกำหนดจริง
enum CalendarItemStatus { done, upcoming, overdue, info }

extension CalendarItemStatusX on CalendarItemStatus {
  String get label => switch (this) {
    CalendarItemStatus.done => 'ทำแล้ว',
    CalendarItemStatus.upcoming => 'ยังไม่ถึงกำหนด',
    CalendarItemStatus.overdue => 'เกินกำหนด - ยังไม่ทำ',
    CalendarItemStatus.info => 'แจ้งให้ทราบ',
  };

  Color get color => switch (this) {
    CalendarItemStatus.done => kCalendarGreen,
    CalendarItemStatus.upcoming => kCalendarAmber,
    CalendarItemStatus.overdue => kCalendarRed,
    CalendarItemStatus.info => kCalendarGreen,
  };
}

/// รายการย่อยหนึ่งบรรทัดของวันนั้น เช่น "นิวคาสเซิล – คอกX"
/// category บอกว่าเป็นเรื่องอะไร (วัคซีน/ตรวจสุขภาพ/...) ส่วน status บอกสถานะ
/// เพื่อให้แสดงป้ายกำกับสี+ข้อความที่ชัดเจน แทนการเดาความหมายจากไอคอนอย่างเดียว
class DayDetailItem {
  final String text;
  final CalendarItemCategory category;
  final CalendarItemStatus status;
  // รหัสคอกที่รายการนี้เกี่ยวข้อง (ใช้กดแล้วพาไปหน้ารายละเอียดคอกนั้น) - null ถ้าไม่ผูกกับคอกไหน
  final String? coopId;

  const DayDetailItem({
    required this.text,
    required this.category,
    required this.status,
    this.coopId,
  });

  bool get isPending => status == CalendarItemStatus.overdue;
}

/// ข้อมูลมาร์กของวันหนึ่งๆ สำหรับปฏิทินรวม (สีจุด + รายละเอียดที่โชว์ตอนกดค้าง)
class DayMarkerInfo {
  final Color color;
  final List<DayDetailItem> details;

  const DayMarkerInfo({required this.color, required this.details});

  /// เลือกสีจุดของวันนั้นตามสถานะที่ "ร้ายแรงที่สุด" ในบรรดารายการของวัน:
  /// เกินกำหนด (แดง) > นัดล่วงหน้ายังไม่ถึงกำหนด (เหลือง) > ทำแล้ว/แจ้งให้ทราบ (เขียว)
  static Color colorForDetails(List<DayDetailItem> details) {
    if (details.any((d) => d.status == CalendarItemStatus.overdue)) {
      return kCalendarRed;
    }
    if (details.any((d) => d.status == CalendarItemStatus.upcoming)) {
      return kCalendarAmber;
    }
    return kCalendarGreen;
  }
}

/// เปิดปฏิทินแบบเดียวกับที่ใช้ทั้งแอป (CustomCalendar สีเขียว การ์ดเดียวกับหน้า
/// วัคซีน/ตรวจสุขภาพ/ปฏิทินรวม) เป็นป็อบอัพให้เลือกวันที่เดียว - ใช้แทน
/// showEzDatePicker (ปฏิทิน Material ของ Flutter เอง สีทอง หน้าตาต่างจากปฏิทิน
/// หลักของแอป) ในจุดที่อยากให้ตัวเลือกวันที่หน้าตาเหมือนปฏิทินอื่นๆ ในแอป
/// แตะวันที่แล้วปิดป็อบอัพพร้อมคืนค่าทันที ไม่ต้องกดยืนยันซ้ำอีกขั้น (พฤติกรรม
/// เดียวกับที่ CustomCalendar ทำอยู่แล้วตอนฝังอยู่ในหน้าเต็ม)
Future<DateTime?> showCustomCalendarPicker(
  BuildContext context, {
  DateTime? initialDate,
  String title = 'เลือกวันที่',
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) {
      final ez = ezColors(dialogContext);
      return Dialog(
        backgroundColor: ez.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kCalendarGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: kCalendarGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.kanit(
                        color: ez.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(dialogContext),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        color: ez.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomCalendar(
                initialDate: initialDate,
                onDateSelected: (day) => Navigator.pop(dialogContext, day),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class CustomCalendar extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected; // ส่งค่ากลับเมื่อมีการเลือกวันที่
  final List<DateTime>?
  markedDates; // 🌟 1. เพิ่มตัวแปรสำหรับรับรายการวันที่ต้องการมาร์กจุด
  final Map<DateTime, DayMarkerInfo>?
  dayMarkers; // 🌟 มาร์กแบบมีสี+รายละเอียด ใช้แยกจาก markedDates เพื่อไม่กระทบของเดิม
  final void Function(DateTime day, DayMarkerInfo marker)? onDayLongPress;
  // แจ้งหน้าที่เรียกใช้ว่าตอนนี้ผู้ใช้กำลังดูเดือนไหนอยู่ (กดลูกศรเปลี่ยนเดือน) -
  // ใช้ทำรายการสรุป "ของเดือนที่กำลังดูเป็นต้นไป" ให้ตรงกับเดือนที่เลื่อนดูจริงๆ
  final void Function(DateTime month)? onMonthChanged;

  const CustomCalendar({
    super.key,
    required this.onDateSelected,
    this.initialDate,
    this.markedDates, // 🌟 2. เพิ่มใน Constructor
    this.dayMarkers,
    this.onDayLongPress,
    this.onMonthChanged,
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime currentMonth;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    // ตั้งค่าวันเริ่มต้น
    selectedDate = widget.initialDate ?? DateTime.now();
    currentMonth = DateTime(selectedDate!.year, selectedDate!.month, 1);
    // แจ้งเดือนเริ่มต้นให้หน้าที่เรียกใช้รู้ด้วย (รอ frame แรกเสร็จก่อน กัน
    // setState ของ widget อื่นชนกับตอน initState/build ของตัวเองยังไม่เสร็จ)
    if (widget.onMonthChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onMonthChanged?.call(currentMonth);
      });
    }
  }

  Widget _buildDayCell(int day) {
    bool isSelected =
        selectedDate != null &&
        selectedDate!.year == currentMonth.year &&
        selectedDate!.month == currentMonth.month &&
        selectedDate!.day == day;

    // 🌟 3. ตรวจสอบว่าวันในช่องนี้ ตรงกับหนึ่งในวันที่ที่ถูกมาร์กมาหรือไม่
    bool hasMarker =
        widget.markedDates?.any(
          (markedDate) =>
              markedDate.year == currentMonth.year &&
              markedDate.month == currentMonth.month &&
              markedDate.day == day,
        ) ??
        false;

    final DateTime cellDate = DateTime(
      currentMonth.year,
      currentMonth.month,
      day,
    );
    final DayMarkerInfo? richMarker = widget.dayMarkers?[cellDate];

    final DateTime now = DateTime.now();
    final bool isToday =
        now.year == cellDate.year &&
        now.month == cellDate.month &&
        now.day == cellDate.day;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          DateTime newSelected = cellDate;
          setState(() {
            selectedDate = newSelected;
          });
          // ส่งค่าวันที่ที่เลือกกลับไปให้หน้าหลัก
          widget.onDateSelected(newSelected);
        },
        onLongPress: richMarker != null
            ? () => widget.onDayLongPress?.call(cellDate, richMarker)
            : null,
        child: SizedBox(
          height: 42,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected ? kCalendarGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: (!isSelected && isToday)
                    ? Border.all(color: kCalendarGreen, width: 1.4)
                    : null,
              ),
              child: Column(
                // 🌟 4. เปลี่ยนจาก Center เป็น Column เพื่อให้ใส่จุดใต้ตัวเลขได้
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.toString(),
                    style: GoogleFonts.kanit(
                      // เดิมใช้ Colors.white ตายตัว ตัวเลขเลยมองไม่เห็นเวลาการ์ด
                      // เป็นพื้นสว่าง (โหมดสว่าง) ต้องอิงสีตามธีมแทน
                      color: isSelected
                          ? Colors.black
                          : ezColors(context).textPrimary,
                      fontSize: 13,
                      height: 1.0,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  // 🌟 5. แสดงจุดมาร์ก - ถ้ามี dayMarkers (สีตามสถานะ) ให้ใช้สีนั้น
                  // ไม่งั้น fallback ไปใช้จุดเขียวตายตัวแบบเดิมจาก markedDates
                  if (richMarker != null)
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : richMarker.color,
                        shape: BoxShape.circle,
                      ),
                    )
                  else if (hasMarker)
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        // ถ้าวันนั้นกำลังถูกเลือกอยู่ ให้จุดเปลี่ยนเป็นสีดำเพื่อให้ตัดกับพื้นหลังสีเขียวของปุ่ม
                        color: isSelected ? Colors.black : kCalendarGreen,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(
                      height: 5,
                    ), // เผื่อพื้นที่ว่างไว้เท่ากัน เพื่อให้ตัวเลขอยู่ในระดับระนาบเดียวกันตลอด
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;
    int firstWeekday = DateTime(
      currentMonth.year,
      currentMonth.month,
      1,
    ).weekday;
    int offset = firstWeekday - 1;
    int totalCells = offset + daysInMonth;
    // 🌟 สร้างเป็น Column ของ Row เอง แทน GridView.builder(shrinkWrap:true)
    // เพราะ shrinkWrap GridView ที่ซ้อนอยู่ใน SingleChildScrollView หลายชั้นของหน้าที่เรียกใช้
    // คำนวณความสูงเกินจริง (เหลือพื้นที่ว่างเยอะผิดปกติไม่ว่าจะมีกี่แถว) ส่วน Column/Row
    // จะสูงเท่ากับเนื้อหาจริงเสมอ ไม่มีปัญหานี้
    int rowCount = (totalCells / 7).ceil();

    return Container(
      // 🌟 แก้ไข 1: ลด padding vertical จาก 20 เหลือ 15 เพื่อเพิ่มพื้นที่ให้ปฏิทิน
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: ezCardDecoration(context),
      child: Column(
        mainAxisSize: MainAxisSize
            .min, // 🌟 แก้ไข 2: เพิ่มบรรทัดนี้เพื่อให้ Column สูงพอดีกับเนื้อหาด้านใน
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(
                    () => currentMonth = DateTime(
                      currentMonth.year,
                      currentMonth.month - 1,
                      1,
                    ),
                  );
                  widget.onMonthChanged?.call(currentMonth);
                },
                child: Icon(
                  Icons.chevron_left,
                  color: ezColors(context).textPrimary,
                  size: 28,
                ),
              ),
              Text(
                thaiMonthYear(currentMonth),
                style: GoogleFonts.kanit(
                  color: ezColors(context).textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(
                    () => currentMonth = DateTime(
                      currentMonth.year,
                      currentMonth.month + 1,
                      1,
                    ),
                  );
                  widget.onMonthChanged?.call(currentMonth);
                },
                child: Icon(
                  Icons.chevron_right,
                  color: ezColors(context).textPrimary,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: GoogleFonts.kanit(
                          color: ezColors(context).textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          Column(
            children: List.generate(rowCount, (rowIndex) {
              return Row(
                children: List.generate(7, (colIndex) {
                  int cellIndex = rowIndex * 7 + colIndex;
                  if (cellIndex < offset || cellIndex >= totalCells) {
                    return const Expanded(child: SizedBox(height: 42));
                  }
                  int day = cellIndex - offset + 1;
                  return _buildDayCell(day);
                }),
              );
            }),
          ),
        ],
      ),
    );
  }
}
