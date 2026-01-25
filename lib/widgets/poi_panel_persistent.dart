import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'map_popup_tabs.dart';
import '../controllers/poi_controller.dart';
import '../state/poi_state.dart';

class PersistentPoiPanel extends StatelessWidget {
  final bool isAdmin;

  const PersistentPoiPanel({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PoiState>();
    final poi = state.selected;
    final isOpen = state.isPanelOpen;

    if (!isOpen || poi == null) {
      return const SizedBox.shrink();
    }
  
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      height: 350,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  poi.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  context.read<PoiState>().closePanel();
                  context.read<PoiController>().clearSelection();
                },
              ),
            ],
          ),
          Expanded(child: MapPopupTabs(isAdmin: isAdmin)),
        ],
      ),
    );
  }
}
