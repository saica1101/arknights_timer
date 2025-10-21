import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'presentation/pages/home_page.dart';
import 'providers/stamina_provider.dart';
import 'providers/theme_provider.dart';
import 'data/services/notification_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();

  // Desktop 環境のみウィンドウ操作を行う（Android/iOS/Web では呼び出さない）
  final isDesktop =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);
  if (isDesktop) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(size: Size(360, 620), center: true);
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StaminaProvider>(
          create: (_) => StaminaProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider()..load(),
        ),
      ],
      child: const ArknightsTimerApp(),
    ),
  );
}

class ArknightsTimerApp extends StatelessWidget {
  const ArknightsTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    // Light/Dark テーマを指定色で構築（テキストは可読性を優先）
    final lightScheme =
        ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: AppColors.primaryLight,
        ).copyWith(
          primary: AppColors.primaryLight,
          onPrimary: Colors.black,
          secondary: AppColors.resetLight,
          onSecondary: Colors.black,
          surface: AppColors.cardLight,
          onSurface: Colors.black,
        );

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      cardColor: AppColors.cardLight,
      cardTheme: const CardThemeData(
        color: AppColors.cardLight,
        surfaceTintColor: Colors.transparent, // M3 のトーンオーバーレイを無効化
      ),
      colorScheme: lightScheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            final c = lightScheme.primary;
            if (states.contains(WidgetState.disabled)) {
              return c.withValues(alpha: 0.45);
            }
            return c;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            final c = lightScheme.onPrimary;
            if (states.contains(WidgetState.disabled)) {
              return c.withValues(alpha: 0.78);
            }
            return c;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(100, 44)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            final c = lightScheme.secondary;
            if (states.contains(WidgetState.disabled)) {
              return c.withValues(alpha: 0.45);
            }
            return c;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            final c = lightScheme.onSecondary;
            if (states.contains(WidgetState.disabled)) {
              return c.withValues(alpha: 0.78);
            }
            return c;
          }),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      fontFamily: 'Segoe UI Variable',
    );

    final darkScheme =
        ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: AppColors.primaryDark,
        ).copyWith(
          primary: AppColors.primaryDark,
          onPrimary: Colors.white,
          secondary: AppColors.resetDark,
          onSecondary: Colors.black,
          surface: AppColors.cardDark,
          onSurface: Colors.white,
        );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.cardDark,
      cardTheme: const CardThemeData(
        color: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: darkScheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            final c = darkScheme.primary;
            if (states.contains(WidgetState.disabled)) {
              return c.withValues(alpha: 0.45);
            }
            return c;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            final c = darkScheme.onPrimary;
            if (states.contains(WidgetState.disabled)) {
              return c.withValues(alpha: 0.78);
            }
            return c;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(100, 44)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            final c = darkScheme.secondary;
            if (states.contains(WidgetState.disabled)) {
              return c.withValues(alpha: 0.45);
            }
            return c;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            final c = darkScheme.onSecondary;
            if (states.contains(WidgetState.disabled)) {
              return c.withValues(alpha: 0.78);
            }
            return c;
          }),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      fontFamily: 'Segoe UI Variable',
    );

    return MaterialApp(
      title: 'アークナイツタイマー',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.mode, // ユーザー選択に追従（既定は system）
      home: const HomePage(),
    );
  }
}
