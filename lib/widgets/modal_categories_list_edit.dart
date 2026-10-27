import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/models/category_dto.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/category_repository_provider.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/repositories/category_repository.dart';
import 'package:stadtschreiber/utils/category_localization_utils.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:stadtschreiber/widgets/_editable_list.dart';

class CategoryEditor extends ConsumerWidget {
  const CategoryEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    final localeKey = CategoryLocalizationUtils.localeKey(
      locale,
    );

    final categoriesAsync = ref.watch(
      categoriesListProvider,
    );

    final repository = ref.read(
      categoriesRepositoryProvider,
    );

    return SingleChildScrollView(
      child: categoriesAsync.when(
        data: (categories) {
          final sortedCategories =
              CategoryLocalizationUtils.sortDtos(
                categories,
                localeKey,
              );

          return EditableList<CategoryDto>(
            items: sortedCategories,
            isEditModeEnabled: true,
            itemBuilder: (category) {
              return ListTile(
                tileColor: Colors.white,
                title: Text(
                  CategoryLocalizationUtils.labelForDto(
                    category,
                    localeKey,
                  ),
                ),
                subtitle: Text(category.slug),
              );
            },
            onAdd: () {
              return _showAddDialog(
                context,
                ref,
                repository,
                locale,
              );
            },
            onEdit: (category) {
              return _showEditDialog(
                context,
                ref,
                repository,
                category,
                locale,
              );
            },
            onDelete: (category) {
              return _confirmAndDelete(
                context,
                ref,
                repository,
                category,
                localeKey,
              );
            },
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Text(error.toString()),
          );
        },
      ),
    );
  }

  Future<CategoryDto?> _showAddDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryRepository repository,
    Locale locale,
  ) async {
    final translations = AppLocalizations.of(context)!;

    final germanController = TextEditingController();
    final englishController = TextEditingController();
    final frenchController = TextEditingController();
    final swissGermanController = TextEditingController();
    final slugController = TextEditingController();

    final result = await showDialog<CategoryDto?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(translations.add),
          content: SizedBox(
            width:
                MediaQuery.sizeOf(dialogContext).width *
                0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: germanController,
                    decoration: const InputDecoration(
                      labelText: 'Deutsch',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: englishController,
                    decoration: const InputDecoration(
                      labelText: 'English',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: frenchController,
                    decoration: const InputDecoration(
                      labelText: 'Français',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: swissGermanController,
                    decoration: const InputDecoration(
                      labelText: 'Baseldeutsch',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: slugController,
                    decoration: const InputDecoration(
                      labelText: 'Kategorie-Slug',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(translations.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final slug = slugController.text.trim();

                final labels = <String, String>{
                  'de-DE': germanController.text.trim(),
                  'en-US': englishController.text.trim(),
                  'fr-FR': frenchController.text.trim(),
                  'de-CH':
                      swissGermanController.text.trim(),
                };

                if (!_labelsAreValid(labels) ||
                    slug.isEmpty) {
                  return;
                }

                final newCategory =
                    await repository.addCategory(
                      slug: slug,
                      labels: labels,
                    );

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop(newCategory);
              },
              child: Text(
                getText(
                  'save',
                  languageCode: locale.languageCode,
                  countryCode: locale.countryCode,
                ),
              ),
            ),
          ],
        );
      },
    );

    germanController.dispose();
    englishController.dispose();
    frenchController.dispose();
    swissGermanController.dispose();
    slugController.dispose();

    if (result != null) {
      await _refreshCategories(ref);
    }

    return result;
  }

  Future<CategoryDto?> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryRepository repository,
    CategoryDto item,
    Locale locale,
  ) async {
    final translations = AppLocalizations.of(context)!;

    final localeKey =
        CategoryLocalizationUtils.localeKey(locale);

    final germanController = TextEditingController(
      text: item.labels['de-DE'] ?? '',
    );

    final englishController = TextEditingController(
      text: item.labels['en-US'] ?? '',
    );

    final frenchController = TextEditingController(
      text: item.labels['fr-FR'] ?? '',
    );

    final swissGermanController =
        TextEditingController(
          text: item.labels['de-CH'] ?? '',
        );

    final slugController = TextEditingController(
      text: item.slug,
    );

    final result = await showDialog<CategoryDto?>(
      context: context,
      builder: (dialogContext) {
        final screenSize = MediaQuery.sizeOf(
          dialogContext,
        );

        final maxHeight = screenSize.height * 0.75;
        final dialogWidth = screenSize.width * 0.85;

        return AlertDialog(
          title: Text(
            getText(
              'editCategory',
              languageCode: locale.languageCode,
              countryCode: locale.countryCode,
            ),
          ),
          content: SizedBox(
            width: dialogWidth,
            height: maxHeight,
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: germanController,
                          decoration:
                              const InputDecoration(
                                labelText: 'Deutsch',
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller:
                              englishController,
                          decoration:
                              const InputDecoration(
                                labelText: 'English',
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller:
                              frenchController,
                          decoration:
                              const InputDecoration(
                                labelText: 'Français',
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller:
                              swissGermanController,
                          decoration:
                              const InputDecoration(
                                labelText:
                                    'Baseldeutsch',
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: slugController,
                          decoration:
                              const InputDecoration(
                                labelText:
                                    'Kategorie-Slug',
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                Expanded(
                  flex: 3,
                  child: Consumer(
                    builder: (
                      consumerContext,
                      dialogRef,
                      child,
                    ) {
                      final childrenAsync =
                          dialogRef.watch(
                            childrenProvider(item.id),
                          );

                      return childrenAsync.when(
                        data: (children) {
                          final sortedChildren =
                              CategoryLocalizationUtils
                                  .sortDtos(
                                    children,
                                    localeKey,
                                  );

                          return Scrollbar(
                            child: SingleChildScrollView(
                              child:
                                  EditableList<CategoryDto>(
                                    items:
                                        sortedChildren,
                                    isEditModeEnabled:
                                        true,
                                    itemBuilder: (
                                      category,
                                    ) {
                                      return ListTile(
                                        tileColor:
                                            Colors.white,
                                        title: Text(
                                          CategoryLocalizationUtils
                                              .labelForDto(
                                                category,
                                                localeKey,
                                              ),
                                        ),
                                        subtitle: Text(
                                          category.slug,
                                        ),
                                      );
                                    },
                                    onAdd: () {
                                      return _showAddRelationDialog(
                                        dialogContext,
                                        dialogRef,
                                        repository,
                                        item.id,
                                        locale,
                                      );
                                    },
                                    onDelete: (
                                      childCategory,
                                    ) {
                                      return _confirmAndDeleteRelation(
                                        dialogContext,
                                        dialogRef,
                                        repository,
                                        item.id,
                                        childCategory,
                                        localeKey,
                                      );
                                    },
                                  ),
                            ),
                          );
                        },
                        loading: () {
                          return const Center(
                            child:
                                CircularProgressIndicator(),
                          );
                        },
                        error: (
                          error,
                          stackTrace,
                        ) {
                          return Center(
                            child: Text(
                              error.toString(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(translations.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final slug = slugController.text.trim();

                final labels = <String, String>{
                  'de-DE':
                      germanController.text.trim(),
                  'en-US':
                      englishController.text.trim(),
                  'fr-FR':
                      frenchController.text.trim(),
                  'de-CH': swissGermanController.text
                      .trim(),
                };

                if (!_labelsAreValid(labels) ||
                    slug.isEmpty) {
                  return;
                }

                final updatedCategory =
                    await repository.updateCategory(
                      id: item.id,
                      slug: slug,
                      labels: labels,
                    );

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop(updatedCategory);
              },
              child: Text(translations.save),
            ),
          ],
        );
      },
    );

    germanController.dispose();
    englishController.dispose();
    frenchController.dispose();
    swissGermanController.dispose();
    slugController.dispose();

    if (result != null) {
      await _refreshCategories(ref);
    }

    return result;
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryRepository repository,
    CategoryDto item,
    String localeKey,
  ) async {
    final translations = AppLocalizations.of(context)!;

    final categoryLabel =
        CategoryLocalizationUtils.labelForDto(
          item,
          localeKey,
        );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(translations.delete),
          content: Text(
            'Kategorie "$categoryLabel" löschen?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: Text(translations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: Text(translations.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await repository.deleteCategory(item.slug);
      await _refreshCategories(ref);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      await _showErrorDialog(
        context,
        error.toString(),
      );
    }
  }

  Future<CategoryDto?> _showAddRelationDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryRepository repository,
    String parentId,
    Locale locale,
  ) async {
    final translations = AppLocalizations.of(context)!;

    final localeKey =
        CategoryLocalizationUtils.localeKey(locale);

    final allCategories = await ref.read(
      categoriesListProvider.future,
    );

    final currentChildren = await ref.read(
      childrenProvider(parentId).future,
    );

    final currentChildIds = currentChildren
        .map((category) => category.id)
        .toSet();

    final candidates =
        CategoryLocalizationUtils.sortDtos(
          allCategories.where(
            (category) =>
                category.id != parentId &&
                !currentChildIds.contains(category.id),
          ),
          localeKey,
        );

    if (candidates.isEmpty) {
      if (!context.mounted) {
        return null;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(translations.add),
            content: const Text(
              'Keine verfügbaren Kategorien zum Hinzufügen.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      return null;
    }

    String? selectedId = candidates.first.id;

    if (!context.mounted) {
      return null;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Relation hinzufügen',
          ),
          content: StatefulBuilder(
            builder: (
              statefulContext,
              setState,
            ) {
              return DropdownButtonFormField<String>(
                initialValue: selectedId,
                isExpanded: true,
                items: candidates.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(
                      CategoryLocalizationUtils
                          .labelForDto(
                            category,
                            localeKey,
                          ),
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedId = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText:
                      'Kindkategorie wählen',
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: Text(translations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: Text(translations.add),
            ),
          ],
        );
      },
    );

    if (confirmed != true || selectedId == null) {
      return null;
    }

    try {
      await repository.addCategoryRelation(
        parentId: parentId,
        childId: selectedId!,
      );

      final addedCategory =
          candidates.firstWhereOrNull(
            (category) =>
                category.id == selectedId,
          );

      ref.invalidate(
        childrenProvider(parentId),
      );

      ref.invalidate(categoriesListProvider);

      await ref
          .read(categoriesProvider.notifier)
          .loadCategoryTree();

      return addedCategory;
    } catch (error) {
      if (!context.mounted) {
        return null;
      }

      await _showErrorDialog(
        context,
        error.toString(),
      );

      return null;
    }
  }

  Future<void> _confirmAndDeleteRelation(
    BuildContext context,
    WidgetRef ref,
    CategoryRepository repository,
    String parentId,
    CategoryDto child,
    String localeKey,
  ) async {
    final translations = AppLocalizations.of(context)!;

    final childLabel =
        CategoryLocalizationUtils.labelForDto(
          child,
          localeKey,
        );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Relation entfernen',
          ),
          content: Text(
            'Kindkategorie "$childLabel" von dieser Kategorie entfernen?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: Text(translations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: Text(translations.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await repository.deleteCategoryRelation(
        parentId: parentId,
        childId: child.id,
      );

      ref.invalidate(
        childrenProvider(parentId),
      );

      ref.invalidate(categoriesListProvider);

      await ref
          .read(categoriesProvider.notifier)
          .loadCategoryTree();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      await _showErrorDialog(
        context,
        error.toString(),
      );
    }
  }

  Future<void> _refreshCategories(
    WidgetRef ref,
  ) async {
    ref.invalidate(categoriesListProvider);

    await ref
        .read(categoriesProvider.notifier)
        .loadCategoryTree();
  }

  Future<void> _showErrorDialog(
    BuildContext context,
    String message,
  ) {
    final translations = AppLocalizations.of(context)!;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(translations.error),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(translations.confirm),
            ),
          ],
        );
      },
    );
  }

  bool _labelsAreValid(
    Map<String, String> labels,
  ) {
    return labels['de-DE']?.isNotEmpty == true &&
        labels['en-US']?.isNotEmpty == true &&
        labels['fr-FR']?.isNotEmpty == true &&
        labels['de-CH']?.isNotEmpty == true;
  }
}