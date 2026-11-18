import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/poi_drag_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:stadtschreiber/widgets/_editable_list.dart';

class PoiGeometryEditDialog extends ConsumerWidget {
  final PointOfInterest poi;

  const PoiGeometryEditDialog({super.key, required this.poi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPoi = ref.watch(selectedPoiProvider) ?? poi;

    final appState = ref.watch(appStateProvider);

    final locale = ref.watch(localeProvider);

    final languageCode = locale.languageCode;

    final countryCode = locale.countryCode;

    final location = selectedPoi.location;

    final points = selectedPoi.getPoints();

    final pointsList = points == null
        ? <String>[]
        : points
              .map(
                (point) =>
                    '${point.lat.toStringAsFixed(6)}, '
                    '${point.lon.toStringAsFixed(6)}',
              )
              .toList(growable: false);

    return AlertDialog(
      title: Text(
        getText(
          'editLocation',
          languageCode: languageCode,
          countryCode: countryCode,
        ),
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  labelText: getText(
                    'location',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  isDense: true,
                  contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                ),
                child: Text(
                  '${location.lat.toStringAsFixed(6)}, '
                  '${location.lon.toStringAsFixed(6)}',
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                icon: const Icon(Icons.location_on_outlined),
                label: Text(
                  getText(
                    'moveLocation',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();

                  ref
                      .read(dragPoiProvider.notifier)
                      .startDraggingPoiMode(selectedPoi);
                },
              ),

              const SizedBox(height: 16),

              SwitchListTile(
                tileColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  getText(
                    'editGeometryPoints',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                ),
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

              const SizedBox(height: 12),

              Text(
                getText(
                  'geometryType',
                  languageCode: languageCode,
                  countryCode: countryCode,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              RadioGroup<String>(
                groupValue: selectedPoi.geometryType,
                onChanged: (value) async {
                  if (value == null) {
                    return;
                  }

                  final updatedPoi = selectedPoi.copyWith(geometryType: value);

                  if (updatedPoi.isGeometryValid()) {
                    await ref
                        .read(poiRepositoryProvider)
                        .updatePoiGeomInSupabase(updatedPoi);
                  }

                  ref.read(appStateProvider.notifier).setPoiGeomEditMode(false);

                  ref.read(selectedPoiProvider.notifier).setPoi(updatedPoi);
                },
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        getText(
                          'point',
                          languageCode: languageCode,
                          countryCode: countryCode,
                        ),
                      ),
                      leading: const Radio<String>(
                        toggleable: true,
                        value: 'point',
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        getText(
                          'line',
                          languageCode: languageCode,
                          countryCode: countryCode,
                        ),
                      ),
                      leading: const Radio<String>(
                        toggleable: true,
                        value: 'linestring',
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        getText(
                          'polygone',
                          languageCode: languageCode,
                          countryCode: countryCode,
                        ),
                      ),
                      leading: const Radio<String>(
                        toggleable: true,
                        value: 'polygon',
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        getText(
                          'multipolygone',
                          languageCode: languageCode,
                          countryCode: countryCode,
                        ),
                      ),
                      leading: const Radio<String>(
                        toggleable: true,
                        value: 'multipolygon',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                getText(
                  'editGeometryPointsInstruction',
                  languageCode: languageCode,
                  countryCode: countryCode,
                ),
              ),

              const SizedBox(height: 12),

              if (pointsList.isEmpty)
                Text(
                  getText(
                    'noGeometryPoints',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                )
              else
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
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            getText(
              'close',
              languageCode: languageCode,
              countryCode: countryCode,
            ),
          ),
        ),
      ],
    );
  }
}
