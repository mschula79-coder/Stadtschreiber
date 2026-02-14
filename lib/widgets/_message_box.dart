import 'package:flutter/material.dart';

Future<void> messageBox(BuildContext context, String message, String? title) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title ?? ''),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
