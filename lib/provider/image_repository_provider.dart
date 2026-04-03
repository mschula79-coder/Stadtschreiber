import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/image_repository.dart';

final imageRepositoryProvider = Provider<ImageRepository>((ref) {
  return ImageRepository(Supabase.instance.client);
});
