import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:stadtschreiber/provider/poi_drag_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:stadtschreiber/widgets/poi_panel_tabs_articles.dart';
import 'package:stadtschreiber/widgets/poi_panel_tabs_gallery.dart';
import 'package:stadtschreiber/widgets/poi_panel_tabs_history.dart';
import 'package:stadtschreiber/widgets/poi_panel_tabs_info.dart';
import 'package:stadtschreiber/widgets/poi_panel_tabs_ratings.dart';
import '../models/poi.dart';

class PoiPanelTabs extends ConsumerStatefulWidget {
  const PoiPanelTabs({super.key});

  @override
  ConsumerState<PoiPanelTabs> createState() => _PoiPanelTabsState();
}

class _PoiPanelTabsState extends ConsumerState<PoiPanelTabs> {
  /*   bool _listenerRegistered = false;
 */
  late final ProviderSubscription<PointOfInterest?> _sub;
  late final PoiDragNotifier dragPoiNotifier;

  @override
  void initState() {
    super.initState();
    dragPoiNotifier = ref.read(dragPoiProvider.notifier);
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
    DebugService.log('Dispose PoiPanelTabs');
  }

  @override
  Widget build(BuildContext context) {
    DebugService.log('Build PoiPanelTabs');
    final selectedPoi = ref.watch(selectedPoiProvider);
    if (selectedPoi == null) return const SizedBox.shrink();

    /* 
    if (!_listenerRegistered) {
      _listenerRegistered = true;

      // 1. Listener registrieren
      _sub = ref.listenManual<PointOfInterest?>(selectedPoiProvider, (
        prev,
        next,
      ) {
        
      });

      // 2. Initialen Wert manuell setzen
      final current = ref.read(selectedPoiProvider);
      if (current != null) {
        nameController.text = current.name;
        featuredImageUrlController.text = current.featuredImageUrl ?? '';
        descriptionController.text = current.description ?? '';
        DebugService.log(
          'Initial values set in PoiPanelTabs Name: ${current.name}',
        );
      }
    } */

    final tabs = [
      const Tab(
        icon: Tooltip(message: "Info", child: Icon(Icons.info_outline)),
      ),
      const Tab(
        icon: Tooltip(
          message: "Photo Gallery",
          child: Iconify(
            Mdi.image_multiple_outline,
            size: 24,
            color: Colors.black,
          ),
        ),
      ),
      const Tab(
        icon: Tooltip(message: "Ratings", child: Icon(Icons.star)),
      ),

      const Tab(
        icon: Tooltip(
          message: "History",
          child: Iconify(Mdi.historic, size: 24),
        ),
      ),
      const Tab(
        icon: Tooltip(
          message: "Stories and articles",
          child: Iconify(Mdi.book_open_blank_variant, size: 24),
        ),
      ),
    ];

    final pages = [
      PoiPanelInfoTab(),
      PoiPanelGalleryTab(),
      PoiPanelRatingsTab(),
      PoiPanelHistoryTab(),
      PoiPanelArticlesTab(),
    ];
    int initialIndex;
    if (selectedPoi.images.isEmpty) {
      initialIndex = 0;
    } else {
      initialIndex = 1;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        DebugService.log("PoiPanelTabs constraints: $constraints");

        return DefaultTabController(
          length: tabs.length,
          initialIndex: initialIndex,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabs: tabs,
                tabAlignment: TabAlignment.start,
              ),
              Expanded(child: TabBarView(children: pages)),
            ],
          ),
        );
      },
    );
  }
}
