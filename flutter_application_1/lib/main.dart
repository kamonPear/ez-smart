import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/theme/farm_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();
  await farmThresholdController.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'EZ - SmartFram',
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
          home: const MainScreen(),
        );
      },
    );
  }
}
