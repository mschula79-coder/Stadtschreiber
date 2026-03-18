
import '../models/poi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/poi_repository.dart';
import '../state/camera_state.dart';

final searchResultsProvider = FutureProvider.autoDispose
    .family<
      List<PointOfInterest>,
      ({
        String query,
        bool searchActive,
        PoiRepository repo,
        CameraState camera,
      })
    >((ref, params) async {
      if (!params.searchActive) {
        return [];
      }

      final pois = await params.repo.searchPois(
        params.query.trimRight(),
        params.camera.lat,
        params.camera.lon,
      );
      
      return pois;
    });
