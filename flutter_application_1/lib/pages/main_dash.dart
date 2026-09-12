import 'dart:convert';
import 'package:flutter_application_1/pages/Chicken_health_information/Main_HealthAppointments.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_Datadopt_chicken_2.dart';
import 'package:flutter_application_1/pages/Vaccine/Add_VaccineType.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'bottombar.dart';
import 'Main_SenSor/Main_DeviceSummary.dart';
import 'Data_AdoptChicken/Main_DataChicken_2.dart';
import 'Data_AdoptChicken/Main_CoopDetail.dart';
import '../../services/backend_config.dart';
import '../../services/notifications_service.dart';
import '../widgets/ez_header.dart';
import '../widgets/ez_gauge.dart';
import '../theme/app_theme.dart';
import '../theme/farm_settings.dart';
import '../utils/thai_date.dart';
import 'Settings/Main_FarmThresholds.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedIndex = 0;
  bool isLoading = true;
  List<Map<String, dynamic>> coopList = [];
  double _totalFoodKg = 0;
  String _searchQuery = '';
  int _notificationCount = 0;

  List<Map<String, dynamic>> get _visibleCoopList {
    if (_searchQuery.trim().isEmpty) return coopList;
    final query = _searchQuery.trim().toLowerCase();
    // ✅ ค้นหาได้ทุกอย่าง ไม่ใช่แค่ชื่อ/เลขคอก แต่รวมวันที่นำเข้า วันเกิดไก่
    // จำนวนไก่ และผลสุขภาพล่าสุดด้วย - พิมพ์วันที่/เดือน/ปีก็เจอได้เลย
    return coopList.where((coop) {
      final haystack = [
        coop['name'],
        coop['number'],
        coop['import_date'],
        coop['birth_date'],
        coop['amount'],
        coop['healthy'],
        coop['poor_health'],
      ].map((v) => (v ?? '').toString().toLowerCase()).join(' ');
      return haystack.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchCoops();
    _fetchFoodStock();
    _fetchNotificationCount();
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final notifications = await loadNotifications();
      if (mounted) setState(() => _notificationCount = notifications.length);
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  Future<void> _fetchFoodStock() async {
    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/api/foods'),
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> rows = decoded is List ? decoded : [];
        double total = 0;
        for (final row in rows) {
          if (row is Map<String, dynamic>) {
            total += (row['quantity_current'] as num?)?.toDouble() ?? 0;
          }
        }
        if (mounted) {
          setState(() => _totalFoodKg = total);
        }
      }
    } catch (e) {
      debugPrint("❌ โหลดข้อมูลอาหารคงเหลือไม่สำเร็จ: $e");
    }
  }

  Future<void> _fetchCoops() async {
    setState(() {
      isLoading = true;
    });

    try {
      final coopResponse = await http.get(
        Uri.parse('$backendBaseUrl/api/coops'),
      );
      final healthResponse = await http.get(
        Uri.parse('$backendBaseUrl/api/healths'),
      );
      final eggResponse = await http.get(Uri.parse('$backendBaseUrl/api/eggs'));
      final deviceResponse = await http.get(
        Uri.parse('$backendBaseUrl/api/devices'),
      );

      if (coopResponse.statusCode == 200) {
        final List<dynamic> coopData = jsonDecode(coopResponse.body);
        List<dynamic> healthData = [];
        List<dynamic> eggData = [];
        List<dynamic> deviceData = [];

        if (healthResponse.statusCode == 200) {
          healthData = jsonDecode(healthResponse.body);
        }
        if (eggResponse.statusCode == 200) {
          eggData = jsonDecode(eggResponse.body);
        }
        if (deviceResponse.statusCode == 200) {
          deviceData = jsonDecode(deviceResponse.body);
        }

        setState(() {
          coopList = coopData.map((item) {
            String currentCoopId =
                item['coop_id']?.toString() ?? item['id']?.toString() ?? "1";

            var matchedHealths = healthData
                .where((h) => h['coop_id']?.toString() == currentCoopId)
                .toList();
            var latestHealth = matchedHealths.isNotEmpty
                ? matchedHealths.last
                : null;

            var matchedEggs = eggData
                .where((e) => e['coop_id']?.toString() == currentCoopId)
                .toList();
            Map<String, List<double>> eggStats = {};

            for (var egg in matchedEggs) {
              String year = '2026';
              int month = 1;

              if (egg['date_collect_egg'] != null) {
                try {
                  DateTime parsedDate = DateTime.parse(
                    egg['date_collect_egg'].toString(),
                  ).toLocal();
                  year = parsedDate.year.toString();
                  month = parsedDate.month;
                } catch (e) {
                  debugPrint("Date parsing error: $e");
                }
              }

              double amount =
                  double.tryParse((egg['number_egg'] ?? '0').toString()) ?? 0.0;

              if (!eggStats.containsKey(year)) {
                eggStats[year] = List.filled(12, 0.0);
              }
              if (month >= 1 && month <= 12) {
                eggStats[year]![month - 1] += amount;
              }
            }

            if (eggStats.isEmpty) {
              eggStats['2026'] = List.filled(12, 0.0);
            }

            var coopDevices = deviceData.where((d) {
              return d['coop_id'] != null &&
                  d['coop_id'].toString() == currentCoopId;
            }).toList();

            var tempDevice = coopDevices.firstWhere((d) {
              String name = (d['name'] ?? '').toString().toLowerCase();
              return name.contains('อุณหภูมิ') || name.contains('dht');
            }, orElse: () => null);
            String latestTemp = tempDevice != null
                ? tempDevice['value']?.toString() ?? "0"
                : "0";

            var ppmDevice = coopDevices.firstWhere((d) {
              String name = (d['name'] ?? '').toString().toLowerCase();
              return name.contains('แอมโมเนีย') || name.contains('mq');
            }, orElse: () => null);
            String latestPpm = ppmDevice != null
                ? ppmDevice['value']?.toString() ?? "0"
                : "0";

            // 💡 1. จัดการวันที่นำเข้า
            String importDate = thaiDateFromIso(
              item['date_adopt_animals']?.toString(),
              fallback: "ไม่ระบุ",
            );

            // 💡 2. จัดการวันเกิดไก่ (ใช้ 'Birthday' ตัว B พิมพ์ใหญ่ และ 'birthday')
            String birthDate = thaiDateFromIso(
              (item['Birthday'] ?? item['birthday'])?.toString(),
              fallback: "ไม่ระบุ",
            );

            return {
              "id": currentCoopId,
              "number": currentCoopId,
              "name": item['name_coop']?.toString().trim().isNotEmpty == true
                  ? item['name_coop'].toString()
                  : currentCoopId,
              "amount": item['amount']?.toString() ?? "120",

              "import_date": importDate,
              "birth_date": birthDate,

              "healthy": latestHealth != null
                  ? latestHealth['healthy']?.toString() ?? "0"
                  : "0",
              "poor_health": latestHealth != null
                  ? latestHealth['poor_health']?.toString() ?? "0"
                  : "0",

              "temp": latestTemp,
              "ppm": latestPpm,
              "egg_data": eggStats,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("❌ Connection/Parsing error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void onTabSelected(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainDeviceSummary()),
      ).then((_) => setState(() => selectedIndex = 0));
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      ).then((_) => setState(() => selectedIndex = 0));
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      ).then((_) => setState(() => selectedIndex = 0));
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()),
      ).then((_) => setState(() => selectedIndex = 0));
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  int get _totalChickenCount {
    int total = 0;
    for (var coop in coopList) {
      total +=
          int.tryParse(
            coop["amount"].toString().replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
    }
    return total;
  }

  int get _totalEggCount {
    int total = 0;
    for (var coop in coopList) {
      Map<String, List<double>> eggStats = coop["egg_data"] ?? {};
      for (var values in eggStats.values) {
        total += values.fold<double>(0, (sum, v) => sum + v).round();
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // ✅ หักความสูงแป้นพิมพ์ออกด้วย ไม่งั้นตอนโฟกัสช่องค้นหาแล้วคีย์บอร์ดเด้งขึ้นมา
    // เนื้อหาจะยังถูกบังคับให้สูงเท่าจอเต็มทั้งที่พื้นที่จริงเหลือน้อยลง ทำให้
    // เลย์เอาต์กระตุกดูแปลกๆ (และดูเหมือนพิมพ์อะไรไม่ได้เพราะหน้าขยับตลอด)
    final double minContentHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      drawer: _buildAppDrawer(context),
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: minContentHeight),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        'EZ - SMART FARM',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.kanit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ezGoldColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 15),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: ezColors(context).textPrimary,
                          size: 32,
                        ),
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: ezColors(context).border),
                          ),
                          child: TextField(
                            textAlignVertical: TextAlignVertical.center,
                            style: GoogleFonts.kanit(color: Colors.black87),
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'ค้นหาคอกไก่ (ชื่อ, เลขคอก, วันที่)',
                              hintStyle: GoogleFonts.kanit(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              suffixIcon: const Icon(
                                Icons.search,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Notifications(),
                            ),
                          );
                          _fetchNotificationCount();
                        },
                        borderRadius: BorderRadius.circular(
                          20,
                        ), // เพิ่มเอฟเฟกต์ตอนกดให้เป็นวงกลม
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                color: ezColors(context).textPrimary,
                                size: 32,
                              ),
                              if (_notificationCount > 0)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ezColors(context).danger,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: ezBackgroundColor(context),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      _notificationCount > 99
                                          ? '99+'
                                          : '$_notificationCount',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.kanit(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                ListenableBuilder(
                  listenable: farmThresholdController,
                  builder: (context, _) {
                    final temp = farmThresholdController.temperature;
                    final ammonia = farmThresholdController.ammonia;
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainFarmThresholds(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 15,
                        ),
                        decoration: BoxDecoration(
                          color: ezCardColor(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            EzGaugeCard(
                              icon: Icons.thermostat_outlined,
                              value: temp.toStringAsFixed(0),
                              unit: "°",
                              subTitle: "อุณหภูมิที่ตั้งไว้คงที่",
                              color: Colors.cyan,
                              percent: (temp / 50).clamp(0, 1),
                            ),
                            EzGaugeCard(
                              icon: Icons.air_outlined,
                              value: ammonia.toStringAsFixed(0),
                              unit: "PPM",
                              subTitle: "ปริมาณแอมโมเนียที่ตั้งไว้คงที่",
                              color: Colors.orange.shade800,
                              percent: (ammonia / 100).clamp(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          emoji: '🐔',
                          bgColor: ezColors(context).chipGreenBg,
                          textColor: ezColors(context).chipGreenText,
                          label: 'จำนวนไก่ทั้งหมด',
                          value: '$_totalChickenCount ตัว',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Adoptchicken(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          emoji: '🥚',
                          bgColor: ezColors(context).chipOrangeBg,
                          textColor: ezColors(context).chipOrangeText,
                          label: 'จำนวนไข่ทั้งหมด',
                          value: '$_totalEggCount ฟอง',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ShowChart(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          emoji: '🌾',
                          bgColor: ezColors(context).chipDarkBg,
                          textColor: ezColors(context).chipDarkText,
                          label: 'อาหารคงเหลือ',
                          value: '${_totalFoodKg.toStringAsFixed(0)} กิโลกรัม',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainShowDataFood(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                Text(
                  'คอกไก่ทั้งหมด',
                  style: GoogleFonts.kanit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ezGoldColor(context),
                  ),
                ),

                const SizedBox(height: 15),

                if (isLoading)
                  Skeletonizer(
                    enabled: true,
                    child: Column(
                      children: List.generate(
                        3,
                        (_) => _buildCoopCard(const {
                          "name": "ก้านกล้วย",
                          "amount": "200",
                          "import_date": "2026-08-19",
                          "birth_date": "2026-07-31",
                        }),
                      ),
                    ),
                  )
                else if (coopList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    child: Text(
                      "ไม่มีข้อมูลคอกไก่",
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        color: ezColors(context).textSecondary,
                      ),
                    ),
                  )
                else if (_visibleCoopList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    child: Text(
                      "ไม่พบคอกไก่ที่ค้นหา",
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        color: ezColors(context).textSecondary,
                      ),
                    ),
                  )
                else
                  ..._visibleCoopList.map((coop) => _buildCoopCard(coop)),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }

  Widget _buildStatCard({
    required String emoji,
    required Color bgColor,
    required Color textColor,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoopCard(Map<String, dynamic> data) {
    // ✅ ลบคำว่า "ตัว" ออกจากค่า amount
    String cleanAmount = data["amount"].toString().replaceAll(
      RegExp(r'ตัว|\s'),
      '',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CoopDetailPage(coop: data)),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: ezCardColor(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ezColors(context).textPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('🐔', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'คอกไก่ ${data["name"]}',
                      style: GoogleFonts.kanit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: ezColors(context).textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          cleanAmount,
                          style: GoogleFonts.kanit(
                            color: ezColors(context).danger,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "ตัว",
                          style: GoogleFonts.kanit(
                            color: ezColors(context).textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "วันที่นำเข้า : ${data["import_date"]}",
                    style: GoogleFonts.kanit(
                      color: ezColors(context).textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "วันเกิดไก่ : ${data["birth_date"]}",
                    style: GoogleFonts.kanit(
                      color: ezColors(context).textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: ezCardColor(context),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.egg_alt_rounded,
                    color: ezGoldColor(context),
                    size: 42,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'EZ - SMART FARM',
                    style: GoogleFonts.kanit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ezGoldColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: ezColors(context).border, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  // เรียงตามลำดับตัวอักษรไทย (ก ขึ้นก่อน)
                  _buildDrawerItem(
                    Icons.notifications_none,
                    'การแจ้งเตือน',
                    () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Notifications(),
                        ),
                      );
                      _fetchNotificationCount();
                    },
                    badgeCount: _notificationCount,
                  ),
                  _buildDrawerItem(Icons.pets, 'คอกไก่', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Adoptchicken(),
                      ),
                    );
                  }),
                  _buildDrawerItem(Icons.tune_rounded, 'ค่ามาตรฐานทุกคอก', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainFarmThresholds(),
                      ),
                    );
                  }),
                  _buildDrawerItem(
                    Icons.medical_information_outlined,
                    'นัดตรวจสุขภาพ',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MainHealthAppointments(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(Icons.vaccines_outlined, 'เพิ่มยาวัคซีน', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddVaccineType(),
                      ),
                    );
                  }),
                  Divider(color: ezColors(context).border, height: 24),
                  _buildThemeToggleItem(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleItem(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final isDark = themeController.isDark;
        return ListTile(
          leading: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: ezGoldColor(context),
          ),
          title: Text(
            isDark ? 'โหมดมืด' : 'โหมดสว่าง',
            style: GoogleFonts.kanit(
              color: ezColors(context).textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Switch(
            value: isDark,
            onChanged: (_) => themeController.toggle(),
          ),
          onTap: () => themeController.toggle(),
        );
      },
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    int? badgeCount,
  }) {
    final bool hasBadge = badgeCount != null && badgeCount > 0;
    return ListTile(
      leading: Icon(icon, color: ezGoldColor(context)),
      title: Text(
        title,
        style: GoogleFonts.kanit(
          color: ezColors(context).textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: hasBadge
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              constraints: const BoxConstraints(minWidth: 22),
              decoration: BoxDecoration(
                color: ezColors(context).danger,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                textAlign: TextAlign.center,
                style: GoogleFonts.kanit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
