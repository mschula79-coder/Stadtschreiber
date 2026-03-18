import 'package:flutter/material.dart';

Future<bool> confirmBox(
  BuildContext context,
  String message,
  String? title,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title ?? ''),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
