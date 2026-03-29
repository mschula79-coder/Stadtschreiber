import 'package:flutter/material.dart';
import '../models/poi.dart';

class SearchResultsList extends StatelessWidget {
  final List<PointOfInterest> results;
  final void Function(PointOfInterest poi) onSelect;
  final VoidCallback onShowAll;

  const SearchResultsList({
    super.key,
    required this.results,
    required this.onSelect,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 215,
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6),
        ],
      ),

      // Maximalhöhe, danach scrollt die Liste
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 300, // ca. 5–6 Einträge
        ),

        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: results.length + 1, // +1 für den Button
          itemBuilder: (context, index) {
            // Button am Ende
            if (index == results.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Center(
                  child: ElevatedButton(
                    onPressed: onShowAll,
                    child: const Text("Show all results on map"),
                  ),
                ),
              );
            }

            final poi = results[index];

            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(
                poi.name,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: poi.displayAddress != null
                  ? Text(
                      '${poi.city ?? ''}, ${poi.street ?? ''} ${poi.houseNumber ?? ''}',
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
              onTap: () => onSelect(poi),
            );
          },
        ),
      ),
    );
  }
}
