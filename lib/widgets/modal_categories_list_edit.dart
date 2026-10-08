import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/models/category_dto.dart';
import 'package:stadtschreiber/provider/category_repository_provider.dart';
import 'package:stadtschreiber/repositories/category_repository.dart';
import 'package:stadtschreiber/widgets/_editable_list.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';

class CategoryEditor extends ConsumerWidget {
  const CategoryEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final repo = ref.read(categoriesRepositoryProvider);

    return SingleChildScrollView(
      child: categoriesAsync.when(
        data: (categories) {
          return EditableList<CategoryDto>(
            items: categories,
            isEditModeEnabled: true,
            itemBuilder: (c) => ListTile(
              tileColor: Colors.white,
              title: Text(c.name),
              subtitle: Text(c.slug),
            ),
            onAdd: () => _showAddDialog(context, ref, repo),
            onEdit: (item) => _showEditDialog(context, ref, repo, item),
            onDelete: (item) => _confirmAndDelete(context, ref, repo, item),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Fehler: $err')),
      ),
    );
  }

  Future<CategoryDto?> _showAddDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryRepository repo,
  ) async {
    final t = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();

    final result = await showDialog<CategoryDto?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.add),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width * 0.85,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: t.name),
                ),
                TextField(
                  controller: slugCtrl,
                  decoration: InputDecoration(labelText: "Category Slug"),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final slug = slugCtrl.text.trim();
              if (name.isEmpty) return;
              final newDto = await repo.addCategory(name: name, slug: slug);
              if (!context.mounted) return;
              Navigator.of(ctx).pop(newDto);
            },
            child: Text(t.save),
          ),
        ],
      ),
    );

    if (result != null) {
      ref.invalidate(categoriesListProvider);
    }
    return result;
  }

  Future<CategoryDto?> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryRepository repo,
    CategoryDto item,
  ) async {
    final t = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: item.name);
    final slugCtrl = TextEditingController(text: item.slug);

    final result = await showDialog<CategoryDto?>(
      context: context,
      builder: (ctx) {
        // Maximalhöhe relativ zur Bildschirmhöhe
        final maxHeight = MediaQuery.of(ctx).size.height * 0.6;
        final dialogWidth = MediaQuery.of(ctx).size.width * 0.85;

        // Wir verwenden eine feste Box (SizedBox) mit begrenzter Höhe,
        // damit der scrollbare Bereich (EditableList / ListView) eine
        // definierte Höhe hat und kein ShrinkWrappingViewport-Fehler entsteht.
        return AlertDialog(
          title: Text("Kategorie bearbeiten"),
          content: SizedBox(
            width: dialogWidth,
            height: maxHeight,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Kopfbereich: Felder
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: t.name),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: slugCtrl,
                  decoration: InputDecoration(labelText: "Kategorie Slug"),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: Consumer(
                    builder: (dialogContext, dialogRef, _) {
                      final childrenAsync = dialogRef.watch(
                        childrenProvider(item.id),
                      );

                      return childrenAsync.when(
                        data: (children) {
                          return Scrollbar(
                            child: SingleChildScrollView(
                              child: EditableList<CategoryDto>(
                                items: children,
                                isEditModeEnabled: true,
                                itemBuilder: (c) => ListTile(
                                  tileColor: Colors.white,
                                  title: Text(c.name),
                                  subtitle: Text(c.slug),
                                ),
                                onAdd: () => _showAddRelationDialog(
                                  context,
                                  dialogRef,
                                  repo,
                                  item.id,
                                ),
                                onDelete: (child) => _confirmAndDeleteRelation(
                                  context,
                                  dialogRef,
                                  repo,
                                  item.id,
                                  child,
                                ),
                              ),
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, st) => Center(child: Text('Fehler: $err')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final slug = slugCtrl.text.trim();
                if (name.isEmpty) return;
                final updated = await repo.updateCategory(
                  id: item.id,
                  name: name,
                  slug: slug,
                );
                if (!context.mounted) return;
                Navigator.of(ctx).pop(updated);
              },
              child: Text(t.save),
            ),
          ],
        );
      },
    );

    if (result != null) {
      ref.invalidate(categoriesListProvider);
    }
    return result;
  }

  // Beispiel: Aufruf in der UI mit Fehlerbehandlung und Meldung an den Nutzer
  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryRepository repo,
    CategoryDto item,
  ) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.delete),
        content: Text('Lösche Kategorie'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await repo.deleteCategory(item.slug);
      ref.invalidate(categoriesListProvider);
    } catch (e) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.delete),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.confirm),
            ),
          ],
        ),
      );
    }
  }

  Future<CategoryDto?> _showAddRelationDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryRepository repo,
    String parentId,
  ) async {
    final t = AppLocalizations.of(context)!;

    final allAsync = ref.read(categoriesListProvider);
    final allCategories = allAsync.when(
      data: (list) => list,
      loading: () => <CategoryDto>[],
      error: (_, _) => <CategoryDto>[],
    );

    // aktuelle Kinder laden
    final currentChildren = await ref.read(childrenProvider(parentId).future);
    final currentChildIds = currentChildren.map((c) => c.id).toSet();

    final candidates =
        allCategories
            .where((c) => c.id != parentId && !currentChildIds.contains(c.id))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    if (candidates.isEmpty) {
      if (!context.mounted) return null;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.add),
          content: Text('Keine verfügbaren Kategorien zum Hinzufügen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Ok'),
            ),
          ],
        ),
      );
      return null;
    }

    String? selectedId = candidates.first.id;

    if (!context.mounted) return null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Relation hinzufügen'),
        content: StatefulBuilder(
          builder: (ctx2, setState) {
            return DropdownButtonFormField<String>(
              initialValue: selectedId,
              items: candidates
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedId = v),
              decoration: InputDecoration(labelText: 'Kindkategorie wählen'),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.add),
          ),
        ],
      ),
    );

    if (confirmed != true || selectedId == null) return null;

    try {
      await repo.addCategoryRelation(parentId: parentId, childId: selectedId!);

      final added = candidates.firstWhereOrNull((c) => c.id == selectedId);
      ref.invalidate(childrenProvider(parentId));
      ref.invalidate(categoriesListProvider);

      return added;
    } catch (e) {
      if (!context.mounted) return null;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Fehler'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Ok'),
            ),
          ],
        ),
      );
      return null;
    }
  }

  Future<void> _confirmAndDeleteRelation(
    BuildContext context,
    WidgetRef ref,
    CategoryRepository repo,
    String parentId,
    CategoryDto child,
  ) async {
    final t = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Relation entfernen'),
        content: Text(
          'Kindkategorie "${child.name}" von dieser Kategorie entfernen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await repo.deleteCategoryRelation(parentId: parentId, childId: child.id);
      ref.invalidate(categoriesListProvider);
      ref.invalidate(childrenProvider(parentId));
    } catch (e) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Fehler'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text("Ok"),
            ),
          ],
        ),
      );
    }
  }
}
