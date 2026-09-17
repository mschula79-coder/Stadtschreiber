import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordCtrl = TextEditingController();
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.setNewPassword)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(AppLocalizations.of(context)!.pleaseEnterPassword),
            const SizedBox(height: 16),

            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.newPassword,
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
                  :  Text(AppLocalizations.of(context)!.save),
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
