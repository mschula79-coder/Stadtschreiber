import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:stadtschreiber/models/image_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageRepository {
  final SupabaseClient supabase;

  ImageRepository(this.supabase);

  Future<ImageEntry?> pickProcessAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();

    final decoded = await decodeImageFromList(bytes);
    final w = decoded.width;
    final h = decoded.height;

    const maxSize = 1200;
    final scale = maxSize / (w > h ? w : h);

    final targetWidth = (w * scale).round();
    final targetHeight = (h * scale).round();

    // EXIF-Fix + Resize + WebP in einem Schritt
    final processed = await FlutterImageCompress.compressWithList(
      bytes,
      autoCorrectionAngle: true,
      format: CompressFormat.webp,
      quality: 80,
      minWidth: targetWidth,
      minHeight: targetHeight,
    );
    final originalName = picked.name; // z.B. "IMG_1234.JPG"

    // Extension extrahieren
    final extIndex = originalName.lastIndexOf('.');
    final baseName = extIndex != -1
        ? originalName.substring(0, extIndex)
        : originalName;

    // Timestamp anhängen
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Neuer Dateiname
    final fileName = "${baseName}_$timestamp.webp";

    await supabase.storage
        .from("Photos")
        .uploadBinary("processed/$fileName", Uint8List.fromList(processed));
    final url = supabase.storage
        .from("Photos")
        .getPublicUrl("processed/$fileName");
    return ImageEntry(title: baseName, url: url, enteredBy: 'dummy');
  }
}
