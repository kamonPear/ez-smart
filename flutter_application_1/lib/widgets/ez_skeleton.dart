import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'ez_header.dart';

/// รายการโครงกระดูก (skeleton) ทั่วไป ใช้แสดงระหว่างรอโหลดข้อมูลจริงจาก backend
/// เลือกใช้จุดนี้เมื่อหน้านั้นไม่มีฟังก์ชันสร้างการ์ดจริงที่หยิบมาใช้ซ้ำได้ง่ายๆ
class EzSkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;
  final EdgeInsetsGeometry itemPadding;

  const EzSkeletonList({
    super.key,
    this.count = 3,
    this.itemHeight = 84,
    this.itemPadding = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: List.generate(
          count,
          (_) => Padding(
            padding: itemPadding,
            child: EzSkeletonCard(height: itemHeight),
          ),
        ),
      ),
    );
  }
}

/// การ์ดโครงกระดูกใบเดียว ทรง: วงกลมนำ + ข้อความ 2 บรรทัด + ข้อความท้ายแถว
class EzSkeletonCard extends StatelessWidget {
  final double height;

  const EzSkeletonCard({super.key, this.height = 84});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ezCardColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  height: 16,
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 13,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 54, height: 13, color: Colors.grey),
        ],
      ),
    );
  }
}
