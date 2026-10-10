import 'package:flutter/material.dart';

/// Shared palette with the website: warm ivory, deep green, soft gold; red only for urgency.
abstract final class SajagColors {
  static const brand = Color(0xFF0B7A57);
  static const brandDark = Color(0xFF063F2D);
  static const brandSoft = Color(0xFFE2F0EA);
  static const accent = Color(0xFFE0303F);
  static const gold = Color(0xFFB5884A);
  static const ink = Color(0xFF121514);
  static const surface = Color(0xFFF7F5F0);
  static const resolved = Color(0xFF2B9A5A);
  static const progress = Color(0xFFD9951A);

  /// Text and icons on red (accent / error) surfaces are always white.
  static const onAccent = Colors.white;

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16A276), Color(0xFF0B7A57), Color(0xFF063F2D)],
  );

  static List<BoxShadow> softShadow(Brightness b) => b == Brightness.light
      ? const [
          BoxShadow(color: Color(0x0A121514), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x0F121514), blurRadius: 24, offset: Offset(0, 10)),
        ]
      : const [];
}

const _font = 'AnekBangla';

/// Calm, borderless, generously spaced. Anek Bangla covers both Bangla and Latin.
ThemeData buildTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: SajagColors.brand,
    brightness: brightness,
    primary: light ? SajagColors.brand : const Color(0xFF4EC396),
    onPrimary: light ? Colors.white : const Color(0xFF052A1E),
    secondary: SajagColors.gold,
    error: SajagColors.accent,
    onError: SajagColors.onAccent,
    surface: light ? Colors.white : const Color(0xFF171B19),
    surfaceContainerHighest: light ? const Color(0xFFEFECE4) : const Color(0xFF242A27),
  );
  final background = light ? SajagColors.surface : const Color(0xFF0F1211);
  final ink = light ? SajagColors.ink : const Color(0xFFF2F1EC);
  final muted = light ? const Color(0xFF6E7470) : const Color(0xFF9AA19C);

  final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: brightness, fontFamily: _font);
  TextStyle s(double size, FontWeight w, {double height = 1.35, Color? color}) =>
      TextStyle(fontFamily: _font, fontSize: size, fontWeight: w, height: height, color: color ?? ink);
  final text = base.textTheme.copyWith(
    displaySmall: s(36, FontWeight.w600, height: 1.15),
    headlineLarge: s(32, FontWeight.w600, height: 1.2),
    headlineMedium: s(28, FontWeight.w600, height: 1.25),
    headlineSmall: s(24, FontWeight.w600, height: 1.25),
    titleLarge: s(21, FontWeight.w600, height: 1.3),
    titleMedium: s(17, FontWeight.w600, height: 1.35),
    titleSmall: s(15, FontWeight.w600, height: 1.35),
    bodyLarge: s(17, FontWeight.w400, height: 1.55),
    bodyMedium: s(15, FontWeight.w400, height: 1.5),
    bodySmall: s(13, FontWeight.w400, height: 1.45, color: muted),
    labelLarge: s(15, FontWeight.w600, height: 1.2),
    labelMedium: s(13, FontWeight.w500, height: 1.2),
    labelSmall: s(11, FontWeight.w500, height: 1.2, color: muted),
  );

  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
  return base.copyWith(
    scaffoldBackgroundColor: background,
    textTheme: text,
    dividerTheme: const DividerThemeData(color: Colors.transparent, space: 0, thickness: 0),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: s(24, FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        shape: pill,
        elevation: 0,
        textStyle: s(17, FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        shape: pill,
        side: BorderSide.none,
        backgroundColor: light ? Colors.white : scheme.surface,
        foregroundColor: ink,
        textStyle: s(17, FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(textStyle: s(15, FontWeight.w600))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: light ? Colors.white : scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.error, width: 1.2),
      ),
      hintStyle: s(16, FontWeight.w400, color: muted),
      labelStyle: s(16, FontWeight.w500, color: muted),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: light ? Colors.white : scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: light ? Colors.white : scheme.surface,
      selectedColor: scheme.primary,
      checkmarkColor: scheme.onPrimary,
      labelStyle: s(14, FontWeight.w500),
      secondaryLabelStyle: s(14, FontWeight.w600, color: scheme.onPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: const WidgetStatePropertyAll(BorderSide.none),
        backgroundColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected)
              ? (light ? Colors.white : scheme.surfaceContainerHighest)
              : Colors.transparent,
        ),
        textStyle: WidgetStatePropertyAll(s(14, FontWeight.w600)),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      titleTextStyle: s(16, FontWeight.w500),
      subtitleTextStyle: s(13, FontWeight.w400, color: muted),
      iconColor: ink,
    ),
    badgeTheme: const BadgeThemeData(backgroundColor: SajagColors.accent, textColor: SajagColors.onAccent),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: s(21, FontWeight.w600),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: s(15, FontWeight.w500, color: background),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    switchTheme: const SwitchThemeData(trackOutlineColor: WidgetStatePropertyAll(Colors.transparent)),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
  );
}
