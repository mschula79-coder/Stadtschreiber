import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showReLoginDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text("Neu einloggen erforderlich"),
      content: const Text(
        "Deine Rollen wurden aktualisiert. "
        "Bitte melde dich einmal neu an, damit die Änderungen aktiv werden.",
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final navigator = Navigator.of(context);

            await Supabase.instance.client.auth.signOut();

            navigator.pushNamedAndRemoveUntil('/login', (_) => false);
          },
          child: const Text("Jetzt neu einloggen"),
        ),
      ],
    ),
  );
}
