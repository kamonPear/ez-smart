import 'package:flutter/material.dart';

/// แถบเมนูล่างแบบลอย (floating pill) พร้อมตัวชี้ (indicator) เคลื่อนไหวหลังไอคอนที่เลือก
/// สีต่างๆ มาจาก NavigationBarTheme ใน AppTheme (รองรับโหมดมืด/สว่าง)
///
/// ส่ง [selectedIndex] เป็น null เมื่ออยู่หน้าที่ไม่ใช่ 1 ใน 5 เมนูของแถบนี้
/// (เช่น หน้าบันทึกวัคซีน, หน้าเพิ่ม/แก้ไขข้อมูล) จะไม่ไฮไลต์เมนูไหนเลย
class CustomBottomBar extends StatelessWidget {
  final int? selectedIndex;
  final Function(int index) onTabSelected;

  const CustomBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = selectedIndex != null;
    final navTheme = NavigationBarTheme.of(context);

    // สไตล์ตอน "ไม่ถูกเลือก" ของธีมหลัก เอามาบังคับใช้กับทุกเมนูเมื่อไม่มีการเลือก
    final unselectedLabel = navTheme.labelTextStyle?.resolve(<WidgetState>{});
    final unselectedIcon = navTheme.iconTheme?.resolve(<WidgetState>{});

    final destinations = [
      _destination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'หน้าแรก',
        hasSelection: hasSelection,
      ),
      _destination(
        icon: Icons.meeting_room_outlined,
        selectedIcon: Icons.meeting_room,
        label: 'ประตู',
        hasSelection: hasSelection,
      ),
      _destination(
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        label: 'สถิติเก็บไข่',
        hasSelection: hasSelection,
      ),
      _destination(
        icon: Icons.pets_outlined,
        selectedIcon: Icons.pets,
        label: 'ข้อมูลคอก',
        hasSelection: hasSelection,
      ),
      _destination(
        icon: Icons.restaurant_outlined,
        selectedIcon: Icons.restaurant,
        label: 'อาหาร',
        hasSelection: hasSelection,
      ),
    ];

    Widget bar = NavigationBar(
      selectedIndex: selectedIndex ?? 0,
      onDestinationSelected: onTabSelected,
      destinations: destinations,
    );

    if (!hasSelection) {
      bar = NavigationBarTheme(
        data: navTheme.copyWith(
          indicatorColor: Colors.transparent,
          labelTextStyle: WidgetStatePropertyAll(unselectedLabel),
          iconTheme: WidgetStatePropertyAll(unselectedIcon),
        ),
        child: bar,
      );
    }

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
      child: ClipRRect(borderRadius: BorderRadius.circular(28), child: bar),
    );
  }

  NavigationDestination _destination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool hasSelection,
  }) {
    return NavigationDestination(
      icon: Icon(icon),
      // ไม่มีเมนูไหนถูกเลือก จึงใช้ไอคอนแบบเส้นทั้งหมด ไม่ให้เมนูแรกดูเหมือนถูกเลือก
      selectedIcon: Icon(hasSelection ? selectedIcon : icon),
      label: label,
    );
  }
}
