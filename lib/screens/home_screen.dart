import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:stadtschreiber/models/poi_display_modes.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/categories_menu_provider.dart';
import 'package:stadtschreiber/provider/poi_display_mode_provider.dart';
import 'package:stadtschreiber/provider/search_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stadtschreiber/widgets/visible_pois_menu.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'map_screen.dart';

import '../services/debug_service.dart';
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

  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  bool _menuInitialized = false;
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    _initPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _menuInitialized = true);
      ref.read(appStateProvider.notifier).setAdminViewEnabled(true);
    });
  }

  Future<void> _initPermissions() async {
    final granted = await ensureLocationPermission();

    if (!mounted) return;

    ref.read(appStateProvider.notifier).setLocationPermission(granted);
  }

  @override
  Widget build(BuildContext context) {
    DebugService.log('Build HomeScreen');

    bool adminInitialized = false;

    ref.listen<SupabaseUserState>(supabaseUserStateProvider, (previous, next) {
      // Erst reagieren, wenn Profil fertig geladen ist
      if (!adminInitialized && !next.loading) {
        adminInitialized = true;

        debugPrint(
          'SupabaseUserState changed:\n'
          '  userid: ${next.userid}\n'
          '  email: ${next.username}\n'
          '  username: ${next.username}\n'
          '  isAdmin: ${next.isAdmin}\n'
          '  isAuthor: ${next.isAuthor}\n'
          '  loading: ${next.loading}',
        );
        /*         ref.read(appStateProvider.notifier).setAdminViewEnabled(next.isAdmin);*/
      }
    });

    return Scaffold(
      appBar: MainAppBar(
        filterButtonKey: _filterKey,
        onFilterPressed: toggleCategoryMenu,
      ),
      body: Stack(
        children: [
          MapScreen(key: _mapKey),

          // Outside‑Tap‑Catcher
          if (_menuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _menuOpen = false),
                behavior: HitTestBehavior.translucent,
              ),
            ),

          // Das Menü selbst
          AnimatedPositioned(
            duration: _menuInitialized
                ? Duration(milliseconds: 200)
                : Duration.zero,
            curve: Curves.easeOut,
            top: _menuOpen ? 10 : -3000, // Menü fährt rein/raus
            right: 0,
            width: MediaQuery.of(context).size.width * 0.75,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: VisiblePoisMenu(
                onClose: () {
                  final displayMode = ref.read(poiDisplayModeProvider);
                  if (displayMode != PoiDisplayMode.categories) {
                    ref.read(categoriesSelectionProvider.notifier).clear();
                  }
                  if (displayMode != PoiDisplayMode.search) {
                    ref.read(searchSelectionProvider.notifier).clear();
                  }

                  setState(() => _menuOpen = false);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  void toggleCategoryMenu() {
    setState(() {
      _menuOpen = !_menuOpen;
    });
  }
}
