import 'package:flutter/material.dart';

// ลบ main(), MyApp, HomeScreen ออกให้หมด
// และใช้ Widget นี้แทน

class CustomBottomBar extends StatefulWidget {
  // 1. เพิ่มตัวรับค่า index ปัจจุบันจากหน้าหลัก (แก้จุดที่ทำให้แดง)
  final int selectedIndex; 
  
  // 2. แก้ Callback ให้เป็น required (จำเป็นต้องส่งมา)
  final Function(int index) onTabSelected; 
  
  const CustomBottomBar({
    super.key, 
    required this.selectedIndex, // ต้องรับค่า index
    required this.onTabSelected, // ต้องรับฟังก์ชัน
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  // ไม่ต้องประกาศ int _selectedIndex = 0; เองแล้ว เพราะจะใช้ค่าจาก widget.selectedIndex แทน

  void _onItemTapped(int index) {
    // เมื่อกด ให้เรียกฟังก์ชันของหน้าหลัก
    widget.onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'หน้าแรก',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.meeting_room),
          label: 'ประตู',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'เก็บไข่',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pets),
          label: 'ข้อมูลคอก',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant),
          label: 'อาหาร',
        ),
      ],
      
      // 3. ใช้ค่า index ที่ส่งมาจากหน้าหลัก (สำคัญมาก จุดนี้ทำให้ tab เปลี่ยนตามหน้า)
      currentIndex: widget.selectedIndex,
      
      // กำหนดสีตามที่คุณต้องการ
      selectedItemColor: const Color.fromARGB(255, 199, 14, 8), 
      unselectedItemColor: const Color(0xFFFFFFFF), 
      backgroundColor: const Color(0xFF1E3C4E), 
      type: BottomNavigationBarType.fixed, 
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),

      // กำหนด Action เมื่อมีการแตะ Tab
      onTap: _onItemTapped,
    );
  }
}