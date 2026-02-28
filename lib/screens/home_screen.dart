import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'map_screen.dart';

import '../controllers/categories_menu_controller.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';
import '../services/debug_service.dart';
import '../state/app_state.dart';
import '../widgets/categories_menu.dart';
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
  final CategoriesMenuController _categoriesMenuController =
      CategoriesMenuController();
  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  late final StreamSubscription _authSub;

  @override
  void initState() {
    super.initState();

    _categoriesMenuController.initAnimation(this);

    _categoriesMenuController.setOnClosed(() {
      _mapKey.currentState?.reloadPois();
    });

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
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
        .maybeSingle();

    final isAdmin = profile?['is_admin'] ?? false;

    if (!mounted) return;
    context.read<AppState>().setAdmin(isAdmin);
    context.read<AppState>().setAdminViewEnabled(isAdmin);

    ensureLocationPermission();
  }

  Future<bool> ensureLocationPermission() async {
    final appState = context.read<AppState>();

    // 1. Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      appState.setLocationPermission(false);
      return false;
    }

    // 2. Check current permission
    LocationPermission permission = await Geolocator.checkPermission();

    // 3. Request permission if needed
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 4. Handle deniedForever
    if (permission == LocationPermission.deniedForever) {
      appState.setLocationPermission(false);
      return false;
    }

    // 5. Permission granted?
    final granted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    appState.setLocationPermission(granted);
    return granted;
  }

  @override
  void dispose() {
    _categoriesMenuController.dispose();
    _authSub.cancel();
    super.dispose();
  }

  Future<void> _initCategories() async {
    final loaded = await _categoryRepository.loadCategories();

    if (!mounted) return;
    setState(() => categories = loaded);
  }

  @override
  Widget build(BuildContext context) {
    DebugService.log('Build HomeScreen');

    return Scaffold(
      appBar: MainAppBar(
        filterButtonKey: _filterKey,
        onFilterPressed: toggleCategoryMenuOverlay,
      ),
      body: categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              clipBehavior: Clip.hardEdge,
              children: [MapScreen(key: _mapKey)],
            ),
    );
  }

  void toggleCategoryMenuOverlay() {
    _categoriesMenuController.toggle(
      context: context,
      buttonKey: _filterKey,
      vsync: this,
      builder: (anim) {
        return CategoriesMenuOverlayContent(
          categories: categories,
          animation: anim,
          onClose: _categoriesMenuController.hide,
        );
      },
    );
  }
}
