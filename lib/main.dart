import 'dart:async';

import 'package:auto_hyphenating_text/auto_hyphenating_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/riverpod_logger.dart';
import 'package:stadtschreiber/screens/password_reset_screen.dart';
import 'package:stadtschreiber/widgets/app_root.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supportedLocales = [
  Locale('de', 'DE'),
  Locale('en', 'EN'),
  Locale('fr', 'FR'),
  Locale('de', 'CH'),
];

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initHyphenation(DefaultResourceLoaderLanguage.de1996);

  await Supabase.initialize(
    url: 'https://ymniruxxduyewqvyjrve.supabase.co',
    publishableKey: 'sb_publishable_UoTQd39QJPhglwwJ-QQhHg_83s3h-Lo',
  );

  runApp(ProviderScope(observers: [RiverpodLogger()], child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _recoveryNavigationScheduled = false;
  late final bool _initialPasswordRecovery;

  @override
  void initState() {
    super.initState();

    _initialPasswordRecovery =
        kIsWeb && Uri.base.queryParameters['passwordRecovery'] == 'true';

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      _handleAuthStateChange,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Auth state error: $error');
      },
    );
  }

  void _handleAuthStateChange(AuthState authState) {
    if (authState.event != AuthChangeEvent.passwordRecovery) {
      return;
    }

    if (_recoveryNavigationScheduled) {
      return;
    }

    _recoveryNavigationScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = rootNavigatorKey.currentState;

      if (navigator == null) {
        _recoveryNavigationScheduled = false;
        return;
      }

      navigator.pushNamedAndRemoveUntil('/reset-password', (route) => false);

      _recoveryNavigationScheduled = false;
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceSans3FontFamily = GoogleFonts.sourceSans3().fontFamily;

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Stadtschreiber',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: sourceSans3FontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF145968),
          primaryContainer: const Color.fromARGB(255, 225, 225, 225),
        ),
      ),
      locale: ref.watch(localeProvider),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      home: _initialPasswordRecovery
          ? const ResetPasswordScreen()
          : const AppRoot(),
      routes: {
        '/map': (_) => const AppRoot(),
        '/reset-password': (_) => const ResetPasswordScreen(),
      },
    );
  }
}
