import 'package:flutter_riverpod/flutter_riverpod.dart';

final featureFilterProvider =
    NotifierProvider<FeatureFilterNotifier, List<String>>(
      FeatureFilterNotifier.new,
    );

class FeatureFilterNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return <String>[];
  }

  void replaceAll(Iterable<String> featureSlugs) {
    state = List<String>.unmodifiable(featureSlugs);
  }

  void setSelected(String featureSlug, bool selected) {
    final normalizedSlug = featureSlug.trim();

    if (normalizedSlug.isEmpty) {
      return;
    }

    final next = List<String>.from(state);

    if (selected) {
      next.add(normalizedSlug);
    } else {
      next.remove(normalizedSlug);
    }

    state = List<String>.unmodifiable(next);
  }

  void clear() {
    state = <String>[];
  }
}
