import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';               

class EditableList<T> extends ConsumerWidget {
  final List<T> items;
  final bool isEditModeEnabled;

  final Future<T?> Function()? onAdd;
  final Future<T?> Function(T item)? onEdit;
  final Future<void> Function(T item)? onDelete;

  final Widget Function(T item) itemBuilder;

  const EditableList({
    super.key,
    required this.items,
    required this.isEditModeEnabled,
    this.onAdd,
    this.onEdit,
    this.onDelete,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(localeProvider).languageCode;
    final countryCode = ref.watch(localeProvider).countryCode;

    return ListView(
      padding: const EdgeInsets.all(0),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        if (onAdd != null && isEditModeEnabled)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(getText("add", languageCode: languageCode, countryCode: countryCode)),
              onPressed: () async {
                await onAdd!();
              },
            ),
          ),

        if (items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(getText('noEntries', languageCode: languageCode, countryCode: countryCode)),
          )
        else
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: itemBuilder(item)),
                  if (isEditModeEnabled) ...[
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async => await onEdit!(item),
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async => await onDelete!(item),
                      ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}
