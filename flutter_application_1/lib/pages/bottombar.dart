import 'package:flutter/material.dart';

/// แถบเมนูล่างแบบลอย (floating pill) พร้อมตัวชี้ (indicator) เคลื่อนไหวหลังไอคอนที่เลือก
/// สีต่างๆ มาจาก NavigationBarTheme ใน AppTheme (รองรับโหมดมืด/สว่าง)
class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int index) onTabSelected;

  const CustomBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onTabSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'หน้าแรก',
            ),
            NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined),
              selectedIcon: Icon(Icons.meeting_room),
              label: 'ประตู',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'เก็บไข่',
            ),
            NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets),
              label: 'ข้อมูลคอก',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant),
              label: 'อาหาร',
            ),
          ],
        ),
      ),
    );
  }
}
