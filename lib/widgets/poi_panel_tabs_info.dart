import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:stadtschreiber/models/address.dart';
import 'package:stadtschreiber/models/poi_feature_node.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/categories_localized_provider.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:stadtschreiber/utils/dialog_utils.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:stadtschreiber/utils/url_utils.dart';
import 'package:stadtschreiber/widgets/modal_address_edit.dart';
import 'package:stadtschreiber/widgets/modal_poi_categories_edit.dart';
import 'package:stadtschreiber/widgets/modal_poi_geometry_edit.dart';
import 'package:stadtschreiber/widgets/modal_string_features_editor.dart';
import 'package:stadtschreiber/provider/poi_features_provider.dart';
import 'package:stadtschreiber/provider/pois_for_categories_provider.dart';
import 'package:stadtschreiber/provider/radius_filtered_pois_provider.dart';
import 'package:stadtschreiber/widgets/modal_poi_features_edit.dart';

class PoiPanelInfoTab extends ConsumerWidget {
  const PoiPanelInfoTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DebugService.log('build PoiPanelInfoTab $this.key $this.hashcode');
    final languageCode = ref.watch(localeProvider).languageCode;
    final countryCode = ref.watch(localeProvider).countryCode;

    final selectedPoi = ref.watch(selectedPoiProvider);
    final isEditor = ref.watch(supabaseUserStateProvider.notifier).isEditor();
    final isEditModeEnabled =
        ref.watch(appStateProvider).isPoiEditMode && isEditor;

    if (selectedPoi == null) return SizedBox.shrink();

    final poiFeaturesAsync = ref.watch(poiFeaturesProvider(selectedPoi.id));
    final location = selectedPoi.location;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Edit Button
          Stack(
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  labelText: getText(
                    "name",
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                  alignLabelWithHint: true,
                  isDense: true,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: EdgeInsets.fromLTRB(0, 0, 35, 5),
                ),
                child: Text(
                  selectedPoi.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              isEditModeEnabled
                  ? Positioned(
                      right: 0,
                      top: 5,
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final newValue = await openEditModal(
                            context,
                            fieldName: getText(
                              'name',
                              languageCode: languageCode,
                              countryCode: countryCode,
                            ),
                            initialValue: selectedPoi.name,
                            maxLines: 1,
                          );
                          if (newValue != null) {
                            ref
                                .read(poiRepositoryProvider)
                                .updatePoiDataInSupabase(
                                  id: selectedPoi.id,
                                  name: newValue,
                                );
                            ref
                                .read(selectedPoiProvider.notifier)
                                .setPoi(selectedPoi.copyWith(name: newValue));
                            //ref.invalidate(visiblePoisProvider);
                          }
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 8),

          // Stack Beschreibung mit Bearbeitung
          Stack(
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  labelText: getText(
                    "description",
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                  alignLabelWithHint: true,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  isDense: true,
                  labelStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  contentPadding: EdgeInsets.fromLTRB(0, 0, 35, 5),
                ),
                child: Text(selectedPoi.description ?? '', softWrap: true),
              ),

              // Edit button
              if (isEditModeEnabled)
                Positioned(
                  right: 0,
                  top: 5,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final newValue = await openEditModal(
                        context,
                        fieldName: getText(
                          'description',
                          languageCode: languageCode,
                          countryCode: countryCode,
                        ),
                        initialValue: selectedPoi.description ?? '',
                        maxLines: 10,
                      );
                      if (newValue != null) {
                        ref
                            .read(poiRepositoryProvider)
                            .updatePoiDataInSupabase(
                              id: selectedPoi.id,
                              description: newValue,
                            );
                        ref
                            .read(selectedPoiProvider.notifier)
                            .setPoi(
                              selectedPoi.copyWith(description: newValue),
                            );
                      }
                    },
                  ),
                ),
            ],
          ),

          // Textfeld Adresse read only
          Stack(
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  labelText: getText(
                    'address',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                ),
                child: selectedPoi.address?.displayAddress == null
                    ? Text('')
                    : Text(
                        '${selectedPoi.address?.city ?? ''}, ${selectedPoi.address?.street ?? ''} ${selectedPoi.address?.houseNumber ?? ''}',
                      ),
              ),
              if (isEditModeEnabled)
                Positioned(
                  right: 0,
                  top: 5,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final updatedAddress = await showDialog<Address>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => AddressEditModal(
                          address: selectedPoi.address ?? Address(),
                        ),
                      );

                      if (updatedAddress != null) {
                        final updatedPoi = selectedPoi.copyWith(
                          address: updatedAddress,
                        );

                        ref
                            .read(poiRepositoryProvider)
                            .updatePoiAddressInSupabase(
                              selectedPoi.id,
                              updatedAddress,
                            );

                        ref
                            .read(selectedPoiProvider.notifier)
                            .setPoi(updatedPoi);
                      }
                    },
                  ),
                ),
            ],
          ),
          // Stack links editable
          Stack(
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  labelText: getText(
                    'links',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                  alignLabelWithHint: true,
                  contentPadding: isEditModeEnabled
                      ? const EdgeInsets.fromLTRB(0, 8, 35, 5)
                      : const EdgeInsets.fromLTRB(0, 8, 0, 5),
                ),
                child: Row(
                  children: [
                    SizedBox(height: 20, width: 0),
                    selectedPoi.metadata.getWebsiteLink().isNotEmpty
                        ? InkWell(
                            onTap: () => openLink(
                              context,
                              selectedPoi.metadata.getWebsiteLink(),
                            ),
                            child: Row(
                              children: [
                                Iconify(Mdi.internet, size: 24),
                                const SizedBox(width: 10),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),

                    selectedPoi.metadata.getGoogleMapsLink().isNotEmpty
                        ? InkWell(
                            onTap: () => openLink(
                              context,
                              selectedPoi.metadata.getGoogleMapsLink(),
                            ),
                            child: Row(
                              children: [
                                Iconify(Mdi.google_maps, size: 24),
                                const SizedBox(width: 10),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    selectedPoi.metadata.getOSMLink().isNotEmpty
                        ? InkWell(
                            onTap: () => openLink(
                              context,
                              selectedPoi.metadata.getOSMLink(),
                            ),
                            child: Row(
                              children: [
                                Iconify(Mdi.map, size: 24),
                                const SizedBox(width: 10),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    selectedPoi.metadata.getAppleMapsLink().isNotEmpty
                        ? InkWell(
                            onTap: () => openLink(
                              context,
                              selectedPoi.metadata.getAppleMapsLink(),
                            ),
                            child: Row(
                              children: [
                                Iconify(Mdi.apple, size: 24),
                                const SizedBox(width: 10),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    selectedPoi.metadata.getWikipediaLink().isNotEmpty
                        ? InkWell(
                            onTap: () => openLink(
                              context,
                              selectedPoi.metadata.getWikipediaLink(),
                            ),
                            child: Row(
                              children: [
                                Iconify(Mdi.wikipedia, size: 24),
                                const SizedBox(width: 10),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              //Edit links
              if (isEditModeEnabled)
                Positioned(
                  right: 0,
                  top: 5,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final newLinks = await showDialog<Map<String, String>>(
                        context: context,
                        builder: (_) => StringFeaturesEditorDialog(
                          dialogTitle: getText(
                            'editLinks',
                            languageCode: languageCode,
                            countryCode: countryCode,
                          ),
                          initialValues: selectedPoi.metadata.getLinks(),
                        ),
                      );
                      final updatedPoi = selectedPoi.copyWith();
                      if (newLinks != null) {
                        updatedPoi.metadata.setLinks(newLinks);
                      }
                      ref
                          .read(poiRepositoryProvider)
                          .updatePoiDataInSupabase(
                            id: selectedPoi.id,
                            metadata: updatedPoi.metadata,
                          );

                      ref.read(selectedPoiProvider.notifier).setPoi(updatedPoi);
                      //ref.invalidate(visiblePoisProvider);
                    },
                  ),
                ),
            ],
          ),
          // Kategorien
          Stack(
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  labelText: getText(
                    'categories',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                  alignLabelWithHint: true,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: isEditModeEnabled
                      ? const EdgeInsets.fromLTRB(0, 8, 35, 10)
                      : const EdgeInsets.fromLTRB(0, 8, 0, 10),
                ),
                child: _buildCategoryChips(selectedPoi.categories, ref),
              ),

              if (isEditModeEnabled)
                Positioned(
                  right: 0,
                  top: 5,
                  child: IconButton(
                    tooltip: getText(
                      'editCategories',
                      languageCode: languageCode,
                      countryCode: countryCode,
                    ),
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      await showPoiCategoriesEditModal(
                        context,
                        pois: [selectedPoi],
                      );

                      if (!context.mounted) {
                        return;
                      }

                      final updatedPoi = await ref
                          .read(poiRepositoryProvider)
                          .loadPoiById(selectedPoi.id);

                      if (updatedPoi == null) {
                        return;
                      }

                      ref.read(selectedPoiProvider.notifier).setPoi(updatedPoi);

                      ref.invalidate(radiusFilteredPoisProvider);

                      ref.invalidate(poisForCategoriesProvider);
                    },
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),
          // Feature icons editable
          Stack(
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  labelText: getText(
                    'features',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                  alignLabelWithHint: true,
                  contentPadding: isEditModeEnabled
                      ? const EdgeInsets.fromLTRB(0, 8, 35, 5)
                      : const EdgeInsets.fromLTRB(0, 8, 0, 5),
                ),
                child: poiFeaturesAsync.when(
                  data: (featureTree) {
                    final selectedFeatures = _collectSelectedLeafFeatures(
                      featureTree,
                    );

                    if (selectedFeatures.isEmpty) {
                      return const SizedBox(height: 20);
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedFeatures
                          .map(
                            (feature) => Chip(
                              avatar: const Icon(Icons.check, size: 16),
                              label: Text(feature.label),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                  loading: () {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: LinearProgressIndicator(),
                    );
                  },
                  error: (error, stackTrace) {
                    return Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (isEditModeEnabled)
                Positioned(
                  right: 0,
                  top: 5,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final featureTree = await ref.read(
                        poiFeaturesProvider(selectedPoi.id).future,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      final selectedFeatureSlugs =
                          await showDialog<Set<String>>(
                            context: context,
                            barrierDismissible: false,
                            builder: (dialogContext) {
                              return PoiFeaturesEditDialog(
                                dialogTitle: getText(
                                  'editFeatures',
                                  languageCode: languageCode,
                                  countryCode: countryCode,
                                ),
                                featureTree: featureTree,
                              );
                            },
                          );

                      if (selectedFeatureSlugs == null) {
                        return;
                      }

                      await ref
                          .read(poiRepositoryProvider)
                          .replacePoiFeatures(
                            poiId: selectedPoi.id,
                            featureSlugs: selectedFeatureSlugs,
                          );

                      ref.invalidate(poiFeaturesProvider(selectedPoi.id));

                      ref.invalidate(radiusFilteredPoisProvider);

                      ref.invalidate(poisForCategoriesProvider);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Standort und Geometrie
          Stack(
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  labelText: getText(
                    'location',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                  alignLabelWithHint: true,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  isDense: true,
                  contentPadding: isEditModeEnabled
                      ? const EdgeInsets.fromLTRB(0, 8, 35, 5)
                      : const EdgeInsets.fromLTRB(0, 8, 0, 5),
                ),
                child: Text(
                  '${location.lat.toStringAsFixed(6)}, '
                  '${location.lon.toStringAsFixed(6)}',
                ),
              ),
              if (isEditModeEnabled)
                Positioned(
                  right: 0,
                  top: 5,
                  child: IconButton(
                    tooltip: getText(
                      'editLocation',
                      languageCode: languageCode,
                      countryCode: countryCode,
                    ),
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      await showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) {
                          return PointerInterceptor(
                            child: PoiGeometryEditDialog(poi: selectedPoi),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<PoiFeatureNode> collectSelectedLeaves(List<PoiFeatureNode> nodes) {
    final result = <PoiFeatureNode>[];

    void collect(List<PoiFeatureNode> currentNodes) {
      for (final node in currentNodes) {
        if (node.isLeaf) {
          if (node.isSelected) {
            result.add(node);
          }
        } else {
          collect(node.children);
        }
      }
    }

    collect(nodes);

    return result;
  }

  List<PoiFeatureNode> _collectSelectedLeafFeatures(
    List<PoiFeatureNode> nodes,
  ) {
    final selectedFeatures = <PoiFeatureNode>[];

    void collect(List<PoiFeatureNode> currentNodes) {
      for (final node in currentNodes) {
        if (node.isLeaf) {
          if (node.isSelected) {
            selectedFeatures.add(node);
          }
        } else {
          collect(node.children);
        }
      }
    }

    collect(nodes);

    selectedFeatures.sort(
      (first, second) =>
          first.label.toLowerCase().compareTo(second.label.toLowerCase()),
    );

    return selectedFeatures;
  }

  Widget _buildCategoryChips(List<String>? categories, WidgetRef ref) {
    final normalizedCategories =
        (categories ?? const <String>[])
            .map((category) => category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort(
            (first, second) =>
                first.toLowerCase().compareTo(second.toLowerCase()),
          );

    if (normalizedCategories.isEmpty) {
      return const SizedBox(height: 20);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: normalizedCategories
          .map((category) {
            final categoryLabel = ref.watch(
              categoryLabelBySlugProvider(category),
            );

            return Chip(
              avatar: const Icon(Icons.check, size: 16),
              label: Text(categoryLabel ?? category),
            );
          })
          .toList(growable: false),
    );
  }
}
