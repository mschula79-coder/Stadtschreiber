import '../repositories/category_repository.dart';

class CategoryController {
  final CategoryState state;
  final CategoryRepository repo;

  CategoryController(this.state, this.repo);

  Future<void> loadCategories() async {
    final list = await repo.loadCategories();
    state.setCategories(list);
  }
}
