import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/poi_service_provider.dart';
import 'package:stadtschreiber/provider/search_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';

class AddressLookupQueueNotifier extends Notifier<List<PointOfInterest>> {
  bool _isProcessing = false;

  @override
  List<PointOfInterest> build() {
    return [];
  }

  // TODO poi displayaddress neu setzen
  void enqueue(PointOfInterest poi) {
    state = [...state, poi];
    _process();
  }

  void clear() {
    state = [];
  }

  Future<void> _process() async {
    if (_isProcessing) return;
    _isProcessing = true;

    final service = ref.read(poiServiceProvider);

    while (state.isNotEmpty) {
      final poi = state.first;
      state = state.sublist(1);

      final updated = await service.ensurePoiHasAddress(poi);

      final selected = ref.read(selectedPoiProvider);
      if (selected?.id == updated.id) {
        ref.read(selectedPoiProvider.notifier).setPoi(updated);
      }
ref.read(searchSelectionProvider.notifier).replace(updated);
    }

    _isProcessing = false;
  }
}

final addressLookupQueueProvider =
    NotifierProvider<AddressLookupQueueNotifier, List<PointOfInterest>>(
      AddressLookupQueueNotifier.new,
        name: 'addressLookupQueueProvider',
    );
