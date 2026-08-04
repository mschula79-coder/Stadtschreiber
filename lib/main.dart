import 'package:auto_hyphenating_text/auto_hyphenating_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/riverpod_logger.dart';
import 'package:stadtschreiber/screens/password_reset_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/app_root.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_links/app_links.dart'; // ⭐ NEU

const supportedLocales = [
  Locale('de', 'DE'),
  Locale('en', 'EN'),
  Locale('fr', 'FR'),
  Locale('de', 'CH'),
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHyphenation(DefaultResourceLoaderLanguage.de1996);

  await Supabase.initialize(
    url: 'https://ymniruxxduyewqvyjrve.supabase.co',
    publishableKey: 'sb_publishable_UoTQd39QJPhglwwJ-QQhHg_83s3h-Lo',
  );

  // ⭐ Session IMMER löschen
  await Supabase.instance.client.auth.signOut();

  runApp(ProviderScope(observers: [RiverpodLogger()], child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AppLinks _appLinks; // ⭐ Controller

  @override
  void initState() {
    super.initState();
    _setupDeepLinkListener();
  }

  void _setupDeepLinkListener() {
    _appLinks = AppLinks();

    // ⭐ Cold Start (App wird durch Deep-Link geöffnet)
    _appLinks.stringLinkStream.listen((String? link) {
      if (link == null) return;
      final uri = Uri.parse(link);
      _handleDeepLink(uri);
    });

    // ⭐ Hot Start (App läuft bereits)
    _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final code = uri.queryParameters['code'];

    if (code == null) {
      return;
    }

    // 1) Signup versuchen
    final signupResult = await Supabase.instance.client.auth.verifyOTP(
      type: OtpType.signup,
      token: code,
    );

    if (signupResult.user != null) {

      final response = await Supabase.instance.client.auth.getUser();
      final userId = response.user?.id;

      final prefs = await SharedPreferences.getInstance();
      final chosenUsername = prefs.getString('pending_username');

      await Supabase.instance.client.from('profiles').insert({
        'id': userId,
        'username': chosenUsername,
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/map');
      }

      return;
    }

    // 2) Recovery versuchen
    final recoveryResult = await Supabase.instance.client.auth.verifyOTP(
      type: OtpType.recovery,
      token: code,
    );

    if (recoveryResult.user != null) {
      print("Recovery erfolgreich");

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/reset-password');
      }

      return;
    }

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stadtschreiber',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      locale: ref.watch(localeProvider),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      home: const AppRoot(),
      routes: {
        '/map': (_) => const AppRoot(),
        '/reset-password': (_) => const ResetPasswordScreen(),
      },
    );
  }
}
