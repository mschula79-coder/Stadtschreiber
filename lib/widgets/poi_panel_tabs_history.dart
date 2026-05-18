import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/history_entry.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:stadtschreiber/widgets/_editable_list.dart';
import 'package:stadtschreiber/widgets/modal_history_edit.dart';

class PoiPanelHistoryTab extends ConsumerWidget {
  const PoiPanelHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DebugService.log('build PoiPanelInfoTab $this.key $this.hashcode');
    final selectedPoi = ref.watch(selectedPoiProvider);
    final isEditModeEnabled = ref.watch(appStateProvider).isPoiEditMode;
    if (selectedPoi == null) return SizedBox.shrink();

    final historyEntries = selectedPoi.historyEntries;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 8),
                EditableList<HistoryEntry>(
                  items: historyEntries,
                  isEditModeEnabled: isEditModeEnabled,
                  onAdd: () async {
                    final newEntry = await showDialog<HistoryEntry>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const HistoryEditModal(
                        initialStart: "",
                        initialEnd: "",
                        initialDescription: "",
                      ),
                    );

                    if (newEntry != null) {
                      final updated = [...historyEntries, newEntry];
                      ref
                          .read(poiRepositoryProvider)
                          .updatePoiDataInSupabase(
                            id: selectedPoi.id,
                            historyEntries: updated,
                          );
                      ref
                          .read(selectedPoiProvider.notifier)
                          .setPoi(
                            selectedPoi.copyWith(historyEntries: updated),
                          );
                      //ref.invalidate(visiblePoisProvider);
                    }

                    return newEntry;
                  },
                  onEdit: (entry) async {
                    final updatedEntry = await showDialog<HistoryEntry>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => HistoryEditModal(
                        initialStart: entry.rawStart,
                        initialEnd: entry.rawEnd,
                        initialDescription: entry.description,
                      ),
                    );

                    if (updatedEntry != null) {
                      final updated = [...historyEntries];
                      final index = updated.indexOf(entry);
                      updated[index] = updatedEntry;

                      ref
                          .read(poiRepositoryProvider)
                          .updatePoiDataInSupabase(
                            id: selectedPoi.id,
                            historyEntries: updated,
                          );
                      ref
                          .read(selectedPoiProvider.notifier)
                          .setPoi(
                            selectedPoi.copyWith(historyEntries: updated),
                          );
                      //ref.invalidate(visiblePoisProvider);
                    }

                    return updatedEntry;
                  },
                  onDelete: (entry) async {
                    final updated = [...historyEntries]..remove(entry);
                    ref
                        .read(poiRepositoryProvider)
                        .updatePoiDataInSupabase(
                          id: selectedPoi.id,
                          historyEntries: updated,
                        );
                    ref
                        .read(selectedPoiProvider.notifier)
                        .setPoi(selectedPoi.copyWith(historyEntries: updated));
                  },
                  itemBuilder: (entry) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: entry.getLabel(),
                          alignLabelWithHint: true,
                          contentPadding: EdgeInsets.fromLTRB(0, 0, 20, 10),
                          border:
                              UnderlineInputBorder(), // oder OutlineInputBorder()
                        ),
                        child: Text(
                          entry.description,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
