import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/ez_header.dart';
import '../utils/thai_date.dart';

class CustomCalendar extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected; // ส่งค่ากลับเมื่อมีการเลือกวันที่
  final List<DateTime>?
  markedDates; // 🌟 1. เพิ่มตัวแปรสำหรับรับรายการวันที่ต้องการมาร์กจุด

  const CustomCalendar({
    super.key,
    required this.onDateSelected,
    this.initialDate,
    this.markedDates, // 🌟 2. เพิ่มใน Constructor
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

    return Expanded(
      child: GestureDetector(
        onTap: () {
          DateTime newSelected = DateTime(
            currentMonth.year,
            currentMonth.month,
            day,
          );
          setState(() {
            selectedDate = newSelected;
          });
          // ส่งค่าวันที่ที่เลือกกลับไปให้หน้าหลัก
          widget.onDateSelected(newSelected);
        },
        child: SizedBox(
          height: 36,
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF66E07A)
                    : Colors.transparent,
                shape: BoxShape.circle,
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
                  // 🌟 5. แสดงจุดมาร์กสีเขียวเฉพาะวันที่มีข้อมูล
                  if (hasMarker)
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        // ถ้าวันนั้นกำลังถูกเลือกอยู่ ให้จุดเปลี่ยนเป็นสีดำเพื่อให้ตัดกับพื้นหลังสีเขียวของปุ่ม
                        color: isSelected
                            ? Colors.black
                            : const Color(0xFF66E07A),
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
                onTap: () => setState(
                  () => currentMonth = DateTime(
                    currentMonth.year,
                    currentMonth.month - 1,
                    1,
                  ),
                ),
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
                onTap: () => setState(
                  () => currentMonth = DateTime(
                    currentMonth.year,
                    currentMonth.month + 1,
                    1,
                  ),
                ),
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
                    return const Expanded(child: SizedBox(height: 36));
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
