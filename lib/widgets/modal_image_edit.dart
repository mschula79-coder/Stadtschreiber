import 'package:flutter/material.dart';
import 'package:stadtschreiber/models/image_entry.dart';

class ImageEditModal extends StatefulWidget {
  final String initialTitle;
  final String initialUrl;
  final String initialEnteredBy;
  final String initialCreditsName;
  final String initialCreditsUrl;

  const ImageEditModal({
    super.key,
    required this.initialTitle,
    required this.initialUrl,
    required this.initialEnteredBy,
    required this.initialCreditsName,
    required this.initialCreditsUrl,
  });

  @override
  State<ImageEditModal> createState() => _ImageEditModalState();
}

class _ImageEditModalState extends State<ImageEditModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  late final TextEditingController _enteredByController;
  late final TextEditingController _creditsNameController;
  late final TextEditingController _creditsUrlController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _urlController = TextEditingController(text: widget.initialUrl);
    _enteredByController = TextEditingController(text: widget.initialEnteredBy);
    _creditsNameController = TextEditingController(
      text: widget.initialCreditsName,
    );
    _creditsUrlController = TextEditingController(
      text: widget.initialCreditsUrl,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _enteredByController.dispose();
    _creditsNameController.dispose();
    _creditsUrlController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final url = _urlController.text.trim();
    final enteredBy = _enteredByController.text.trim();
    final creditsName = _creditsNameController.text.trim();
    final creditsUrl = _creditsUrlController.text.trim();

    if (title.isEmpty || url.isEmpty || enteredBy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Titel, URL und Eingetragen von dürfen nicht leer sein")),
      );
      return;
    }

    Navigator.pop(
      context,
      ImageEntry(
        title: title,
        url: url,
        enteredBy: enteredBy,
        creditsName: creditsName,
        creditsUrl: creditsUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Bildinformationen bearbeiten"),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 400, // or MediaQuery.of(context).size.height * 0.6
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Titel",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: "URL",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _enteredByController,
                decoration: const InputDecoration(
                  labelText: "Bild eingetragen von",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _creditsNameController,
                decoration: const InputDecoration(
                  labelText: "Credits Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _creditsUrlController,
                decoration: const InputDecoration(
                  labelText: "Credits Link",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
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
