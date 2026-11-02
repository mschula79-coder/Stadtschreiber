import 'package:stadtschreiber/models/localized_feature_node.dart';

class FeatureTreeUtils {
  const FeatureTreeUtils._();

  static List<LocalizedFeatureNode> buildTree(
    List<LocalizedFeatureNode> features,
  ) {
    final nodesBySlug =
        <String, LocalizedFeatureNode>{};

    for (final feature in features) {
      nodesBySlug[feature.slug] = feature;
    }

    final childrenByParent =
        <String, List<LocalizedFeatureNode>>{};

    final rootFeatures =
        <LocalizedFeatureNode>[];

    for (final feature in features) {
      final parentSlug = feature.parentSlug;

      if (parentSlug == null ||
          parentSlug.trim().isEmpty ||
          !nodesBySlug.containsKey(parentSlug)) {
        rootFeatures.add(feature);
        continue;
      }

      childrenByParent
          .putIfAbsent(
            parentSlug,
            () => <LocalizedFeatureNode>[],
          )
          .add(feature);
    }

    LocalizedFeatureNode buildNode(
      LocalizedFeatureNode node,
    ) {
      final children = List<LocalizedFeatureNode>.from(
        childrenByParent[node.slug] ??
            const <LocalizedFeatureNode>[],
      );

      children.sort(_compareNodes);

      return node.copyWith(
        children: children
            .map(buildNode)
            .toList(growable: false),
      );
    }

    rootFeatures.sort(_compareNodes);

    return rootFeatures
        .map(buildNode)
        .toList(growable: false);
  }

  static int _compareNodes(
    LocalizedFeatureNode left,
    LocalizedFeatureNode right,
  ) {
    final sortOrderComparison = left.sortOrder.compareTo(
      right.sortOrder,
    );

    if (sortOrderComparison != 0) {
      return sortOrderComparison;
    }

    return left.label.toLowerCase().compareTo(
      right.label.toLowerCase(),
    );
  }
}