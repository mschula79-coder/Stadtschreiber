import 'package:flutter/material.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';               

class EditableList<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
              label: Text(AppLocalizations.of(context)!.add),
              onPressed: () async {
                await onAdd!();
              },
            ),
          ),

        if (items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(AppLocalizations.of(context)!.noEntries),
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
