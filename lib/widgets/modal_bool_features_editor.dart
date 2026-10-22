import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';


class BoolFeaturesEditorDialog extends ConsumerStatefulWidget {
  final Map<String, bool> initialFeatures;
  final String dialogTitle;

  const BoolFeaturesEditorDialog({
    required this.dialogTitle,
    required this.initialFeatures,
    super.key,
  });

  @override
  ConsumerState<BoolFeaturesEditorDialog> createState() =>
      _BoolFeaturesEditorDialogState();
}

class _BoolFeaturesEditorDialogState extends ConsumerState<BoolFeaturesEditorDialog> {
  late Map<String, bool> features;

  @override
  void initState() {
    super.initState();
    features = Map.from(widget.initialFeatures);
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider).languageCode;
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
              tileColor: Colors.white,
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
          child: Text(getText("close", languageCode: languageCode)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, features),
          child: Text(getText("save", languageCode: languageCode)),
        ),
      ],
    );
  }
}
