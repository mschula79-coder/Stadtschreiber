import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/provider/user_favorites_provider.dart';
import 'package:stadtschreiber/theme/app_layout.dart';
import 'package:stadtschreiber/widgets/modal_poi_favorite_edit.dart';
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
  double panelHeight = 460;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isEditor = ref.watch(supabaseUserStateProvider.notifier).isEditor();
    final favorites = ref.watch(userFavoritesProvider).value ?? [];

    final isFavorite = favorites.any((f) => f.poiID == widget.selectedPoi.id);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      height: panelHeight,
      width: AppLayout.poiListPanelWidth(context),
      child: Column(
        children: [
          Container(
            height: 5,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(top: 10, bottom: 0),
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          GestureDetector(
            behavior: HitTestBehavior.opaque,

            onVerticalDragUpdate: (details) {
              setState(() {
                panelHeight -= details.delta.dy;

                // Begrenzen
                panelHeight = panelHeight.clamp(200.0, 800.0);
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,

              children: [
                SizedBox(width: 18),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.selectedPoi.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 5),
                      isFavorite
                          ? IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(Icons.star, color: Colors.amber),
                              onPressed: () {
                                /*                               setState(() => panelHeight = 460);
 */
                                showDialog(
                                  context: context,
                                  builder: (_) => PoiFavoriteEditModal(
                                    poi: widget.selectedPoi,
                                  ),
                                );
                              },
                            )
                          : IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.star_border,
                                color: Colors.grey.shade400,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => PoiFavoriteEditModal(
                                    poi: widget.selectedPoi,
                                  ),
                                );
                              },
                            ),

                      SizedBox(width: 5),
                      isEditor
                          ? GestureDetector(
                              onTap: widget.onTogglePoiEditView,
                              child: !ref.read(appStateProvider).isPoiEditMode
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
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref.read(selectedPoiProvider.notifier).clear();
                    ref.read(appStateProvider.notifier).setPoiEditMode(false);
                    ref
                        .read(appStateProvider.notifier)
                        .setPoiGeomEditMode(false);
                  },
                ),
                SizedBox(width: 8),
              ],
            ),
          ),
          Expanded(child: PoiPanelTabs()),
        ],
      ),
    );
  }
}
