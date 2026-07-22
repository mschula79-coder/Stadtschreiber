import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/widgets/_icon_getter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stadtschreiber/main.dart' show supportedLocales;

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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 600 ? 24.0 : width * 0.3;
final emailText= AppLocalizations.of(context)!.email;
final passwordText = AppLocalizations.of(context)!.password;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.hello),
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

                const SizedBox(height: 16),

                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),

                if (loading)
                  const CircularProgressIndicator()
                else
                  Column(
                    children: [
                      buildLanguageDropdown(context, ref),
                      const SizedBox(height: 8),

                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: Text(AppLocalizations.of(context)!.login),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: Text(AppLocalizations.of(context)!.register),
                      ),
                      const SizedBox(height: 16),

                      // 🔥 Passwort zurücksetzen
                      TextButton(
                        onPressed: _resetPassword,
                        child: Text(
                          AppLocalizations.of(context)!.passwordForgotten,
                        ),
                      ),
                    ],
                  ),
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
  }

  Future<void> _register() async {
    await _authAction(() async {
      await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    });
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
    final emailCtrl = TextEditingController();

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
      await Supabase.instance.client.auth.resetPasswordForEmail(email);

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
                getIcon(locale.countryCode ?? locale.languageCode),
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
