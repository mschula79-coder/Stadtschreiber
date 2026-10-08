/* import 'package:flutter/material.dart';
import 'package:stadtschreiber/services/map_controller.dart';
import 'package:stadtschreiber/widgets/visible_pois_menu.dart';
import 'package:stadtschreiber/widgets/wep_maplibre.dart';

class StadtschreiberWebApp extends StatefulWidget {
  const StadtschreiberWebApp({super.key});

  @override
  State<StadtschreiberWebApp> createState() => _StadtschreiberWebAppState();
}

class _StadtschreiberWebAppState extends State<StadtschreiberWebApp> {
  StadtschreiberMapController? mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // linke Spalte: Menü / POI-Liste
          SizedBox(
            width: 400,
            child: VisiblePoisMenu(
              onClose: () {},
            ),
          ),

          // rechte Spalte: MapLibre Web
          Expanded(
            child: WebMapLibreWidget(
              onMapReady: (controller) {
                mapController = controller;
              },
            ),
          ),
        ],
      ),
    );
  }
}
 */