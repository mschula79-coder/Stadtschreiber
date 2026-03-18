import 'package:flutter/material.dart';

class StringFeaturesEditorDialog extends StatefulWidget {
  final Map<String, String> initialValues;
  final String dialogTitle;

  const StringFeaturesEditorDialog({
    required this.dialogTitle,
    required this.initialValues,
    super.key,
  });

  @override
  State<StringFeaturesEditorDialog> createState() =>
      _StringFeaturesEditorDialogState();
}

class _StringFeaturesEditorDialogState
    extends State<StringFeaturesEditorDialog> {
  late Map<String, String> values;
  final Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();

    values = Map.from(widget.initialValues);

    for (final entry in values.entries) {
      controllers[entry.key] = TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    // Controller sauber freigeben
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView(
          children: values.keys.map((key) {
            final controller = controllers[key]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: key,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (newValue) {
                  values[key] = newValue;
                },
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, values),
          child: const Text("Speichern"),
        ),
      ],
    );
  }
}
