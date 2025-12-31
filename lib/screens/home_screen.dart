import 'package:flutter/material.dart';
import '../models/category.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/map_actions.dart';
import '../widgets/filter_overlay.dart';
import '../controllers/filter_overlay_controller.dart';
import '../repositories/category_repository.dart';
import 'package:provider/provider.dart';
import 'map_screen.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  List<CategoryNode> categories = [];
  final GlobalKey _filterKey = GlobalKey();
  late final CategoryRepository _categoryRepository;
  final FilterOverlayController _overlayController = FilterOverlayController();

  @override
  void initState() {
    super.initState();
    _categoryRepository = context.read<CategoryRepository>();
    _initCategories();
    _overlayController.initAnimation(this);
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
  }

  Future<void> _initCategories() async {
    final loaded = await _categoryRepository.loadCategories();
    setState(() {
      categories = loaded;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: MainAppBar(
        filterButtonKey: _filterKey,
        onFilterPressed: toggleFilterOverlay,
      ),
      body: Stack(
        children: const [
          MapScreen(),
          MapActions(),
        ],
      ),
    );
  }

  void toggleFilterOverlay() {
    _overlayController.toggle(
      context: context,
      buttonKey: _filterKey,
      builder: (anim) {
        return FilterOverlayContent(
          categories: categories,
          animation: anim,
          onClose: _overlayController.hide,
        );
      },
    );
  }
}
