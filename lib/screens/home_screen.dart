import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:geolocator/geolocator.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:stadtschreiber/layout/app_breakpoints.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/poi_selection_provider.dart';
import 'package:stadtschreiber/provider/search_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_menu_state_provider.dart';
import 'package:stadtschreiber/theme/app_layout.dart';
import 'package:stadtschreiber/widgets/visible_pois_menu.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'map_screen.dart';

class MyHomePage extends ConsumerStatefulWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage>
    with TickerProviderStateMixin {
  final GlobalKey _filterKey = GlobalKey();
  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  bool _menuInitialized = false;
  bool _menuOpen = false;
  double? _lastMapScreenHeight;

  @override
  void initState() {
    super.initState();

    WakelockPlus.enable();
    _initPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _menuInitialized = true;
      });

      ref.read(appStateProvider.notifier).setAdminViewEnabled(true);
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _initPermissions() async {
    final granted = await ensureLocationPermission();

    if (!mounted) {
      return;
    }

    ref.read(appStateProvider.notifier).setLocationPermission(granted);
  }

  void _updateMapScreenHeight(double height) {
    if (_lastMapScreenHeight == height) {
      return;
    }

    _lastMapScreenHeight = height;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ref.read(appStateProvider.notifier).setMapScreenHeight(height);
    });
  }

  @override
  Widget build(BuildContext context) {
    final expandedTiles = ref.watch(
      visiblePoisMenuStateProvider.select((state) => state.expandedTiles),
    );

    final anyExpanded = expandedTiles.values.any((expanded) => expanded);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          _updateMapScreenHeight(height);

          final isCompact = width < AppBreakpoints.compact;

          final isMedium =
              width >= AppBreakpoints.compact && width < AppBreakpoints.medium;

          final isExpanded =
              width >= AppBreakpoints.medium && width < AppBreakpoints.expanded;

          final isWide = width >= AppBreakpoints.expanded;

          late final double menuWidth;
          late final double menuHeightFactor;
          late final double menuRight;

          if (isCompact) {
            final paddingWidth = anyExpanded ? 40.0 : 150.0;

            menuWidth = width - paddingWidth;
            menuHeightFactor = anyExpanded ? 0.75 : 0.35;
            menuRight = 30.0;
          } else if (isMedium) {
            menuWidth = anyExpanded ? 560.0 : 440.0;
            menuHeightFactor = anyExpanded ? 0.80 : 0.45;
            menuRight = 30.0;
          } else if (isExpanded) {
            menuWidth = anyExpanded ? 640.0 : 480.0;
            menuHeightFactor = anyExpanded ? 0.85 : 0.55;
            menuRight = 30.0;
          } else if (isWide) {
            menuWidth = anyExpanded ? 720.0 : 250.0;
            menuHeightFactor = anyExpanded ? 0.85 : 0.45;
            menuRight = 30.0;
          }

          final maximumMenuWidth =
              (AppLayout.menuWidth(context) - menuRight - 12.0).clamp(
                0.0,
                width,
              );

          final safeMenuWidth = menuWidth.clamp(0.0, maximumMenuWidth);

          final maximumMenuHeight = (height - 20.0).clamp(0.0, height);

          final menuHeight = (height * menuHeightFactor).clamp(
            0.0,
            maximumMenuHeight,
          );

          return SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                // MapScreen
                Positioned.fill(child: MapScreen(key: _mapKey)),
                if (_menuOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        setState(() {
                          _menuOpen = false;
                        });
                      },
                    ),
                  ),
        
                Positioned(
                  top: 25,
                  left: 25,
                  child: Image.asset('assets/icons/basel-no-bg.png', height: 35),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    key: _filterKey,
                    iconSize: 50,
                    icon: Iconify(Mdi.map_search, size: 30),
                    onPressed: toggleCategoryMenu,
                  ),
                ),

                _menuOpen
                    ? AnimatedPositioned(
                        duration: _menuInitialized
                            ? const Duration(milliseconds: 500)
                            : Duration.zero,
                        curve: Curves.easeOut,
                        top: _menuOpen ? 50.0 : -height - 20.0,
                        right: menuRight,
                        width: safeMenuWidth,
                        height: menuHeight,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: PointerInterceptor(
                            child: VisiblePoisMenu(
                              onClose: () {
                                ref.read(poiSelectionProvider.notifier).clear();

                                ref
                                    .read(searchSelectionProvider.notifier)
                                    .clear();

                                if (!mounted) {
                                  return;
                                }

                                setState(() {
                                  _menuOpen = false;
                                });
                              },
                            ),
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool> ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();

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
