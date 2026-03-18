import 'package:flutter/material.dart';
import '../models/article_entry.dart';

class ArticleEditModal extends StatefulWidget {
  final String initialTitle;
  final String initialUrl;

  const ArticleEditModal({
    super.key,
    required this.initialTitle,
    required this.initialUrl,
  });

  @override
  State<ArticleEditModal> createState() => _ArticleEditModalState();
}

class _ArticleEditModalState extends State<ArticleEditModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _urlController = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final url = _urlController.text.trim();

    if (title.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Titel und URL dürfen nicht leer sein")),
      );
      return;
    }

    Navigator.pop(
      context,
      ArticleEntry(title: title, url: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Artikel bearbeiten"),
      content: 
      
      Column(
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Abbrechen"),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text("Speichern"),
        ),
      ],
    );
  }
}
