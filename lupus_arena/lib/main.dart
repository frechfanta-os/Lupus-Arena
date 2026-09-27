import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splashscreen_ghdinteractivestudio/splashscreen_ghdinteractivestudio.dart';

import 'firebase_options.dart';
import 'services/locale_provider.dart';
import 'services/lupus_permission_service.dart';
import 'ui/screens/lobby_screen.dart';
import 'ui/theme/lupus_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error');
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('[ErrorWidget] Erreur de rendu interceptée : ${details.exception}');
    return const Material(
      color: Colors.transparent,
      child: SizedBox.shrink(),
    );
  };

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('[Firebase] Initialisation avec options : $e');
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e2) {
      debugPrint('[Firebase] Initialisation par défaut : $e2');
    }
  }

  LupusPermissionService().startBackgroundPermissionMonitor();

  final localeProvider = LocaleProvider.instance;
  await localeProvider.loadSavedLocale();

  runApp(
    ProviderScope(
      child: LupusArenaApp(localeProvider: localeProvider),
    ),
  );
}

class LupusArenaApp extends StatefulWidget {
  final LocaleProvider localeProvider;

  const LupusArenaApp({super.key, required this.localeProvider});

  @override
  State<LupusArenaApp> createState() => _LupusArenaAppState();
}

class _LupusArenaAppState extends State<LupusArenaApp> {
  bool _splashFinished = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.localeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'Lupus Arena',
          debugShowCheckedModeBanner: false,
          theme: LupusTheme.darkTheme,
          locale: widget.localeProvider.locale,
          supportedLocales: const [
            Locale('fr'),
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: _splashFinished
              ? LobbyScreen(localeProvider: widget.localeProvider)
              : AppSplashScreen(
                  appName: 'Lupus Arena',
                  appNameFontFamily: 'serif',
                  appNameStyle: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.normal,
                    letterSpacing: 1.5,
                    color: Color(0xFFF3E8FF),
                    shadows: [
                      Shadow(color: Color(0xFFC084FC), blurRadius: 12),
                      Shadow(color: Color(0xFF9333EA), blurRadius: 24),
                    ],
                  ),
                  appLogo: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/lupus_seal.png',
                      width: 76,
                      height: 76,
                      fit: BoxFit.contain,
                    ),
                  ),
                  companyName: 'ghdinteractivestudio',
                  companyPrefix: 'from',
                  companyNameGradient: AppSplashScreen.arcaneGradient,
                  themeMode: ThemeMode.dark,
                  backgroundColor: const Color(0xFF0B0E17),
                  duration: const Duration(milliseconds: 2200),
                  skipOnTap: true,
                  onFinish: () {
                    if (mounted) {
                      setState(() {
                        _splashFinished = true;
                      });
                    }
                  },
                ),
        );
      },
    );
  }
}
