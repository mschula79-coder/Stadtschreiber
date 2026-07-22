import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/provider/user_favorite_lists_provider.dart';
import 'package:stadtschreiber/widgets/poi_list_item.dart';

class PoiFavouritesList extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final void Function(List<PointOfInterest>) onShowAll;

  const PoiFavouritesList({
    super.key,
    required this.onClose,
    required this.onShowAll,
  });

  @override
  ConsumerState<PoiFavouritesList> createState() => _PoiFavouritesListState();
}

class _PoiFavouritesListState extends ConsumerState<PoiFavouritesList> {
  @override
  Widget build(BuildContext context) {
    final userID = ref.watch(supabaseUserStateProvider).userid;

    final favoriteListsAsync = ref.watch(userFavoriteListsProvider(userID));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        const Text(
          "Favoriten",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        favoriteListsAsync.when(
          data: (listOfFavoriteLists) {
            List<PointOfInterest> favPois = [];

            return ListView.builder(
              shrinkWrap: true, // ⭐ wichtig
              physics: NeverScrollableScrollPhysics(), // ⭐ wichtig
              itemCount: listOfFavoriteLists.length,
              itemBuilder: (context, index) {
                final (listDTO, favoritesInThisList) =
                    listOfFavoriteLists[index];

                return ExpansionTile(
                  title: Text(listDTO.name),
                  tilePadding: const EdgeInsets.only(
                    left: 0,
                    right: 12,
                    bottom: 0,
                    top: 0,
                  ), // ⭐ links kompakt
                  children: [
                    ...favoritesInThisList.map(
                      (fav) => Consumer(
                        builder: (context, ref, _) {
                          final poiAsync = ref.watch(
                            poiByIdProvider(fav.poiID),
                          );

                          return poiAsync.when(
                            data: (poi) {
                              if (poi == null) {
                                return const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Text("POI not found"),
                                );
                              }

                              favPois.add(poi);

                              return PoiListItem(
                                poi: poi,
                                onTap: () {
                                  ref
                                      .read(selectedPoiProvider.notifier)
                                      .setPoi(poi);
                                  widget.onClose();
                                },
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, st) => Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text("Error: $e"),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),

                    // ⭐ Button am Ende der Liste
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Center(
                        child: ElevatedButton(
                          child: const Text("Alle anzeigen"),
                          onPressed: () {
                            widget.onShowAll(favPois);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, st) => Text("Error: $e"),
        ),
      ],
    );
  }
}
