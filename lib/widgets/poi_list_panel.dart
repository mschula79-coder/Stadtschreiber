import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: unused_import
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_provider.dart';
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
    final visiblePois = ref.watch(sortedVisiblePoisProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      height: panelHeight,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16, top:10),
                    child: const Icon(
                      Icons.visibility,
                      color: Colors.black54,
                      size: 32,
                    ),
                  ),
                  Container(
                    height: 5,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 10, bottom: 30),
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.only(top: 15),
                    constraints: const BoxConstraints(),

                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref
                          .read(appStateProvider.notifier)
                          .setPoiListVisible(false);
                    },
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: visiblePois.length,
              itemBuilder: (context, index) {
                return PoiListItem(
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
        ],
      ),
    );
  }
}
