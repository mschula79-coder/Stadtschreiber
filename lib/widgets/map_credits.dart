import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapCredits extends StatelessWidget {
  const MapCredits({super.key});

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 25,
      left: 15,
      child: GestureDetector(
        onTap: () {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final Offset iconPos = box.localToGlobal(Offset.zero);
          final Size iconSize = box.size;
          final Size screen = MediaQuery.of(context).size;

          showDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (context) {
              return Stack(
                children: [
                  Positioned(
                    // rechts neben dem Icon
                    left: iconPos.dx + iconSize.width,

                    // untere linke Ecke sitzt oberhalb des Icons
                    bottom: (screen.height - iconPos.dy) + iconSize.height - 30,

                    child: Material(
                      color: Colors.white,
                      elevation: 6,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        width: 180,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                "Credits",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),

                            // alphabetisch sortiert
                            _creditItem("DuckServer", "https://duckdns.org"),
                            _creditItem("Iconify", "https://iconify.design"),
                            _creditItem("© MapLibre", "https://maplibre.org"),
                            _creditItem("Maputnik", "https://maputnik.github.io"),
                            _creditItem("Nominatim", "https://nominatim.org"),
                            _creditItem("© OpenStreetMap", "https://www.openstreetmap.org"),
                            _creditItem("Overpass API", "https://overpass-api.de"),
                            _creditItem("Planetiler", "https://github.com/onthegomap/planetiler"),
                            _creditItem("Supabase", "https://supabase.com"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF000000).withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.info_outline,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _creditItem(String name, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          InkWell(
            onTap: () => _openUrl(url),
            child: const Icon(
              Icons.open_in_new,
              size: 18,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
