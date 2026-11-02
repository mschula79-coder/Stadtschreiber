import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:stadtschreiber/models/localized_feature_node.dart';

class FeatureFilterDialog extends StatefulWidget {
  final String dialogTitle;
  final String categoryLabel;
  final List<LocalizedFeatureNode> features;
  final Set<String> initiallySelectedSlugs;

  const FeatureFilterDialog({
    super.key,
    required this.dialogTitle,
    required this.categoryLabel,
    required this.features,
    required this.initiallySelectedSlugs,
  });

  @override
  State<FeatureFilterDialog> createState() {
    return _FeatureFilterDialogState();
  }
}

class _FeatureFilterDialogState extends State<FeatureFilterDialog> {
  late Set<String> _selectedFeatureSlugs;

  @override
  void initState() {
    super.initState();

    _selectedFeatureSlugs = Set<String>.from(widget.initiallySelectedSlugs);
  }

  @override
  Widget build(BuildContext context) {
    final sortedFeatures = List<LocalizedFeatureNode>.from(widget.features)
      ..sort(_compareFeatureNodes);

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
                    listTileTheme: const ListTileThemeData(
                      horizontalTitleGap: 4,
                      minLeadingWidth: 24,
                    ),
                  ),
                  child: sortedFeatures.isEmpty
                      ? const Center(
                          child: Text(
                            'Für diese Kategorie sind keine Features verfügbar.',
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            _buildCategorySection(
                              widget.categoryLabel,
                              sortedFeatures,
                            ),
                          ],
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
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Filter löschen'),
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
                      icon: const Icon(Icons.check),
                      label: const Text('Übernehmen'),
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

  Widget _buildCategorySection(
    String categoryLabel,
    List<LocalizedFeatureNode> roots,
  ) {
    final normalizedCategoryLabel = categoryLabel.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (normalizedCategoryLabel.isNotEmpty)
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
                      normalizedCategoryLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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

  Widget _buildNode(LocalizedFeatureNode node, {required int depth}) {
    final leftPadding = depth * 10.0;

    if (node.children.isNotEmpty) {
      final sortedChildren = List<LocalizedFeatureNode>.from(node.children)
        ..sort(_compareFeatureNodes);

      return ExpansionTile(
        key: PageStorageKey<String>('feature-filter-${node.id}'),
        controlAffinity: ListTileControlAffinity.leading,
        shape: const Border(),
        collapsedShape: const Border(),
        maintainState: true,
        visualDensity: VisualDensity.compact,
        tilePadding: EdgeInsets.only(left: leftPadding + 24, right: 12),
        childrenPadding: EdgeInsets.zero,
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            node.label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        subtitle: _buildDefinition(node.definition),
        children: sortedChildren
            .map((child) => _buildNode(child, depth: depth + 1))
            .toList(growable: false),
      );
    }

    return CheckboxListTile(
      value: _selectedFeatureSlugs.contains(node.slug),
      controlAffinity: ListTileControlAffinity.leading,
      checkboxScaleFactor: 0.7,

      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.only(left: leftPadding + 16, right: 12),
      title: Padding(
        padding: const EdgeInsets.only(left: 1),
        child: Text(node.label),
      ),
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

  int _compareFeatureNodes(
    LocalizedFeatureNode first,
    LocalizedFeatureNode second,
  ) {
    final labelComparison = _normalizeSortLabel(
      first.label,
    ).compareTo(_normalizeSortLabel(second.label));

    if (labelComparison != 0) {
      return labelComparison;
    }

    return first.slug.compareTo(second.slug);
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
        .replaceAll('ã', 'a')
        .replaceAll('å', 'a')
        .replaceAll('æ', 'ae')
        .replaceAll('ç', 'c')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('í', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ñ', 'n')
        .replaceAll('ò', 'o')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('œ', 'oe')
        .replaceAll('ù', 'u')
        .replaceAll('ú', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ÿ', 'y');
  }
}
