import 'package:flutter/material.dart';

class EditableList<T> extends StatelessWidget {
  final List<T> items;
  final bool isAdminViewEnabled;

  final Future<T?> Function()? onAdd;
  final Future<T?> Function(T item)? onEdit;
  final Future<void> Function(T item)? onDelete;

  final Widget Function(T item) itemBuilder;

  const EditableList({
    super.key,
    required this.items,
    required this.isAdminViewEnabled,
    this.onAdd,
    this.onEdit,
    this.onDelete,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        if (onAdd != null && isAdminViewEnabled)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Hinzufügen"),
              onPressed: () async {
                await onAdd!();
              },
            ),
          ),

        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("Keine Einträge vorhanden."),
          )
        else
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: itemBuilder(item)),
                  if (isAdminViewEnabled) ...[
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
