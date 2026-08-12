import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../bottombar.dart';
import 'Main_Dataadd_adopt2.dart';
import 'Main_EditData_adoptchicken2.dart';
import '../../models/coop.dart';
import '../../services/api_service.dart';
import '../../services/backend_config.dart';

class Adoptchicken extends StatefulWidget {
  const Adoptchicken({super.key});

  @override
  State<Adoptchicken> createState() => _AdoptchickenState();
}

class _AdoptchickenState extends State<Adoptchicken> {
  int selectedIndex = 0;
  List<Coop> coopDataList = [];
  bool isLoading = true;
  String? errorMessage;

  final ApiService api = ApiService(baseUrl: backendBaseUrl);

  String _formatDateFromAPI(String? apiDate) {
    if (apiDate == null || apiDate.isEmpty) return "-";
    try {
      DateTime parsedDate = DateTime.parse(apiDate);
      String day = parsedDate.day.toString().padLeft(2, '0');
      String month = parsedDate.month.toString().padLeft(2, '0');
      String year = parsedDate.year.toString();
      return "$year-$month-$day";
    } catch (e) {
      return apiDate;
    }
  }

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
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

  @override
  void initState() {
    super.initState();
    _fetchCoops();
  }

  Future<void> _fetchCoops() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final list = await api.fetchCoops();
      setState(() {
        coopDataList = list;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildHealthBar(int good, int bad) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'สุขภาพไก่ ',
              style: GoogleFonts.kanit(color: Colors.white, fontSize: 13),
            ),
            Container(
              width: 130,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[800],
              ),
              child: Row(
                children: [
                  if (good > 0)
                    Expanded(
                      flex: good,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF5DBB63),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                        child: Text(
                          good.toString(),
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (bad > 0)
                    Expanded(
                      flex: bad,
                      child: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD9534F),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: Text(
                          bad.toString(),
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 60, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(
                Icons.sentiment_satisfied_alt,
                color: Color(0xFF5DBB63),
                size: 18,
              ),
              Icon(
                Icons.sentiment_dissatisfied,
                color: Color(0xFFD9534F),
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBar(String label, String value, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$label ',
            style: GoogleFonts.kanit(color: Colors.white, fontSize: 13),
          ),
          Container(
            width: 110,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              alignment: Alignment.centerRight,
              widthFactor: 0.6,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  value,
                  style: GoogleFonts.kanit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            unit,
            style: GoogleFonts.kanit(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoopCard({
    required int index,
    required String id,
    required String name,
    required String importDate,
    required String count,
    required String birthDate,
    required String note,
  }) {
    // ✅ ลบคำว่า "ตัว" และช่องว่าง ออกจากตัวแปร count เผื่อมีบันทึกติดมาในฐานข้อมูล
    String cleanCount = count.replaceAll(RegExp(r'ตัว|\s'), '');

    return GestureDetector(
      onTap: () {
        _showActionDialog(
          index: index,
          id: id,
          name: name,
          importDate: importDate,
          count: count,
          birthDate: birthDate,
          note: note,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF263238),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    'คอกไก่ $name',
                    style: GoogleFonts.kanit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ✅ เปลี่ยนจากรูปกระต่าย เป็นรูปไก่ (ถ้าไม่มีไฟล์ chicken.png จะแสดง 🐔 แทนเพื่อไม่ให้ Error)
                  Image.asset(
                    'assets/images/chicken.png',
                    width: 65,
                    height: 65,
                    color: Colors.white,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('🐔', style: TextStyle(fontSize: 50));
                    },
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        cleanCount, // ✅ ใช้ตัวเลขที่ลบคำว่า "ตัว" ออกแล้ว
                        style: GoogleFonts.kanit(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF47B7B),
                        ),
                      ),
                      Text(
                        ' ตัว',
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'วันที่นำเข้า : $importDate',
                    style: GoogleFonts.kanit(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'วันเกิดไก่ : $birthDate',
                    style: GoogleFonts.kanit(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  _buildHealthBar(115, 5),
                  _buildStatBar('อุณหภูมิ', '28', 'C', const Color(0xFF33C7CC)),
                  _buildStatBar(
                    'แอมโมเนีย',
                    '20',
                    'PPM',
                    const Color(0xFFE58940),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionDialog({
    required int index,
    required String id,
    required String name,
    required String importDate,
    required String count,
    required String birthDate,
    required String note,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext dialogContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'จัดการคอกไก่ $name',
                style: GoogleFonts.kanit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.amber),
                title: Text('แก้ไขข้อมูล', style: GoogleFonts.kanit()),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditDataAdoptchicken(
                        initialData: {
                          "id": id,
                          "importDate": importDate,
                          "count": count,
                          "birthDate": birthDate,
                          "note": note,
                        },
                      ),
                    ),
                  );

                  if (result != null && result is Map<String, String>) {
                    setState(() {
                      coopDataList[index] = Coop(
                        id: result['id'] ?? '',
                        // ✅ ฟอร์มแก้ไขไม่มีช่องแก้ชื่อคอก จึงคงชื่อเดิมไว้
                        name: name,
                        importDate: result['importDate'] ?? '',
                        count: result['count'] ?? '',
                        birthDate: result['birthDate'] ?? '',
                        note: result['note'] ?? '',
                      );
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('ลบข้อมูล', style: GoogleFonts.kanit()),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _confirmDelete(index: index, id: id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete({required int index, required String id}) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AppDeleteDialog(
          onConfirm: () async {
            Navigator.of(dialogContext).pop();
            await _executeDeleteAPI(index: index, id: id);
          },
        );
      },
    );
  }

  Future<bool> _executeDeleteAPI({
    required int index,
    required String id,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    try {
      final response = await http.delete(
        Uri.parse('$backendBaseUrl/api/coops?id=$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (!context.mounted) return false;
      Navigator.of(context, rootNavigator: true).pop(); // ปิด Loading

      if (response.statusCode == 200) {
        setState(() {
          coopDataList.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบข้อมูลสำเร็จ', style: GoogleFonts.kanit()),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการลบ: ${response.statusCode}',
              style: GoogleFonts.kanit(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      if (!context.mounted) return false;
      Navigator.of(context, rootNavigator: true).pop(); // ปิด Loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e',
            style: GoogleFonts.kanit(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: screenHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/coop.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          Positioned(
            top: 245,
            left: 0,
            right: 0,
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  if (isLoading)
                    const SizedBox(
                      height: 40,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'เกิดข้อผิดพลาด: $errorMessage',
                        style: GoogleFonts.kanit(color: Colors.red),
                      ),
                    ),

                  ...coopDataList.asMap().entries.map((entry) {
                    int index = entry.key;
                    Coop data = entry.value;

                    return Dismissible(
                      key: Key(data.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AppDeleteDialog(
                              onConfirm: () =>
                                  Navigator.of(dialogContext).pop(true),
                            );
                          },
                        );
                      },
                      onDismissed: (direction) async {
                        await _executeDeleteAPI(index: index, id: data.id);
                      },
                      child: _buildCoopCard(
                        index: index,
                        id: data.id,
                        name: data.name,
                        importDate: _formatDateFromAPI(data.importDate),
                        count: data.count,
                        birthDate: _formatDateFromAPI(data.birthDate),
                        note: data.note,
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 8),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddDataadopt()),
            );

            if (result != null && result is Map<String, String>) {
              setState(() {
                coopDataList.add(
                  Coop(
                    id: result['id'] ?? '',
                    // ✅ ฟอร์มเพิ่มคอกไม่มีช่องกรอกชื่อคอก จึงใช้เลขคอกแทนไปก่อน
                    name: result['name'] ?? result['id'] ?? '',
                    importDate: result['importDate'] ?? '',
                    count: result['count'] ?? '',
                    birthDate: result['birthDate'] ?? '',
                    note: result['note'] ?? '',
                  ),
                );
              });
            }
          },
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
}

class AppDeleteDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const AppDeleteDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('ยืนยันการลบ', style: GoogleFonts.kanit()),
      content: Text(
        'คุณต้องการลบข้อมูลคอกนี้ใช่หรือไม่?',
        style: GoogleFonts.kanit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('ยกเลิก', style: GoogleFonts.kanit()),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text(
            'ลบ',
            style: GoogleFonts.kanit(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
