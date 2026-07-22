import 'package:flutter/material.dart';

class NameEditModal extends StatefulWidget {
  final String initialName;

  const NameEditModal({
    super.key,
    required this.initialName,
  });

  @override
  State<NameEditModal> createState() => _NameEditModalState();
}

class _NameEditModalState extends State<NameEditModal> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(
      text: widget.initialName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    
    final name = _nameController.text.trim();
  
    Navigator.pop(
      context,
      name
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Name eingeben"),
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
          child: const Text("Abbrechen"),
        ),
        ElevatedButton(onPressed: _save, child: const Text("Speichern")),
      ],
    );
  }
}
