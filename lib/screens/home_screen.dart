import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'map_screen.dart';

import '../controllers/filter_overlay_controller.dart';
import '../controllers/poi_controller.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';
import '../state/app_state.dart';
import '../services/debug_service.dart';
import '../widgets/filter_overlay.dart';
import '../widgets/main_app_bar.dart';

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
  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  @override
  void initState() {
    super.initState();
    _overlayController.initAnimation(this);

    _overlayController.setOnClosed(() {
      _mapKey.currentState?.reloadPois();
    });

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _loadUserProfile(session.user.id);
      }
    });
  }

  @override
  // ignore: unused_element
  void didChangeDependencies() {
    super.didChangeDependencies();
    _categoryRepository = context.read<CategoryRepository>();
    _initCategories();
  }

  Future<void> _loadUserProfile(String userId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      DebugService.log('User is null, userId: $userId');
      return;
    }

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('is_admin')
        .eq('id', userId)
        .single();
    final isAdmin = profile['is_admin'] ?? false;
    if (!mounted) return;
    context.read<AppState>().setAdmin(isAdmin);
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
        children: [
          Consumer<PoiController>(
            builder: (_, controller, _) {
              controller.addListener(() {
                _mapKey.currentState?.reloadPois();
              });

              return MapScreen(key: _mapKey);
            },
          ),
        ],
      ),
    );
  }

  void toggleFilterOverlay() {
    _overlayController.toggle(
      context: context,
      buttonKey: _filterKey,
      vsync: this,
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
