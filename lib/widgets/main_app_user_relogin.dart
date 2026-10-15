import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stadtschreiber/utils/language_utils.dart';

Future<void> showReLoginDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(getText('loginRequired')),
      content: Text(getText('msgRoleUpdate')),
      actions: [
        TextButton(
          onPressed: () async {
            final navigator = Navigator.of(context);

            await Supabase.instance.client.auth.signOut();

            navigator.pushNamedAndRemoveUntil('/login', (_) => false);
          },
          child: Text(getText('msgNewLogin')),
        ),
      ],
    ),
  );
}
