// ignore_for_file: unused_local_variable

import 'dart:io';
import 'package:geo_osm_pbf/geo_osm_pbf.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/repositories/poi_repository.dart';
import 'package:stadtschreiber/services/poi_service.dart';

class OsmPbfPoiImportService {
  final parser = OsmPbfParser();

  // ⭐ NodeCache enthält GeoNode (ohne Tags)
  final Map<int, GeoNode> nodeCache = {};

  late final PoiService poiService = PoiService(PoiRepository());

  // ⭐ Nur einen POI je Typ importieren
  bool importedNode = false;
  bool importedRelation = false;

  // ⭐ Fortschritt
  int processed = 0;
  int total = 0;

  void updateProgress(Function(String) onStatus) {
    onStatus("$processed von $total§ Objekten verarbeitet");
  }

  bool isPoi(Map<String, String>? tags) {
    if (tags == null || tags.isEmpty) return false;

    // ⭐ Kein POI ohne Namen
    final name = tags['name'];
    if (name == null || name.trim().isEmpty) return false;

    final amenity = tags['amenity'];
    final building = tags['building'];
    final tourism = '[tourism]';
    final historic = '[historic]';
    final leisure = '[leisure]';

    // Nur Restaurants, Cafés und öffentliche Gebäude
    /*     return 
    amenity == 'restaurant' 
    || amenity == 'cafe' 
    || building == 'public'
    || historic.isNotEmpty;
    ||
    ||
    ||;

 */
    return building == 'government';

    /* 
erledigt 21.09.2026:leisure
    return building == 'fountain';

 */
  }

  Geographic? calculateRelationCenter(List<int> refs) {
    double sumLat = 0;
    double sumLon = 0;
    int count = 0;

    for (final ref in refs) {
      final node = nodeCache[ref];
      if (node != null) {
        sumLat += node.coordinate.lat;
        sumLon += node.coordinate.lon;
        count++;
      }
    }

    if (count == 0) return null;

    return Geographic(lat: sumLat / count, lon: sumLon / count);
  }

  Future<String> runImport({
    required Function(String) onStatus,
    required String filePath,
  }) async {
    final file = File(filePath);
    total = await countPoiCandidates(filePath);
    
    await parser.parse(
      file.path,

      readNodes: true,
      readWays: true, // ⭐ bleibt aktiv, aber wir ignorieren Ways
      readRelations: true,

      // ⭐ GeoNode → KEINE Tags
      onNode: (GeoNode node) {
        nodeCache[node.id] = node;

        processed++;
        updateProgress(onStatus);
      },

      // ⭐ GeoTaggedNode → POI Nodes!
      onTaggedNode: (GeoTaggedNode node) async {
        processed++;
        updateProgress(onStatus);

        /*         if (importedNode) return; // ⭐ nur 1 Node importieren
 */
        if (!isPoi(node.tags)) return;

        importedNode = true;

        final json = {
          'id': node.id,
          'lat': node.coordinate.lat,
          'lon': node.coordinate.lon,
          'tags': node.tags,
        };

        final poi = PointOfInterest.fromOSM(json);
        final fresh = await poiService.checkForDuplicates(poi);

        onStatus("Node POI (TEST): ${fresh.osmId}");
      },

      // ⭐ Ways komplett ausklammern
      onWay: (GeoWay way) {
        processed++;
        updateProgress(onStatus);

        // ⭐ KEINE POIs ohne Position → Ways ignorieren
        return;
      },

      // ⭐ GeoRelation → hat tags + members → Node-Refs
      onRelation: (GeoRelation rel) async {
        processed++;
        updateProgress(onStatus);

        /*         if (importedRelation) return; // ⭐ nur 1 Relation importieren
 */
        if (!isPoi(rel.tags)) return;

        importedRelation = true;

        final refs = rel.members.map((m) => m.ref).toList();
        final center = calculateRelationCenter(refs);

        final json = {
          'id': rel.id,
          'center': center == null
              ? {'lat': 0, 'lon': 0}
              : {'lat': center.lat, 'lon': center.lon},
          'tags': rel.tags,
        };

        final poi = PointOfInterest.fromOSM(json);
        final fresh = await poiService.checkForDuplicates(poi);

        onStatus("Relation POI (TEST): ${fresh.osmId}");
      },
    );

    return "OSM POI Import abgeschlossen (TESTMODE)";
  }

  Future<int> countPoiCandidates(String filePath) async {
    int count = 0;

    await parser.parse(
      filePath,
      readNodes: false,
      readWays: false,
      readRelations: true,

      onTaggedNode: (node) {
        if (isPoi(node.tags)) count++;
      },

      onRelation: (rel) {
        if (isPoi(rel.tags)) count++;
      },
    );

    return count;
  }
}
