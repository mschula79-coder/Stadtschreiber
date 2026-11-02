import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:stadtschreiber/models/poi_feature_node.dart';

class PoiFeaturesEditDialog extends StatefulWidget {
  final String dialogTitle;
  final List<PoiFeatureNode> featureTree;

  const PoiFeaturesEditDialog({
    super.key,
    required this.dialogTitle,
    required this.featureTree,
  });

  @override
  State<PoiFeaturesEditDialog> createState() {
    return _PoiFeaturesEditDialogState();
  }
}

class _PoiFeaturesEditDialogState extends State<PoiFeaturesEditDialog> {
  late Set<String> _selectedFeatureSlugs;

  @override
  void initState() {
    super.initState();

    _selectedFeatureSlugs = <String>{};

    _collectSelectedLeaves(widget.featureTree);
  }

  void _collectSelectedLeaves(List<PoiFeatureNode> nodes) {
    for (final node in nodes) {
      if (node.isLeaf) {
        if (node.isSelected) {
          _selectedFeatureSlugs.add(node.slug);
        }
      } else {
        _collectSelectedLeaves(node.children);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedRoots = _groupRootsByCategory(widget.featureTree);

    return PointerInterceptor(
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                child: Row(
                  children: [
                    const Icon(Icons.tune),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.dialogTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    dividerTheme: const DividerThemeData(
                      color: Colors.transparent,
                      space: 0,
                      thickness: 0,
                    ),
                  ),
                  child: groupedRoots.isEmpty
                      ? const Center(
                          child: Text(
                            'Für diesen POI sind keine Features verfügbar.',
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: groupedRoots.entries
                              .map(
                                (entry) => _buildCategorySection(
                                  entry.key,
                                  entry.value,
                                ),
                              )
                              .toList(growable: false),
                        ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _selectedFeatureSlugs.isEmpty
                          ? null
                          : () {
                              setState(() {
                                _selectedFeatureSlugs.clear();
                              });
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Alle entfernen'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Abbrechen'),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(Set<String>.unmodifiable(_selectedFeatureSlugs));
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Speichern'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<PoiFeatureNode>> _groupRootsByCategory(
    List<PoiFeatureNode> roots,
  ) {
    final grouped = <String, List<PoiFeatureNode>>{};

    for (final root in roots) {
      final categoryLabel = root.sourceCategoryLabel.trim().isEmpty
          ? root.sourceCategorySlug
          : root.sourceCategoryLabel;

      grouped.putIfAbsent(categoryLabel, () => <PoiFeatureNode>[]).add(root);
    }

    final sortedCategoryLabels = grouped.keys.toList()
      ..sort(
        (first, second) =>
            _normalizeSortLabel(first).compareTo(_normalizeSortLabel(second)),
      );

    return <String, List<PoiFeatureNode>>{
      for (final categoryLabel in sortedCategoryLabels)
        categoryLabel: grouped[categoryLabel]!,
    };
  }

  Widget _buildCategorySection(
    String categoryLabel,
    List<PoiFeatureNode> roots,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...roots.map((node) => _buildNode(node, depth: 0)),
        ],
      ),
    );
  }

  Widget _buildNode(PoiFeatureNode node, {required int depth}) {
    final leftPadding = depth * 10.0;

    if (node.children.isNotEmpty) {
      return ExpansionTile(
        controlAffinity: ListTileControlAffinity.leading,
        key: PageStorageKey<String>(
          'poi-feature-${node.sourceCategorySlug}-${node.rootFeatureSlug}-${node.id}',
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        maintainState: true,
        visualDensity: VisualDensity.compact,
        tilePadding: EdgeInsets.only(left: leftPadding + 16, right: 12),
        childrenPadding: EdgeInsets.zero,
        title: Padding(
          padding: const EdgeInsets.only(left: 7),
          child: Text(
            node.label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        subtitle: _buildDefinition(node.definition),
        children: node.children
            .map((child) => _buildNode(child, depth: depth + 1))
            .toList(growable: false),
      );
    }

    return CheckboxListTile(
      value: _selectedFeatureSlugs.contains(node.slug),
      controlAffinity: ListTileControlAffinity.leading,
      checkboxScaleFactor: 0.7,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.only(left: leftPadding + 8, right: 12),
      title: Text(node.label),
      subtitle: _buildDefinition(node.definition),
      onChanged: (selected) {
        setState(() {
          if (selected ?? false) {
            _selectedFeatureSlugs.add(node.slug);
          } else {
            _selectedFeatureSlugs.remove(node.slug);
          }
        });
      },
    );
  }

  Widget? _buildDefinition(String? definition) {
    final text = definition?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return Text(text, style: const TextStyle(fontSize: 12));
  }

  String _normalizeSortLabel(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u');
  }
}
