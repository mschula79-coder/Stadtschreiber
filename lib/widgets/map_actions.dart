import 'package:flutter/material.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/widgets/user_actions_bar.dart';
import '../services/debug_service.dart';

class MapActions extends ConsumerStatefulWidget {
  final VoidCallback onChangeStyle;
  final VoidCallback onLocateMe;
  final VoidCallback onRemoveThumbnails;
  final VoidCallback onAddPoi;
  final bool isAdmin;
  final bool isAdminViewEnabled;

  const MapActions({
    super.key,
    required this.onChangeStyle,
    required this.onLocateMe,
    required this.onAddPoi,
    required this.onRemoveThumbnails,
    required this.isAdmin,
    required this.isAdminViewEnabled,
  });

  @override
  ConsumerState<MapActions> createState() => _MapActionsState();
}

class _MapActionsState extends ConsumerState<MapActions> {
  bool userActionsExpanded = false;

  @override
  Widget build(BuildContext context) {
    DebugService.log('Build MapActions');

    return Stack(
      children: [
        // MAP ACTIONS BUTTONS
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Goto current location
              FloatingActionButton(
                heroTag: "locateMe",
                onPressed: () {
                  widget.onLocateMe();
                },
                mini: true,
                child: const Icon(Icons.my_location),
              ),

              const SizedBox(height: 8),

              //Clear thumbnails
              FloatingActionButton(
                heroTag: "removeThumbnails",
                onPressed: () {
                  widget.onRemoveThumbnails();
                },
                mini: true,

                child: const Iconify(Mdi.pin_off_outline, size: 24),
              ),
              const SizedBox(height: 8),

              // Goto current location
              if (ref.read(supabaseUserStateProvider).isAdmin)
                FloatingActionButton(
                  heroTag: "addPoi",
                  onPressed: widget.onAddPoi,
                  mini: true,
                  child: const Icon(Icons.add_location),
                ),

              const SizedBox(height: 8),

              Row(
                children: [
                  // User Actions Bar
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: userActionsExpanded
                        ? UserActionsBar(
                            onClose: () =>
                                setState(() => userActionsExpanded = false),
                            onChangeStyle: widget.onChangeStyle,
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Show User Actions Bar
                  FloatingActionButton(
                    heroTag: "userActions",
                    mini: true,
                    onPressed: () {
                      setState(
                        () => userActionsExpanded = !userActionsExpanded,
                      );
                    },
                    child: const Icon(Icons.person),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
