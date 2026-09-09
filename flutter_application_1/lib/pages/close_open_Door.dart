import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottombar.dart';
import '../widgets/ez_header.dart';
import '../widgets/ez_confirm_dialog.dart';

class CloseOpenDoor extends StatefulWidget {
  const CloseOpenDoor({super.key});

  @override
  State<CloseOpenDoor> createState() => _CloseOpenDoorState();
}

class _CloseOpenDoorState extends State<CloseOpenDoor> {
  int selectedIndex = 1;

  List<Map<String, dynamic>> doors = List.generate(
    5,
    (index) => {"id": index + 1, "isOn": false},
  );

  int nextDoorId = 6;

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()),
      );
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  void _addNewDoor() {
    setState(() {
      doors.add({"id": nextDoorId++, "isOn": false});
    });
  }

  Future<void> _confirmDeleteDoor(int doorId) async {
    final confirmed = await showEzDeleteConfirm(
      context,
      message: 'ต้องการลบประตูคอกไก่ที่ $doorId ใช่หรือไม่?',
    );
    if (confirmed) {
      setState(() => doors.removeWhere((d) => d['id'] == doorId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    final int openCount = doors.where((d) => d['isOn'] == true).length;

    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const EzHeader(pageTitle: 'ควบคุมประตูคอกไก่'),
                const SizedBox(height: 20),

                // สรุปภาพรวม: จำนวนประตูทั้งหมด และจำนวนที่เปิดอยู่ตอนนี้
                if (doors.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: ez.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 18,
                          color: ez.gold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ทั้งหมด ${doors.length} ประตู',
                          style: GoogleFonts.kanit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ez.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.sensor_door_outlined,
                          size: 16,
                          color: ez.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'เปิดอยู่ $openCount บาน',
                          style: GoogleFonts.kanit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ez.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                if (doors.isEmpty)
                  _buildEmptyState()
                else
                  Column(
                    children: [for (final door in doors) _buildDoorCard(door)],
                  ),

                const SizedBox(
                  height: 100,
                ), // เว้นที่สำหรับ BottomNavigationBar
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 8),
        child: FloatingActionButton(
          onPressed: _addNewDoor,
          backgroundColor: const Color(0xFFE74C3C),
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 36, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }

  Widget _buildEmptyState() {
    final ez = ezColors(context);
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.meeting_room_outlined, size: 54, color: ez.textSecondary),
          const SizedBox(height: 14),
          Text(
            'ยังไม่มีประตูคอกไก่',
            style: GoogleFonts.kanit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ez.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'กดปุ่ม + ด้านล่างขวาเพื่อเพิ่มประตู',
            style: GoogleFonts.kanit(fontSize: 13, color: ez.textSecondary),
          ),
        ],
      ),
    );
  }

  // การ์ดควบคุมประตูแต่ละบาน — ไอคอนซ้ายบอกสถานะด้วยสีทันที, ป้ายข้อความ
  // ใต้ชื่อบอกสถานะปัจจุบันอย่างเดียว (ไม่ใช้ OFF/ON คู่กันตลอดแบบเดิมที่ทำให้งง)
  Widget _buildDoorCard(Map<String, dynamic> door) {
    final ez = ezColors(context);
    final bool isOn = door['isOn'] == true;
    final Color stateColor = isOn ? ez.success : ez.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ezCardColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: stateColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.meeting_room, color: stateColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ประตูคอกไก่ที่ ${door["id"]}',
                  style: GoogleFonts.kanit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ez.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOn ? 'เปิดอยู่' : 'ปิดอยู่',
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: stateColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOn,
            onChanged: (value) => setState(() => door['isOn'] = value),
            activeThumbColor: Colors.white,
            activeTrackColor: ez.success,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: ez.border,
          ),
          IconButton(
            onPressed: () => _confirmDeleteDoor(door['id']),
            tooltip: 'ลบประตูนี้',
            icon: Icon(Icons.delete_outline, color: ez.danger, size: 20),
          ),
        ],
      ),
    );
  }
}
