import 'package:flutter/material.dart';

class BoolFeaturesEditorDialog extends StatefulWidget {
  final Map<String, bool> initialFeatures;
  final String dialogTitle;

  const BoolFeaturesEditorDialog({
    required this.dialogTitle,
    required this.initialFeatures, 
    super.key
  });

  @override
  State<BoolFeaturesEditorDialog> createState() =>
      _BoolFeaturesEditorDialogState();
}

class _BoolFeaturesEditorDialogState extends State<BoolFeaturesEditorDialog> {
  late Map<String, bool> features;

  @override
  void initState() {
    super.initState();
    features = Map.from(widget.initialFeatures);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView(
          children: features.entries.map((entry) {
            final key = entry.key;
            final value = entry.value;

            return SwitchListTile(
              title: Text(key),
              value: value,
              onChanged: (newValue) {
                setState(() {
                  features[key] = newValue;
                });
              },
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
          onPressed: () => Navigator.pop(context, features), 
          child: const Text("Speichern"),
        ),
      ],
    );

  }
}














