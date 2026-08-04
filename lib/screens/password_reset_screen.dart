import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      appBar: AppBar(title: const Text("Neues Passwort setzen")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Bitte gib dein neues Passwort ein."),
            const SizedBox(height: 16),

            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Neues Passwort",
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
                  : const Text("Speichern"),
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
