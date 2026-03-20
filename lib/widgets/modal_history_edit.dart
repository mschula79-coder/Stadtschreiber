import 'package:flutter/material.dart';
import 'package:stadtschreiber/services/datetime_service.dart';
import '../models/history_entry.dart';

class HistoryEditModal extends StatefulWidget {
  final String initialStart;
  final String? initialEnd;
  final String initialDescription;

  const HistoryEditModal({
    super.key,
    required this.initialStart,
    this.initialEnd,
    required this.initialDescription,
  });

  @override
  State<HistoryEditModal> createState() => _HistoryEditModalState();
}

class _HistoryEditModalState extends State<HistoryEditModal> {
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(text: widget.initialStart);
    _endController = TextEditingController(text: widget.initialEnd);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final start = _startController.text.trim();
    final end = _endController.text.trim();
    final description = _descriptionController.text.trim();

    if (!isValidDateInput(start)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ungültiges Startdatum")));
      return;
    }

    if (end.isNotEmpty && !isValidDateInput(end)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ungültiges Enddatum")));
      return;
    }

    final startDate = parseDateInput(start);
    final endDate = end.isNotEmpty ? parseDateInput(end) : null;

    Navigator.pop(
      context,
      HistoryEntry(
        rawStart: start,
        rawEnd: end.isNotEmpty ? end : null,
        start: startDate,
        end: endDate,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Geschichtseintrag bearbeiten"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _startController,
              decoration: const InputDecoration(
                labelText: "Beginn (JJJJ, TT.MM.JJJJ oder MM.JJJJ)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _endController,
              decoration: const InputDecoration(
                labelText: "Ende Zeitraum (optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLength: 200,
              maxLines: 8,
              decoration: InputDecoration(
                labelText:
                    "Beschreibung (${_descriptionController.text.length}/200 Zeichen) ",
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
