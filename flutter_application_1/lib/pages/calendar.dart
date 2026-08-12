import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // ชื่อเดือนแบบภาษาอังกฤษ
  String _getMonthName(int month) {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return months[month - 1];
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

    return Container(
      // 🌟 แก้ไข 1: ลด padding vertical จาก 20 เหลือ 15 เพื่อเพิ่มพื้นที่ให้ปฏิทิน
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF19232F),
        borderRadius: BorderRadius.circular(20),
      ),
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
                child: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              Text(
                '${_getMonthName(currentMonth.month)} ${currentMonth.year}',
                style: GoogleFonts.kanit(
                  color: Colors.white,
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
                child: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['MON', 'TUES', 'WEDNES', 'THURS', 'FRI', 'SATUR', 'SUN']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: GoogleFonts.kanit(
                          color: Colors.white,
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offset + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox();
              int day = index - offset + 1;

              // ... โค้ดส่วนอื่นๆ คงเดิม ...

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

              return GestureDetector(
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
                child: Container(
                  margin: const EdgeInsets.all(1.5),
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
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      // 🌟 5. แสดงจุดมาร์กสีเขียวเฉพาะวันที่มีข้อมูล
                      if (hasMarker)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 5,
                          height: 5,
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
                          height: 7,
                        ), // เผื่อพื้นที่ว่างไว้เท่ากัน เพื่อให้ตัวเลขอยู่ในระดับระนาบเดียวกันตลอด
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
