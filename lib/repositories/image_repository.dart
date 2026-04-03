import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageRepository {
  final SupabaseClient supabase;

  ImageRepository(this.supabase);

  Future<String?> pickProcessAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();

    // EXIF-Fix + Resize + WebP in einem Schritt
    final processed = await FlutterImageCompress.compressWithList(
      bytes,
      autoCorrectionAngle: true,
      format: CompressFormat.webp,
      quality: 80,
      minWidth: 1200,
      minHeight: 1200,
    );

    final fileName = "img_${DateTime.now().millisecondsSinceEpoch}.webp";

    await supabase.storage
        .from("Photos")
        .uploadBinary("processed/$fileName", Uint8List.fromList(processed));

    return supabase.storage
        .from("Photos")
        .getPublicUrl("processed/$fileName");
  }
}
