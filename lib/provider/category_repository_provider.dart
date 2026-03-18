import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/repositories/category_repository.dart';

final categoriesRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});
