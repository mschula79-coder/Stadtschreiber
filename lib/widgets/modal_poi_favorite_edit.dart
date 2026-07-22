import 'package:flutter/material.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/provider/user_favorite_lists_provider.dart';
import 'package:stadtschreiber/provider/user_favorites_provider.dart';
import 'package:stadtschreiber/widgets/modal_name_edit.dart';

class PoiFavoriteEditModal extends ConsumerStatefulWidget {
  final PointOfInterest poi;
  const PoiFavoriteEditModal({super.key, required this.poi});

  @override
  ConsumerState<PoiFavoriteEditModal> createState() =>
      _PoiFavoriteEditModalState();
}

class _PoiFavoriteEditModalState extends ConsumerState<PoiFavoriteEditModal> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userID = ref.watch(supabaseUserStateProvider).userid;

    return Consumer(
      builder: (context, ref, _) {
        return AlertDialog(
          title: const Text("Favorit bearbeiten"),
          contentPadding: EdgeInsets.fromLTRB(12, 12, 0, 0),
          actionsPadding: EdgeInsets.fromLTRB(24, 0, 0, 8),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FavoriteListSelectionList(selectedPoiId: widget.poi.id),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.fromLTRB(24, 0, 0, 20),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize
                        .shrinkWrap, // ⭐ kompakter Touch‑Bereich
                  ),
                  child: const Text("+ neue Liste"),
                  onPressed: () async {
                    final listname = await showDialog<String>(
                      context: context,
                      builder: (_) => const NameEditModal(initialName: ''),
                    );

                    if (listname == null || listname.isEmpty) return;

                    ref.read(editFavoriteListsListProvider)(
                      add: true,
                      listId: '',
                      listname: listname,
                      userID: userID,
                    );
                    ref.invalidate(userFavoriteListsProvider(userID));
                    ref.invalidate(userFavoritesProvider);
                    
                  },
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(userFavoriteListsProvider(userID));
                    ref.invalidate(userFavoritesProvider);
                    Navigator.pop(context);
                  },
                  child: const Text("Ok"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class FavoriteListSelectionList extends ConsumerWidget {
  final String selectedPoiId;

  const FavoriteListSelectionList({required this.selectedPoiId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userID = ref.watch(supabaseUserStateProvider).userid;

    final favListsAsync = ref.watch(userFavoriteListsProvider(userID));

    return favListsAsync.when(
      data: (listOfFavoriteLists) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...listOfFavoriteLists.map((entry) {
              final (listDTO, favoritesInThisList) = entry;

              final isSelected = favoritesInThisList.any(
                (fav) => fav.poiID == selectedPoiId,
              );

              return CheckboxListTile(
                value: isSelected,
                title: Text(listDTO.name),
                visualDensity: VisualDensity.compact,
                onChanged: (checked) {
                  ref.read(toggleFavoriteProvider)(
                    poiId: selectedPoiId,
                    listId: listDTO.id,
                    add: checked == true,
                  );

                  ref.invalidate(userFavoriteListsProvider(userID));
                  ref.invalidate(userFavoritesProvider);
                },
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text("Error: $e")),
    );
  }
}
