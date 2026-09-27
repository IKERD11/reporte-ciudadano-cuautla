import 'package:flutter/material.dart';

const navy = Color(0xffe9e0ff);
const green = Color(0xff35ba78);
const muted = Color(0xffb1add0);

const citizenBackground = Color(0xff090b22);
const citizenSurface = Color(0xff171337);
const citizenAccent = Color(0xff9b29ff);
const citizenBorder = Color(0xff39305f);
ThemeData citizenTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: citizenAccent,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xffbb86ff),
        secondary: const Color(0xff6ee7c0),
        surface: citizenSurface,
        onSurface: const Color(0xfff2eeff),
      );
  final round = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
    side: const BorderSide(color: citizenBorder),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: citizenBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: citizenBackground,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      toolbarTextStyle: TextStyle(color: Colors.white),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xffeeeaff), height: 1.5),
      bodySmall: TextStyle(color: muted, height: 1.4),
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: citizenSurface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: round,
    ),
    dividerTheme: const DividerThemeData(color: citizenBorder),
    drawerTheme: const DrawerThemeData(backgroundColor: citizenBackground),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: citizenSurface,
      shape: round,
    ),
    dialogTheme: DialogThemeData(backgroundColor: citizenSurface, shape: round),
    popupMenuTheme: PopupMenuThemeData(color: citizenSurface, shape: round),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: citizenSurface,
      labelStyle: const TextStyle(color: muted),
      hintStyle: const TextStyle(color: muted),
      prefixIconColor: const Color(0xffd5bcff),
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: citizenBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: citizenBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: citizenAccent, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        backgroundColor: citizenAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: const Color(0xffd4b7ff),
        side: const BorderSide(color: citizenBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: citizenSurface,
      selectedColor: const Color(0xff6429bb),
      side: const BorderSide(color: citizenBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xff100e2b),
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xff4b237e),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 11,
          color: s.contains(WidgetState.selected)
              ? const Color(0xffcfadff)
              : muted,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.normal,
        ),
      ),
    ),
  );
}

class CitizenBrand extends StatelessWidget {
  const CitizenBrand({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: light ? 184 : 128,
        height: light ? 142 : 98,
        child: Image.asset(
          'assets/branding/logo-violet.png',
          fit: BoxFit.contain,
          semanticLabel: 'Logo de Reporte Ciudadano',
        ),
      ),
      const SizedBox(height: 12),
      Text(
        light ? 'Reporte\nCiudadano' : 'Reporte Ciudadano',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: light ? Colors.white : navy,
          fontSize: light ? 28 : 19,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
    ],
  );
}
