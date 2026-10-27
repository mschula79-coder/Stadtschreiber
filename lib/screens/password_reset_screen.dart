import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final passwordCtrl = TextEditingController();
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider).languageCode;
    final countryCode = ref.watch(localeProvider).countryCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(getText('setNewPassword', languageCode: languageCode, countryCode: countryCode)),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(getText('setNewPassword', languageCode: languageCode, countryCode: countryCode)),
            const SizedBox(height: 16),

            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: getText('newPassword', languageCode: languageCode, countryCode: countryCode),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),

            ElevatedButton(
              onPressed: loading ? null : _savePassword,
              child: loading
                  ? const CircularProgressIndicator()
                  : Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePassword() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: passwordCtrl.text.trim()),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/map');
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }
}
