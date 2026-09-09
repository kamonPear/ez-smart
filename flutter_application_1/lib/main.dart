import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();

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
          home: const MainScreen(),
        );
      },
    );
  }
}
