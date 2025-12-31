import '../models/category.dart';
import '../services/category_service.dart';

class CategoryRepository {
  final CategoryService _service = CategoryService();

  Future<List<CategoryNode>> loadCategories() async {
    // Later: caching, Supabase, remote updates, etc.
    return _service.loadCategories();
  }
}
