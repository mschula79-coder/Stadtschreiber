import 'package:flutter/material.dart';

Future<String?> openEditModal(
  BuildContext context, {
  required String fieldName,
  required String initialValue,
  required int maxLines,
}) {
  final controller = TextEditingController(text: initialValue);

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Edit $fieldName"),
        content: TextField(
          controller: controller,
          autofocus: false,
          decoration: InputDecoration(labelText: fieldName),
          maxLines: maxLines,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Save"),
          ),
        ],
      );
    },
  );
}

Future<bool?> openConfirmDialog(
  BuildContext context, {
  required String message,
  required String optionTrue,
  required String optionFalse,
}) {

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Achtung'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(optionTrue),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(optionFalse),
          ),
        ],
      );
    },
  );
}