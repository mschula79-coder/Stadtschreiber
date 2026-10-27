import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
// ignore: unused_import
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
/* import 'package:stadtschreiber/provider/locale_provider.dart';
 */
import 'package:stadtschreiber/provider/poi_selection_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_provider.dart';
import 'package:stadtschreiber/theme/app_layout.dart';
import 'package:stadtschreiber/widgets/modal_poi_categories_edit.dart';
/* import 'package:stadtschreiber/utils/language_utils.dart';
 */
import 'package:stadtschreiber/widgets/poi_list_item.dart';

class PoiListPanel extends ConsumerStatefulWidget {
  const PoiListPanel({super.key});

  @override
  ConsumerState<PoiListPanel> createState() => _PoiListState();
}

class _PoiListState extends ConsumerState<PoiListPanel> {
  double panelHeight = 460;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /*     final width = MediaQuery.of(context).size.width; */
    /*     final horizontalPadding = width < 600 ? 24.0 : width * 0.3;*/
    /*     final visiblePoisAsync = ref.watch(visiblePoisProvider);
 */

    final isAdmin = ref.watch(supabaseUserStateProvider).isAdmin;

    final visiblePois = ref.watch(sortedVisiblePoisProvider);
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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) {
                setState(() {
                  panelHeight -= details.delta.dy;
                  panelHeight = panelHeight.clamp(200.0, 800.0);
                });
              },
              child: SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Icon(
                        Icons.visibility,
                        color: Colors.black54,
                        size: 32,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsGeometry.only(bottom: 20),

                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          ref
                              .read(appStateProvider.notifier)
                              .setPoiListVisible(false);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              primary: false,
              itemCount: visiblePois.length,
              itemBuilder: (context, index) {
                return PoiListItem(
                  selectEnabled: true,
                  imageWidth: 140,
                  imageHeight: 105,
                  paddingLeft: 16,
                  poi: visiblePois[index],
                  onTap: () {
                    ref
                        .read(selectedPoiProvider.notifier)
                        .setPoi(visiblePois[index]);
                  },
                );
              },
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,

            children: [
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: Iconify(
                  Mdi.checkbox_multiple_marked_outline,
                  color: Colors.black87,
                  size: 24,
                ),
                onPressed: () {
                  ref.read(poiSelectionProvider.notifier).setAll(visiblePois);
                },
              ),
              SizedBox(width: 5),

              // Alle de-markieren
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: const Iconify(
                  Mdi.checkbox_multiple_blank_outline,
                  color: Colors.black87,
                  size: 24,
                ),
                onPressed: () {
                  ref.read(poiSelectionProvider.notifier).clear();
                },
              ),
              SizedBox(width: 5),
              isAdmin
                  ? Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          icon: const Iconify(
                            Mdi.shape_plus,
                            color: Colors.black87,
                            size: 24,
                          ),
                          onPressed: () async {
                            final selectedPois = ref.read(poiSelectionProvider);

                            if (selectedPois.isEmpty) {
                              return;
                            }

                            await showPoiCategoriesEditModal(
                              context,
                              pois: selectedPois,
                            );
                          },
                        ),
                        SizedBox(width: 5),
                      ],
                    )
                  : SizedBox.shrink(),
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: const Iconify(
                  Mdi.playlist_add,
                  color: Colors.black87,
                  size: 24,
                ),
                onPressed: () {
                  // TODO List add
                },
              ),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
