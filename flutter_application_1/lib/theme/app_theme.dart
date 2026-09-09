import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// สีเฉพาะของแอป EZ Smart Farm ที่ไม่ได้มาจาก ColorScheme มาตรฐาน
/// เก็บเป็น ThemeExtension เพื่อให้สลับค่าตาม Light/Dark ได้อัตโนมัติ
@immutable
class EzColors extends ThemeExtension<EzColors> {
  final Color background;
  final Color card;
  final Color cardAlt;
  final Color gold;
  final Color accentGreen;
  final Color textPrimary;
  final Color textSecondary;
  final Color danger;
  final Color success;
  final Color border;
  final Color chipGreenBg;
  final Color chipOrangeBg;
  final Color chipDarkBg;
  final Color chipGreenText;
  final Color chipOrangeText;
  final Color chipDarkText;
  final Color inputFill;
  final Color inputText;

  const EzColors({
    required this.background,
    required this.card,
    required this.cardAlt,
    required this.gold,
    required this.accentGreen,
    required this.textPrimary,
    required this.textSecondary,
    required this.danger,
    required this.success,
    required this.border,
    required this.chipGreenBg,
    required this.chipOrangeBg,
    required this.chipDarkBg,
    required this.chipGreenText,
    required this.chipOrangeText,
    required this.chipDarkText,
    required this.inputFill,
    required this.inputText,
  });

  static const dark = EzColors(
    background: Color(0xFF0F1621),
    card: Color(0xFF19232F),
    cardAlt: Color(0xFF232E3D),
    gold: Color(0xFFE5BA93),
    accentGreen: Color(0xFF66E07A),
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    danger: Color(0xFFFCA5A5),
    success: Color(0xFF66E07A),
    border: Colors.white24,
    chipGreenBg: Color(0xFFCFE8D9),
    chipOrangeBg: Color(0xFFF3DCC2),
    chipDarkBg: Color(0xFF232E3D),
    chipGreenText: Colors.black87,
    chipOrangeText: Colors.black87,
    chipDarkText: Colors.white,
    inputFill: Color(0xFF151D24),
    inputText: Colors.white,
  );

  static const light = EzColors(
    background: Color(0xFFF4F1EC),
    card: Colors.white,
    cardAlt: Color(0xFFEFE6D8),
    gold: Color(0xFFB9793C),
    accentGreen: Color(0xFF2E9E4F),
    textPrimary: Color(0xFF20242B),
    textSecondary: Color(0xFF5B6472),
    danger: Color(0xFFD1443B),
    success: Color(0xFF2E9E4F),
    border: Color(0xFFDDD3C4),
    chipGreenBg: Color(0xFFDCF0E3),
    chipOrangeBg: Color(0xFFFBE7CF),
    chipDarkBg: Color(0xFFEFE6D8),
    chipGreenText: Color(0xFF20242B),
    chipOrangeText: Color(0xFF20242B),
    chipDarkText: Color(0xFF20242B),
    inputFill: Color(0xFFF0EDE7),
    inputText: Color(0xFF20242B),
  );

  @override
  EzColors copyWith({
    Color? background,
    Color? card,
    Color? cardAlt,
    Color? gold,
    Color? accentGreen,
    Color? textPrimary,
    Color? textSecondary,
    Color? danger,
    Color? success,
    Color? border,
    Color? chipGreenBg,
    Color? chipOrangeBg,
    Color? chipDarkBg,
    Color? chipGreenText,
    Color? chipOrangeText,
    Color? chipDarkText,
    Color? inputFill,
    Color? inputText,
  }) {
    return EzColors(
      background: background ?? this.background,
      card: card ?? this.card,
      cardAlt: cardAlt ?? this.cardAlt,
      gold: gold ?? this.gold,
      accentGreen: accentGreen ?? this.accentGreen,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      border: border ?? this.border,
      chipGreenBg: chipGreenBg ?? this.chipGreenBg,
      chipOrangeBg: chipOrangeBg ?? this.chipOrangeBg,
      chipDarkBg: chipDarkBg ?? this.chipDarkBg,
      chipGreenText: chipGreenText ?? this.chipGreenText,
      chipOrangeText: chipOrangeText ?? this.chipOrangeText,
      chipDarkText: chipDarkText ?? this.chipDarkText,
      inputFill: inputFill ?? this.inputFill,
      inputText: inputText ?? this.inputText,
    );
  }

  @override
  EzColors lerp(ThemeExtension<EzColors>? other, double t) {
    if (other is! EzColors) return this;
    return EzColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardAlt: Color.lerp(cardAlt, other.cardAlt, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      accentGreen: Color.lerp(accentGreen, other.accentGreen, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      border: Color.lerp(border, other.border, t)!,
      chipGreenBg: Color.lerp(chipGreenBg, other.chipGreenBg, t)!,
      chipOrangeBg: Color.lerp(chipOrangeBg, other.chipOrangeBg, t)!,
      chipDarkBg: Color.lerp(chipDarkBg, other.chipDarkBg, t)!,
      chipGreenText: Color.lerp(chipGreenText, other.chipGreenText, t)!,
      chipOrangeText: Color.lerp(chipOrangeText, other.chipOrangeText, t)!,
      chipDarkText: Color.lerp(chipDarkText, other.chipDarkText, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      inputText: Color.lerp(inputText, other.inputText, t)!,
    );
  }
}

/// จัดการสถานะโหมดสี (มืด/สว่าง) ของทั้งแอป และจำค่าไว้ในเครื่อง
class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'ez_theme_mode';

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = SharedPreferencesAsync();
    final saved = await prefs.getString(_prefsKey);
    if (saved == 'light') {
      _themeMode = ThemeMode.light;
      notifyListeners();
    } else if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_prefsKey, isDark ? 'dark' : 'light');
  }
}

final themeController = ThemeController();

class AppTheme {
  AppTheme._();

  static ThemeData _base(Brightness brightness, EzColors ez) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ez.gold,
      brightness: brightness,
      primary: ez.gold,
      secondary: ez.accentGreen,
      surface: ez.card,
      error: ez.danger,
    );

    final baseTextTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    // ฟอนต์ Kanit น้ำหนัก Light (300) เป็นค่าเริ่มต้นของทั้งแอป
    // (ข้อความที่ระบุ fontWeight เองอยู่แล้ว เช่นหัวข้อ/ปุ่ม จะไม่ถูกทับ)
    final textTheme = GoogleFonts.kanitTextTheme(baseTextTheme)
        .apply(bodyColor: ez.textPrimary, displayColor: ez.textPrimary)
        .copyWith(
          displayLarge: GoogleFonts.kanit(
            textStyle: baseTextTheme.displayLarge,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          displayMedium: GoogleFonts.kanit(
            textStyle: baseTextTheme.displayMedium,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          displaySmall: GoogleFonts.kanit(
            textStyle: baseTextTheme.displaySmall,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          headlineLarge: GoogleFonts.kanit(
            textStyle: baseTextTheme.headlineLarge,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          headlineMedium: GoogleFonts.kanit(
            textStyle: baseTextTheme.headlineMedium,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          headlineSmall: GoogleFonts.kanit(
            textStyle: baseTextTheme.headlineSmall,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          titleLarge: GoogleFonts.kanit(
            textStyle: baseTextTheme.titleLarge,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          titleMedium: GoogleFonts.kanit(
            textStyle: baseTextTheme.titleMedium,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          titleSmall: GoogleFonts.kanit(
            textStyle: baseTextTheme.titleSmall,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          bodyLarge: GoogleFonts.kanit(
            textStyle: baseTextTheme.bodyLarge,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          bodyMedium: GoogleFonts.kanit(
            textStyle: baseTextTheme.bodyMedium,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          bodySmall: GoogleFonts.kanit(
            textStyle: baseTextTheme.bodySmall,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          labelLarge: GoogleFonts.kanit(
            textStyle: baseTextTheme.labelLarge,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          labelMedium: GoogleFonts.kanit(
            textStyle: baseTextTheme.labelMedium,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          labelSmall: GoogleFonts.kanit(
            textStyle: baseTextTheme.labelSmall,
            color: ez.textPrimary,
            fontWeight: FontWeight.w300,
          ),
        );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ez.background,
      canvasColor: ez.background,
      dividerColor: ez.border,
      splashFactory: InkRipple.splashFactory,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: ez.background,
        foregroundColor: ez.textPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: ez.textPrimary),
        titleTextStyle: GoogleFonts.kanit(
          color: ez.gold,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: ez.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      iconTheme: IconThemeData(color: ez.textPrimary),
      dividerTheme: DividerThemeData(color: ez.border, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ez.gold,
          foregroundColor: isDark ? Colors.black87 : Colors.white,
          textStyle: GoogleFonts.kanit(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ez.gold,
          side: BorderSide(color: ez.gold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: ez.gold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ez.inputFill,
        hintStyle: GoogleFonts.kanit(color: ez.textSecondary),
        labelStyle: GoogleFonts.kanit(color: ez.inputText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ez.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ez.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ez.gold, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E3C4E) : Colors.white,
        indicatorColor: ez.gold.withValues(alpha: isDark ? 0.25 : 0.18),
        indicatorShape: const StadiumBorder(),
        height: 66,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.kanit(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? ez.gold
                : (isDark ? Colors.white : const Color(0xFF8A93A0)),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? ez.gold
                : (isDark ? Colors.white : const Color(0xFF8A93A0)),
            size: selected ? 26 : 24,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? ez.accentGreen
              : (isDark ? Colors.white : Colors.white),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? ez.accentGreen.withValues(alpha: 0.5)
              : ez.border,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? ez.gold
              : Colors.transparent,
        ),
        side: BorderSide(color: ez.border),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: ez.card,
        textStyle: GoogleFonts.kanit(color: ez.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ez.card,
        titleTextStyle: GoogleFonts.kanit(
          color: ez.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: GoogleFonts.kanit(color: ez.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ez.cardAlt,
        contentTextStyle: GoogleFonts.kanit(color: ez.textPrimary),
      ),
      extensions: [ez],
    );
  }

  static ThemeData get light => _base(Brightness.light, EzColors.light);
  static ThemeData get dark => _base(Brightness.dark, EzColors.dark);
}
