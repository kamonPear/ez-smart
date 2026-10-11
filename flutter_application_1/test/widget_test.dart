import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('shows the login page when not logged in', (tester) async {
    // ไม่ให้ google_fonts ดึงฟอนต์จากเน็ตระหว่างเทสต์
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(const MyApp(isLoggedIn: false));
    await tester.pump();

    expect(find.text('EZ-SmartFarm'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
