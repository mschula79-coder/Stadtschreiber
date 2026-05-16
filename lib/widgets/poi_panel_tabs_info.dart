import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/game_icons.dart';
import 'package:iconify_flutter/icons/maki.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:stadtschreiber/models/address.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/poi_drag_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:stadtschreiber/utils/dialog_utils.dart';
import 'package:stadtschreiber/utils/url_utils.dart';
import 'package:stadtschreiber/widgets/_editable_list.dart';
import 'package:stadtschreiber/widgets/category_node_tile.dart';
import 'package:stadtschreiber/widgets/modal_address_edit.dart';
import 'package:stadtschreiber/widgets/modal_bool_features_editor.dart';
import 'package:stadtschreiber/widgets/modal_string_features_editor.dart';

class PoiPanelInfoTab extends ConsumerWidget {
  const PoiPanelInfoTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DebugService.log('build PoiPanelInfoTab $this.key $this.hashcode');
    final selectedPoi = ref.watch(selectedPoiProvider);
    final isEditModeEnabled = ref.watch(appStateProvider).isPoiEditMode;
    if (selectedPoi == null) return SizedBox.shrink();
    final location = selectedPoi.location;
    final pts = selectedPoi.getPoints();
    final pointsList = pts == null
        ? <String>[]
        : pts
              .map(
                (p) =>
                    "${p.lat.toStringAsFixed(6)}, ${p.lon.toStringAsFixed(6)}",
              )
              .toList();

    final appState = ref.watch(appStateProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Edit Button
          Stack(
            children: [
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Name",
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
                            fieldName: "Name",
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
                decoration: const InputDecoration(
                  labelText: "Beschreibung",
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
                        fieldName: "Beschreibung",
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
                  labelText: "Adresse",
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
                  labelText: "Links",
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
                          dialogTitle: "Links bearbeiten",
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

          // Feature icons editable
          Stack(
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  labelText: "Features",
                  alignLabelWithHint: true,
                  contentPadding: isEditModeEnabled
                      ? const EdgeInsets.fromLTRB(0, 8, 35, 5)
                      : const EdgeInsets.fromLTRB(0, 8, 0, 5),
                ),
                child: Row(
                  children: [
                    SizedBox(height: 20, width: 0),
                    selectedPoi.metadata.notBBQAllowed()
                        ? Row(
                            children: [
                              Iconify(Mdi.fire_off, size: 24),
                              const SizedBox(width: 10),
                            ],
                          )
                        : const SizedBox.shrink(),
                    selectedPoi.metadata.isWheelchairAccessible()
                        ? Row(
                            children: [
                              Iconify(Mdi.wheelchair_accessibility, size: 24),
                              const SizedBox(width: 10),
                            ],
                          )
                        : const SizedBox.shrink(),
                    selectedPoi.metadata.hasBenches()
                        ? Row(
                            children: [
                              Iconify(GameIcons.park_bench, size: 24),
                              const SizedBox(width: 10),
                            ],
                          )
                        : const SizedBox.shrink(),
                    selectedPoi.metadata.hasPicnicTables()
                        ? Row(
                            children: [
                              Iconify(Maki.picnic_site, size: 24),
                              const SizedBox(width: 10),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              // Edit features
              if (isEditModeEnabled)
                Positioned(
                  right: 0,
                  top: 5,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final newFeatures = await showDialog<Map<String, bool>>(
                        context: context,
                        builder: (_) => BoolFeaturesEditorDialog(
                          dialogTitle: "Features bearbeiten",
                          initialFeatures: selectedPoi.metadata.getFeatures(),
                        ),
                      );
                      final newPoi = selectedPoi.copyWith();
                      newPoi.metadata.setFeatures(newFeatures!);
                      ref
                          .read(poiRepositoryProvider)
                          .updatePoiDataInSupabase(
                            id: selectedPoi.id,
                            metadata: newPoi.metadata,
                          );
                      ref.read(selectedPoiProvider.notifier).setPoi(newPoi);
                      //ref.invalidate(visiblePoisProvider);
                    },
                  ),
                ),
            ],
          ),

          // Kategorien bearbeiten
          if (isEditModeEnabled) ...[
            const SizedBox(height: 20),
            Text(
              'Kategorien bearbeiten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            // Kategorien Liste
            Consumer(
              builder: (context, ref, _) {
                final categories = ref.watch(categoriesProvider).categories;

                if (categories.isEmpty) {
                  return const Text("Keine Kategorien geladen");
                }

                return ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: categories
                      .map((root) => PoiCategoryNodeTile(node: root))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
          if (isEditModeEnabled) ...[
            // Standort und Geometrie
            Text(
              'Standort und Geometrie',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 15),
            Padding(
              padding: EdgeInsetsGeometry.only(right: 25),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Label Standort: Lat: ${location.lat} Lon: ${location.lon}',
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      ref
                          .read(dragPoiProvider.notifier)
                          .startDraggingPoiMode(selectedPoi);
                    },
                    child: Icon(Icons.edit),
                  ),
                ],
              ),
            ),
            // Geometriepunkte bearbeiten
            const SizedBox(height: 5),
            SwitchListTile(
              title: const Text('Geometriepunkte bearbeiten'),
              contentPadding: const EdgeInsets.only(left: 0, right: 0),
              value: appState.isPoiGeomEditMode,
              onChanged: (newValue) {
                ref
                    .read(appStateProvider.notifier)
                    .setPoiGeomEditMode(newValue);
                if (newValue) {
                  ref.read(dragPoiProvider.notifier).setDragPoi(selectedPoi);
                }
              },
            ),
            const SizedBox(height: 5),
            buildGeometryTypeSelector(context, selectedPoi, ref),
            const SizedBox(height: 5),

            const Text(
              'Punkte von 2D Geometrien (tippe lange auf die Karte, um weitere Punkte hinzuzufügen):',
            ),
            EditableList<String>(
              items: pointsList,
              isEditModeEnabled: true,
              itemBuilder: (entry) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 15),
                  child: Text(entry, style: const TextStyle(fontSize: 16)),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget buildGeometryTypeSelector(
    BuildContext context,
    PointOfInterest selectedPoi,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Geometrietyp", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),

        RadioGroup<String>(
          groupValue: selectedPoi.geometryType,
          onChanged: (value) {
            final newPoi = selectedPoi.copyWith(geometryType: value!);

            if (newPoi.isGeometryValid()) {
              final poiRepository = ref.read(poiRepositoryProvider);
              poiRepository.updatePoiGeomInSupabase(newPoi);
            }
            ref.read(appStateProvider.notifier).setPoiGeomEditMode(false);
            ref.read(selectedPoiProvider.notifier).setPoi(newPoi);
            //ref.invalidate(visiblePoisProvider);
          },
          child: Column(
            children: <Widget>[
              const ListTile(
                title: Text('Punkt'),
                leading: Radio<String>(toggleable: true, value: 'point'),
              ),
              const ListTile(
                title: Text('Linie'),
                leading: Radio<String>(toggleable: true, value: 'linestring'),
              ),
              const ListTile(
                title: Text('Polygon'),
                leading: Radio<String>(toggleable: true, value: 'polygon'),
              ),
              const ListTile(
                title: Text('MultiPolygon'),
                leading: Radio<String>(toggleable: true, value: 'multipolygon'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
