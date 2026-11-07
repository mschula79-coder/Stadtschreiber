import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

class PoiListActionRow extends StatelessWidget {
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;
  final Future<void> Function()? onFilter;
  final Future<void> Function()? onDelete;
  final bool isFilterActive;
  final bool isDeleting;
  final bool showSelectAll;
  final bool showClearSelection;
  final bool showFilter;
  final bool showDelete;
  final String selectAllTooltip;
  final String clearSelectionTooltip;
  final String filterTooltip;
  final String deleteTooltip;

  const PoiListActionRow({
    super.key,
    this.onSelectAll,
    this.onClearSelection,
    this.onFilter,
    this.onDelete,
    this.isFilterActive = false,
    this.isDeleting = false,
    this.showSelectAll = true,
    this.showClearSelection = true,
    this.showFilter = true,
    this.showDelete = false,
    this.selectAllTooltip = 'Sichtbare POIs auswählen',
    this.clearSelectionTooltip = 'Auswahl aufheben',
    this.filterTooltip = 'Nach Kategorien filtern',
    this.deleteTooltip = 'Liste löschen',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showSelectAll)
            IconButton(
              tooltip: selectAllTooltip,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: const Iconify(
                Mdi.check_all,
                color: Colors.black87,
                size: 24,
              ),
              onPressed: isDeleting ? null : onSelectAll,
            ),
          if (showClearSelection)
            IconButton(
              tooltip: clearSelectionTooltip,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: const Iconify(
                Mdi.checkbox_blank_off_outline,
                color: Colors.black87,
                size: 18,
              ),
              onPressed: isDeleting ? null : onClearSelection,
            ),
          if (showFilter)
            IconButton(
              tooltip: filterTooltip,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                isFilterActive ? Icons.filter_alt : Icons.filter_alt_outlined,
                color: Colors.black87,
                size: 24,
              ),
              onPressed: isDeleting || onFilter == null
                  ? null
                  : () async {
                      await onFilter!();
                    },
            ),
          if (showDelete)
            isDeleting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: deleteTooltip,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: const Iconify(
                      Mdi.trash_can_outline,
                      color: Colors.black87,
                      size: 24,
                    ),
                    onPressed: onDelete == null
                        ? null
                        : () async {
                            await onDelete!();
                          },
                  ),
        ],
      ),
    );
  }
}
