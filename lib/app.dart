import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'features/home/home_screen.dart';
import 'core/widgets/auth_gate.dart';
import 'features/radio/radio_controller.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const Color _primary = Color(0xFF182857);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRadio();
    });
  }

  Future<void> _initializeRadio() async {
    final controller = context.read<RadioController>();
    var startService = true;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        var status = await Permission.notification.status;
        if (!status.isGranted) {
          status = await Permission.notification.request();
        }
        if (!status.isGranted) {
          startService = false;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Для отображения медиа-уведомления необходимо разрешить уведомления.',
                ),
              ),
            );
          }
        }
      }
    }
    await controller.init(startService: startService);
    debugPrint('notificationsEnabled: ${controller.notificationsEnabled}');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFFF5F5F5),
          onPrimary: Colors.black,
          surface: const Color(0xFFFAFAFA),
          surfaceVariant: const Color(0xFFF0F0F0),
          background: Colors.white,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      cardColor: Colors.transparent,
      canvasColor: Colors.transparent,
    );

    return MaterialApp(
      title: 'M-Club',
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: base.copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: _primary,
          unselectedLabelColor: Colors.black54,
          labelStyle: base.textTheme.titleMedium?.copyWith(
            fontSize: (base.textTheme.titleMedium?.fontSize ?? 14) + 2,
          ),
          unselectedLabelStyle: base.textTheme.titleMedium?.copyWith(
            fontSize: (base.textTheme.titleMedium?.fontSize ?? 14) + 2,
          ),
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: _primary, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: _primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _primary),
        ),
        textTheme: base.textTheme.copyWith(
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w400,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w400,
          ),
          titleSmall: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w400,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w300,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w300,
          ),
          bodySmall: base.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      home: const AuthGate(child: HomeScreen()),
    );
  }
}
