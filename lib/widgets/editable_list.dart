import 'package:flutter/material.dart';

class EditableList<T> extends StatelessWidget {
  final List<T> items;
  final bool isAdminViewEnabled;

  final Future<T?> Function() onAdd;
  final Future<T?> Function(T item) onEdit;
  final Future<void> Function(T item) onDelete;

  final Widget Function(T item) itemBuilder;

  const EditableList({
    super.key,
    required this.items,
    required this.isAdminViewEnabled,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isAdminViewEnabled)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Hinzufügen"),
              onPressed: () async {
                final newItem = await onAdd();
                if (newItem != null) {
                  // handled by parent
                }
              },
            ),
          ),

        Expanded(
          child: items.isEmpty
              ? const Center(child: Text("Keine Einträge vorhanden."))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: itemBuilder(item)),

                          if (isAdminViewEnabled) ...[
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final updated = await onEdit(item);
                                if (updated != null) {
                                  // handled by parent
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await onDelete(item);
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
