import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/image_entry.dart';
import 'package:stadtschreiber/provider/image_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_provider.dart';
import 'package:stadtschreiber/services/debug_service.dart';

class ImageEditModal extends ConsumerStatefulWidget {
  final ImageEntry image;

  const ImageEditModal({super.key, required this.image});

  @override
  ConsumerState<ImageEditModal> createState() => _ImageEditModalState();
}

class _ImageEditModalState extends ConsumerState<ImageEditModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  late final TextEditingController _enteredByController;
  late final TextEditingController _creditsNameController;
  late final TextEditingController _creditsUrlController;
  String? previewUrl;
  bool isFeatured = false;
  late ImageEntry image;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.image.title);
    _urlController = TextEditingController(text: widget.image.url);
    _enteredByController = TextEditingController(text: widget.image.enteredBy);
    _creditsNameController = TextEditingController(
      text: widget.image.creditsName,
    );
    _creditsUrlController = TextEditingController(
      text: widget.image.creditsUrl,
    );
    image = widget.image;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _enteredByController.dispose();
    _creditsNameController.dispose();
    _creditsUrlController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final url = _urlController.text.trim();
    final enteredBy = _enteredByController.text.trim();
    final creditsName = _creditsNameController.text.trim();
    final creditsUrl = _creditsUrlController.text.trim();

    if (title.isEmpty || url.isEmpty || enteredBy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Titel, URL und Eingetragen von dürfen nicht leer sein",
          ),
        ),
      );
      return;
    }
    image = ImageEntry(
      title: title,
      url: url,
      enteredBy: enteredBy,
      creditsName: creditsName,
      creditsUrl: creditsUrl,
    );

    Navigator.pop(context, image);
  }

  @override
  Widget build(BuildContext context) {
    final imageRepo = ref.read(imageRepositoryProvider);
    final selectedPoi = ref.watch(selectedPoiProvider);

    isFeatured = (selectedPoi?.featuredImageUrl == image.url);

    DebugService.log(isFeatured.toString());
    return AlertDialog(
      title: const Text("Bildinformationen bearbeiten"),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 600, // or MediaQuery.of(context).size.height * 0.6
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Titel",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // URL + Upload
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: "URL",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: const Text("Bild auswählen"),
                    onPressed: () async {
                      final imageEntry = await imageRepo
                          .pickProcessAndUploadImage();
                      if (imageEntry == null) return;

                      setState(() {
                        image = imageEntry; // <— wichtig!
                        _urlController.text = imageEntry.url;
                        previewUrl = imageEntry.url;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Preview image
              if (previewUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      previewUrl!,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Bildautor
              TextField(
                controller: _enteredByController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Bild eingetragen von",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // Credits name
              TextField(
                controller: _creditsNameController,
                decoration: const InputDecoration(
                  labelText: "Credits Name",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // Credits url
              TextField(
                controller: _creditsUrlController,
                decoration: const InputDecoration(
                  labelText: "Credits Link",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text('Featured Image'),
                value: isFeatured,
                onChanged: (newValue) {
                  final newPoi = selectedPoi!.cloneWithNewValues(
                    featuredImageUrl: newValue ? image.url : null,
                    clearFeaturedImage: !newValue,
                  );

                  ref
                      .read(poiRepositoryProvider)
                      .updatePoiDataInSupabase(
                        id: newPoi.id,
                        featuredImageUrl: newValue ? image.url : null,
                      );

                  ref.read(selectedPoiProvider.notifier).setPoi(newPoi);

                  ref.invalidate(visiblePoisProvider);
                },
              ),
            ],
          ),
        ),
      ),

      // Buttons speichern und abbrechen
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Abbrechen"),
        ),
        ElevatedButton(onPressed: _save, child: const Text("Speichern")),
      ],
    );
  }
}
