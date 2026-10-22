import 'package:flutter/material.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';


class RatingCriteriaEditModal extends ConsumerStatefulWidget {
  final RatingCriterionDTO criterionDTO;
  const RatingCriteriaEditModal({super.key, required this.criterionDTO});

  @override
  ConsumerState<RatingCriteriaEditModal> createState() =>
      _RatingCriteriaEditModalState();
}

class _RatingCriteriaEditModalState extends ConsumerState<RatingCriteriaEditModal> {
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
    final languageCode = ref.watch(localeProvider).languageCode;
    return Consumer(
      builder: (context, ref, _) {

        return AlertDialog(
          title: Text(getText("editRatingCriterion", languageCode: languageCode)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bezeichnung
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: getText("enterName", languageCode: languageCode),
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
              child: Text(getText("cancel", languageCode: languageCode)),
            ),
            ElevatedButton(onPressed: _save, child: Text(getText("save", languageCode: languageCode))),
          ],
        );
      },
    );
  }
}
