import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/article_entry.dart';

class ArticleEditModal extends StatefulWidget {
  final String initialTitle;
  final String initialUrl;
  final String initialSource;
  final DateTime? initialDate;

  const ArticleEditModal({
    super.key,
    required this.initialTitle,
    required this.initialUrl,
    required this.initialSource,
    this.initialDate,
  });

  @override
  State<ArticleEditModal> createState() => _ArticleEditModalState();
}

class _ArticleEditModalState extends State<ArticleEditModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  late final TextEditingController _sourceController;
  late final TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _urlController = TextEditingController(text: widget.initialUrl);
    _sourceController = TextEditingController(text: widget.initialSource);
    if (widget.initialDate == null) {
      _dateController = TextEditingController(text: '');
    } else {
      _dateController = TextEditingController(
        text: DateFormat('dd.MM.yyyy').format(widget.initialDate!),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _sourceController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final url = _urlController.text.trim();
    final source = _sourceController.text.trim();

    DateTime? date;
    final dateText = _dateController.text.trim();

    if (dateText.isNotEmpty) {
      date = DateFormat('dd.MM.yyyy').parse(dateText);
    }

    if (title.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Titel, URL und Quelle dürfen nicht leer sein"),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      ArticleEntry(title: title, url: url, source: source, date: date),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Artikel bearbeiten"),
      content: Column(
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
            controller: _sourceController,
            decoration: const InputDecoration(
              labelText: "Quelle",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  final text = _dateController.text.trim();
                  DateTime initial = DateTime.now();

                  if (text.isNotEmpty) {
                    try {
                      initial = DateFormat('dd.MM.yyyy').parseStrict(text);
                    } catch (_) {}
                  }

                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    setState(() {
                      _dateController.text = DateFormat(
                        'dd.MM.yyyy',
                      ).format(picked);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: "Datum",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),

              // 🔥 Der kleine "Datum löschen"-Button
              TextButton(
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(EdgeInsets.zero),
                  minimumSize: WidgetStateProperty.all(Size(0, 0)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  setState(() {
                    _dateController.clear();
                  });
                },
                child: const Text(
                  "  Datum löschen",
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
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
