import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'poi_panel_tabs.dart';
import '../provider/selected_poi_provider.dart';

class PoiPanel extends ConsumerStatefulWidget {
  final PointOfInterest selectedPoi;
  final VoidCallback onTogglePoiEditView;

  const PoiPanel({
    required this.selectedPoi,
    required this.onTogglePoiEditView,
    super.key,
  });

  @override
  ConsumerState<PoiPanel> createState() => _PoiPanelState();
}

class _PoiPanelState extends ConsumerState<PoiPanel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isAdminViewEnabled = ref.watch(appStateProvider).isAdminViewEnabled;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      height: 460,
      child: Column(
        children: [
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(width: 18),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      widget.selectedPoi.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(width: 5),
                    isAdminViewEnabled
                        ? GestureDetector(
                            onTap: widget.onTogglePoiEditView,
                            child: !ref.read(appStateProvider).isPoiEditMode
                                // TODO Icon.polyline Icon.location => poiEdit
                                ? const Icon(
                                    Icons.edit,
                                    color: Color.fromARGB(255, 42, 23, 86),
                                  )
                                : const Icon(
                                    Icons.edit_off,
                                    color: Color.fromARGB(255, 42, 23, 86),
                                  ),
                          )
                        : SizedBox.shrink(),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(selectedPoiProvider.notifier).clear();
                  ref.read(appStateProvider.notifier).setPoiEditMode(false);
                  ref.read(appStateProvider.notifier).setPoiGeomEditMode(false);
                },
              ),
            ],
          ),
          Expanded(
            child: PoiPanelTabs(
            ),
          ),
        ],
      ),
    );
  }
}
