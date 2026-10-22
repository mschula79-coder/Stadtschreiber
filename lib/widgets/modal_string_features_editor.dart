import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';


class StringFeaturesEditorDialog extends ConsumerStatefulWidget {
  final Map<String, String> initialValues;
  final String dialogTitle;

  const StringFeaturesEditorDialog({
    required this.dialogTitle,
    required this.initialValues,
    super.key,
  });

  @override
  ConsumerState<StringFeaturesEditorDialog> createState() =>
      _StringFeaturesEditorDialogState();
}

class _StringFeaturesEditorDialogState
    extends ConsumerState<StringFeaturesEditorDialog> {
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
    final languageCode = ref.watch(localeProvider).languageCode;
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
          child: Text(getText("close", languageCode: languageCode)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, values),
          child: Text(getText("save", languageCode: languageCode)),
        ),
      ],
    );
  }
}
