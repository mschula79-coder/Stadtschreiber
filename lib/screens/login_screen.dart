import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/widgets/_icon_getter.dart';
import 'package:stadtschreiber/widgets/modal_message_box.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stadtschreiber/main.dart' show supportedLocales;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String? errorMessage;
  bool checkEmail = false;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    emailController.text = prefs.getString('last_email') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 600 ? 24.0 : width * 0.3;
    final emailText = AppLocalizations.of(context)!.email;
    final passwordText = AppLocalizations.of(context)!.password;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading) const CircularProgressIndicator(),

                // Hello
                Text(
                  AppLocalizations.of(context)!.hello,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                ),
                const Text(
                  "Stadtschreiber Basel",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: emailText,
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: passwordText,
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 0),

                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),

                // 🔥 Passwort zurücksetzen
                Row(
                  children: [
                    TextButton(
                      onPressed: _resetPassword,
                      child: Text(
                        AppLocalizations.of(context)!.passwordForgotten,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(),
                      child: Text(AppLocalizations.of(context)!.login),
                    ),

                    SizedBox(width: 20),

                    ElevatedButton(
                      onPressed: () async {
                        if (passwordController.value.text.length >= 8) {
                          await _askUsernameAndRegister();
                        } else {
                          messageBox(
                            context,
                            'Bitte Passwort mit min. 8 Zeichen setzen',
                            '',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(),
                      child: Text(AppLocalizations.of(context)!.register),
                    ),
                  ],
                ),
                checkEmail
                    ? Text(AppLocalizations.of(context)!.checkEmail,
                      style: TextStyle(color: Colors.red))
                    : const SizedBox.shrink(),

                const SizedBox(height: 40),

                buildLanguageDropdown(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    await _authAction(() async {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    });

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('last_email', emailController.text.trim());
  }

  Future<void> _askUsernameAndRegister() async {
    final usernameCtrl = TextEditingController();

    final username = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.chooseUserName),
        content: TextField(
          controller: usernameCtrl,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.userName,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel,
),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, usernameCtrl.text.trim());
            },
            child: Text(AppLocalizations.of(context)!.goOn,),
          ),
        ],
      ),
    );

    if (username == null || username.isEmpty) return;

    // Username speichern
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('pending_username', username);

    // Jetzt normal registrieren
    await _register();
  }

  Future<void> _register() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        emailRedirectTo: 'stadtschreiber://auth-callback',
      );

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('last_email', emailController.text.trim());

      // Kein session check hier!
      // User muss E-Mail bestätigen → Deep-Link → verifyOtp()

      setState(() {
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
        checkEmail = true;
      });
    }
  }

  Future<void> _authAction(Future<void> Function() action) async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await action();

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        setState(() => errorMessage = "Authentication failed");
        return;
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/map');
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final emailCtrl = TextEditingController(text: emailController.text);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.resetPassword),
        content: TextField(
          controller: emailCtrl,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.email,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              // 1) Dialog sofort schließen (synchron)
              Navigator.pop(context);

              // 2) Danach async ausführen
              _sendResetEmail(emailCtrl.text.trim());
            },
            child: Text(AppLocalizations.of(context)!.send),
          ),
        ],
      ),
    );
  }

  Future<void> _sendResetEmail(String email) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context)!.resetLinkSent;

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'stadtschreiber://auth-callback',
      );

      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Fehler: $e")));
    }
  }

  Widget buildLanguageDropdown(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // Hintergrund
        borderRadius: BorderRadius.circular(50), // ⭐ abgerundete Ecken
      ),
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),

      child: DropdownButton<Locale>(
        value: currentLocale,
        underline: const SizedBox(),
        onChanged: (locale) {
          if (locale != null) {
            ref.read(localeProvider.notifier).state = locale;
          }
        },
        items: supportedLocales.map((locale) {
          return DropdownMenuItem(
            value: locale,
            child: Row(
              children: [
                getIcon(locale.countryCode ?? locale.languageCode, 24, null),
                SizedBox(width: 8),
                Text(switch (locale.countryCode) {
                  'CH' => 'Schweizerdeutsch',
                  _ => switch (locale.languageCode) {
                    'de' => 'Deutsch',
                    'en' => 'English',
                    'fr' => 'Français',
                    _ => locale.languageCode,
                  },
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
