import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'router.dart';

class MonoApp extends StatefulWidget {
  const MonoApp({super.key});

  @override
  State<MonoApp> createState() => _MonoAppState();
}

class _MonoAppState extends State<MonoApp> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    
    // Aesthetic Tokens
    const creamColor = Color(0xFFF7F2E8);
    const pureBlack = Color(0xFF000000);
    const surfaceBlack = Color(0xFF121212);
    const accentBrown = Color(0xFF8D6E63);

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: creamColor,
      brightness: Brightness.dark,
      surface: surfaceBlack,
      onSurface: creamColor,
      primary: creamColor,
    );

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: accentBrown,
      brightness: Brightness.light,
      surface: creamColor,
      onSurface: Colors.black87,
      primary: Colors.black,
    );

    final mainApp = MaterialApp.router(
      title: 'Mono',
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      themeMode: themeService.themeMode,
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: creamColor,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ).apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: creamColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.black,
          foregroundColor: creamColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.25)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: creamColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: creamColor,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: creamColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.black.withValues(alpha: 0.06),
          thickness: 1,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: pureBlack,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: creamColor,
          displayColor: creamColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: pureBlack.withValues(alpha: 0.8),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: creamColor),
          titleTextStyle: GoogleFonts.outfit(
            color: creamColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceBlack,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: creamColor.withValues(alpha: 0.05)),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: creamColor,
          foregroundColor: pureBlack,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceBlack,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: creamColor.withValues(alpha: 0.2)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: surfaceBlack,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: creamColor.withValues(alpha: 0.05)),
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: surfaceBlack,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: surfaceBlack,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        dividerTheme: DividerThemeData(
          color: creamColor.withValues(alpha: 0.05),
          thickness: 1,
        ),
      ),
    );

    return mainApp;
  }
}
