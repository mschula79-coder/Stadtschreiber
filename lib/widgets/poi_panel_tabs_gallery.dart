import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/image_entry.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/utils/dialog_utils.dart';
import 'package:stadtschreiber/utils/image_utils.dart';
import 'package:stadtschreiber/widgets/_editable_list.dart';
import 'package:stadtschreiber/widgets/modal_image_edit.dart';
import 'package:stadtschreiber/widgets/poi_photo_gallery_modal.dart';
import 'package:url_launcher/url_launcher.dart';

class PoiPanelGalleryTab extends ConsumerWidget {
  const PoiPanelGalleryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPoi = ref.watch(selectedPoiProvider);
    final user = ref.watch(supabaseUserStateProvider);
    final username = user.username;
    final imageUrls = selectedPoi!.images.map((img) => img.url).toList();
    final panelHeight = ref.read(appStateProvider).panelHeight;
    final isEditModeEnabled = ref.watch(appStateProvider).isPoiEditMode;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 15, 10, 5),
        child: Column(
          children: [
            isEditModeEnabled ? SizedBox(height: 15) : SizedBox.shrink(),
            // Featured Image-URL
            isEditModeEnabled
                ? Stack(
                    children: [
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Featured Image-URL",
                          alignLabelWithHint: true,
                          isDense: true,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: EdgeInsets.fromLTRB(0, 0, 35, 0),
                        ),
                        child: Text(
                          selectedPoi.featuredImageUrl ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Edit button Image-URL
                      Positioned(
                        right: 0,
                        top: 10,
                        child: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final newValue = await openEditModal(
                              context,
                              fieldName: "Featured Image-URL",
                              initialValue: selectedPoi.featuredImageUrl ?? '',
                              maxLines: 1,
                            );
                            if (newValue != null) {
                              ref
                                  .read(poiRepositoryProvider)
                                  .updatePoiDataInSupabase(
                                    id: selectedPoi.id,
                                    featuredImageUrl: newValue,
                                  );
                              ref
                                  .read(selectedPoiProvider.notifier)
                                  .setPoi(
                                    selectedPoi.copyWith(
                                      featuredImageUrl: newValue,
                                    ),
                                  );
                              //ref.invalidate(visiblePoisProvider);
                            }
                          },
                        ),
                      ),
                    ],
                  )
                : SizedBox.shrink(),
            isEditModeEnabled ? SizedBox(height: 15) : SizedBox.shrink(),

            // Featured image
            if (selectedPoi.featuredImageUrl == null ||
                selectedPoi.featuredImageUrl!.isEmpty) ...[
              const Icon(
                Icons.image_not_supported,
                size: 80,
                color: Colors.grey,
              ),
            ] else ...[
              FutureBuilder<Size>(
                future: getImageSize(selectedPoi.featuredImageUrl!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final size = snapshot.data!;
                  final aspectRatio = size.width / size.height;
                  final isPortrait = size.height > size.width;

                  return Column(
                    children: [
                      // Bildcontainer
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: isPortrait
                              ? panelHeight * 0.705
                              : double.infinity,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: aspectRatio,
                            child: Image.network(
                              selectedPoi.featuredImageUrl!,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),
                    ],
                  );
                },
              ),
            ],
            // Liste mit ImageUrls
            if (isEditModeEnabled) ...[
              EditableList<ImageEntry>(
                items: selectedPoi.images,
                isEditModeEnabled: isEditModeEnabled,
                onAdd: () async {
                  final newEntry = await showDialog<ImageEntry>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => ImageEditModal(
                      image: ImageEntry(
                        title: '',
                        url: '',
                        enteredBy: username,
                        creditsName: '',
                        creditsUrl: '',
                      ),
                    ),
                  );

                  if (newEntry != null) {
                    final currentPoi = ref.read(selectedPoiProvider)!;

                    final updatedImages = [...currentPoi.images, newEntry];

                    ref
                        .read(poiRepositoryProvider)
                        .updatePoiDataInSupabase(
                          id: currentPoi.id,
                          images: updatedImages,
                        );

                    ref
                        .read(selectedPoiProvider.notifier)
                        .setPoi(currentPoi.copyWith(images: updatedImages));
                  }

                  return newEntry;
                },
                onEdit: (entry) async {
                  final updatedEntry = await showDialog<ImageEntry>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => ImageEditModal(
                      image: ImageEntry(
                        title: entry.title,
                        url: entry.url,
                        enteredBy: entry.enteredBy,
                        creditsName: entry.creditsName ?? '',
                        creditsUrl: entry.creditsUrl ?? '',
                      ),
                    ),
                  );

                  if (updatedEntry != null) {
                    final currentPoi = ref.read(selectedPoiProvider)!;

                    final updatedImages = currentPoi.images.map((img) {
                      return img.url == entry.url ? updatedEntry : img;
                    }).toList();

                    ref
                        .read(poiRepositoryProvider)
                        .updatePoiDataInSupabase(
                          id: currentPoi.id,
                          images: updatedImages,
                        );

                    ref
                        .read(selectedPoiProvider.notifier)
                        .setPoi(currentPoi.copyWith(images: updatedImages));
                  }

                  return updatedEntry;
                },

                onDelete: (entry) async {
                  final updated = [...selectedPoi.images]..remove(entry);
                  ref
                      .read(poiRepositoryProvider)
                      .updatePoiDataInSupabase(
                        id: selectedPoi.id,
                        images: updated,
                      );
                  ref
                      .read(selectedPoiProvider.notifier)
                      .setPoi(selectedPoi.copyWith(images: updated));
                },
                itemBuilder: (entry) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        InkWell(
                          onTap: () => launchUrl(Uri.parse(entry.url)),
                          child: Text(
                            entry.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            // Images
            if (imageUrls.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    final url = imageUrls[index];
                    return GestureDetector(
                      onTap: () => PhotoGalleryModal.open(
                        context,
                        imageUrls: imageUrls,
                        initialIndex: index,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(url, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
