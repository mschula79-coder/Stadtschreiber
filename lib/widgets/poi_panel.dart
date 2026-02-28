import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'poi_panel_tabs.dart';
import '../provider/selected_poi_provider.dart';
import '../state/poi_panel_state.dart';

class PoiPanel extends ConsumerStatefulWidget {

  const PoiPanel({
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
    final selPoi = ref.read(selectedPoiProvider);
    final isOpen = context.watch<PoiPanelState>().isPanelOpen;

    if (!isOpen || selPoi == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      height: 460,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  selPoi.name,
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
                  context.read<PoiPanelState>().closePanel();
                  ref.read(selectedPoiProvider.notifier).clear();
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
