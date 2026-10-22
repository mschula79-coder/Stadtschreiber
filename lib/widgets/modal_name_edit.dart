import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';

class NameEditModal extends ConsumerStatefulWidget {
  final String initialName;

  const NameEditModal({super.key, required this.initialName});

  @override
  ConsumerState<NameEditModal> createState() => _NameEditModalState();
}

class _NameEditModalState extends ConsumerState<NameEditModal> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();

    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider).languageCode;

    return AlertDialog(
      title: Text(getText("enterName", languageCode: languageCode)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              maxLength: 50,
              maxLines: 1,
              decoration: InputDecoration(
                labelText:
                    "Beschreibung (${_nameController.text.length}/50 Zeichen) ",
                border: OutlineInputBorder(),
              ),
              onChanged: (newValue) {
                setState(() {});
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(getText("cancel", languageCode: languageCode)),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(getText("save", languageCode: languageCode)),
        ),
      ],
    );
  }
}
