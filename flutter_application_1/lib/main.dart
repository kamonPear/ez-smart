import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_application_1/pages/Login/login_page.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:flutter_application_1/services/api_client.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/theme/farm_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();
  await farmThresholdController.load();
  // เช็ค token ที่ค้างอยู่ใน SharedPreferences จากการล็อกอินรอบก่อน - ถ้ายังมีอยู่
  // (ยังไม่ logout และยังไม่หมดอายุ) ให้เข้าหน้าหลักได้เลยโดยไม่ต้องล็อกอินซ้ำ
  // token จริงจะหมดอายุตาม auth.TokenTTL ของ backend (7 วัน) ถ้าหมดอายุแล้ว
  // ApiClient จะเจอ 401 จากคำขอแรกแล้วเด้งกลับไปหน้า Login ให้เองอยู่ดี
  final isLoggedIn = await AuthService().isLoggedIn();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'EZ - SmartFram',
          // ผูก navigatorKey ไว้ที่นี่ เพื่อให้ ApiClient นำทางไปหน้า Login ได้
          // จากทุกที่ในแอป (เช่นตอนเจอ 401 ลึกๆ ใน service function ที่ไม่มี
          // BuildContext ของตัวเอง) โดยไม่ต้องส่ง context ผ่านหลายชั้น
          navigatorKey: ApiClient.navigatorKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.themeMode,
          // ✅ ให้ปฏิทินเลือกวันที่ (showDatePicker) ทั้งแอปเป็นภาษาไทย
          // แทนที่จะโชว์ชื่อวัน/เดือนเป็นภาษาอังกฤษแบบดีฟอลต์
          locale: const Locale('th'),
          supportedLocales: const [Locale('th'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: isLoggedIn ? const MainScreen() : const LoginPage(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/main': (context) => const MainScreen(),
          },
        );
      },
    );
  }
}
