import 'package:flutter/material.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RatingCriteriaEditModal extends StatefulWidget {
  final RatingCriterionDTO criterionDTO;
  const RatingCriteriaEditModal({super.key, required this.criterionDTO});

  @override
  State<RatingCriteriaEditModal> createState() =>
      _RatingCriteriaEditModalState();
}

class _RatingCriteriaEditModalState extends State<RatingCriteriaEditModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.criterionDTO.name);
    _descriptionController = TextEditingController(
      text: widget.criterionDTO.description,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  void _save() {
    RatingCriterionDTO newCriterion = widget.criterionDTO.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );
    Navigator.pop(context, newCriterion);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {

        return AlertDialog(
          title: const Text("Bewertungskriterium bearbeiten"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bezeichnung
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Bezeichnung",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                //Beschreibung
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: "Beschreibung",
                    border: OutlineInputBorder(),
                  ),
                ),

                // Kategorien Baum
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
      },
    );
  }
}
