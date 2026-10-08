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
      height: ref.read(appStateProvider).panelHeight - 45,
      child: Column(
        children: [
          PoiListHeader(
            onClose: () {
              ref.read(appStateProvider.notifier).setPoiListVisible(false);
            },
          ),
          SizedBox(height: 0),

          /*           Expanded(
            child: visiblePoisAsync.when(
              data: (visiblePois) {
                return ListView.builder(
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
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text("Fehler: $err"),
            ),
          ),
 */
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

class PoiListHeader extends ConsumerWidget {
  final VoidCallback onClose;

  const PoiListHeader({super.key, required this.onClose});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      child: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.visibility, color: Colors.black54, size: 32),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
