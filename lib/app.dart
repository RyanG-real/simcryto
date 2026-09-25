import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'state/app_state.dart';

class AppColors {
  static const mint = Color(0xFF16C79A);
  static const navy = Color(0xFF00111F);
  static const panel = Color(0xFF071F33);
  static const border = Color(0xFF184362);
  static const muted = Color(0xFF75A0C2);
  static const danger = Color(0xFFFF4161);
}

class CryptoSimApp extends StatelessWidget {
  const CryptoSimApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CryptoSim',
      themeMode: state.isLightMode ? ThemeMode.light : ThemeMode.dark,
      darkTheme: _theme(Brightness.dark),
      theme: _theme(Brightness.light),
      home: state.isLoggedIn ? const HomeShell() : const LoginScreen(),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.mint,
      brightness: brightness,
      surface: dark ? AppColors.navy : const Color(0xFFF0F5FA),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? AppColors.navy : const Color(0xFFF0F5FA),
      fontFamily: 'Arial',
      dividerColor: dark ? AppColors.border : const Color(0xFFCCD9E5),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: dark ? Colors.white : AppColors.navy,
        titleTextStyle: TextStyle(
          color: dark ? Colors.white : AppColors.navy,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF061B2B) : Colors.white,
        indicatorColor: AppColors.mint.withValues(alpha: .14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.mint
                : AppColors.muted,
            fontSize: 11,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.mint
                : AppColors.muted.withValues(alpha: .55),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors.panel : Colors.white,
        hintStyle: const TextStyle(color: AppColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
