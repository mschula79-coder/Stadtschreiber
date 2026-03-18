import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'map_screen.dart';

import '../controllers/categories_menu_controller.dart';
import '../services/debug_service.dart';
import '../widgets/categories_menu_overlay.dart';
import '../widgets/main_app_bar.dart';

class MyHomePage extends ConsumerStatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

/// Lädt globale User und App Daten, triggert das OverlayMenu
class _MyHomePageState extends ConsumerState<MyHomePage>
    with TickerProviderStateMixin {
  final GlobalKey _filterKey = GlobalKey();

  final CategoriesMenuController _categoriesMenuController =
      CategoriesMenuController();

  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _categoriesMenuController.initAnimation(this);

    _categoriesMenuController.setOnClosed(() {
      _mapKey.currentState?.reloadPoisForSelectedCategories();
    });

    ensureLocationPermission();
  }

  @override
  void dispose() {
    _categoriesMenuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DebugService.log('Build HomeScreen');

    bool adminInitialized = false;

    ref.listen<SupabaseUserState>(supabaseUserStateProvider, (previous, next) {
      // Erst reagieren, wenn Profil fertig geladen ist
      if (!adminInitialized && !next.loading) {
        adminInitialized = true;

        debugPrint('SupabaseUserState changed: $previous → $next');

/*         ref.read(appStateProvider.notifier).setAdminViewEnabled(next.isAdmin);*/      }
    });

    return Scaffold(
      appBar: MainAppBar(
        filterButtonKey: _filterKey,
        onFilterPressed: toggleCategoryMenuOverlay,
      ),
      body: Stack(
        clipBehavior: Clip.hardEdge,
        children: [MapScreen(key: _mapKey)],
      ),
    );
  }

  Future<bool> ensureLocationPermission() async {
    // 1. Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ref.read(appStateProvider.notifier).setLocationPermission(false);
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
      ref.read(appStateProvider.notifier).setLocationPermission(false);
      return false;
    }

    // 5. Permission granted?
    final granted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    ref.read(appStateProvider.notifier).setLocationPermission(granted);
    return granted;
  }

  void toggleCategoryMenuOverlay() {
    _categoriesMenuController.toggle(
      context: context,
      buttonKey: _filterKey,
      vsync: this,
      builder: (anim) {
        return CategoriesMenuOverlay(
          animation: anim,
          onClose: _categoriesMenuController.hide,
        );
      },
    );
  }
}
