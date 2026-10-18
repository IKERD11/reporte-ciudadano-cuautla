import 'package:flutter/material.dart';

const navy = Color(0xff092b60);
const green = Color(0xff05af7c);
const muted = Color(0xff627b9c);

const citizenBackground = Color(0xfff8fcfe);
const citizenSurface = Color(0xffffffff);
const citizenAccent = Color(0xff1769ea);
const citizenBorder = Color(0xffdce8f3);
ThemeData citizenTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: citizenAccent,
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xff1769ea),
        secondary: const Color(0xff05af7c),
        surface: citizenSurface,
        onSurface: const Color(0xff092b60),
      );
  final round = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
    side: const BorderSide(color: citizenBorder),
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: citizenBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: citizenBackground,
      foregroundColor: navy,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Manrope',
        color: navy,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      toolbarTextStyle: TextStyle(color: navy),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xff173967), height: 1.5),
      bodySmall: TextStyle(color: muted, height: 1.4),
      titleLarge: TextStyle(
        color: navy,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ).apply(fontFamily: 'Manrope'),
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
      prefixIconColor: const Color(0xff1769ea),
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
        foregroundColor: const Color(0xff075ed9),
        side: const BorderSide(color: citizenBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: citizenSurface,
      selectedColor: const Color(0xffddd0fb),
      side: const BorderSide(color: citizenBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xffffffff),
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xffe4f4fd),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 11,
          color: s.contains(WidgetState.selected)
              ? const Color(0xff0755d9)
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
          'assets/renewal/icons/3d/shield.webp',
          fit: BoxFit.contain,
          semanticLabel: 'Logo de Reporte Ciudadano',
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Cuautla Segura',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: navy,
          fontSize: light ? 28 : 19,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
    ],
  );
}
