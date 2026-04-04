import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/app_state.dart';
import '../services/debug_service.dart';

class AppStateNotifier extends Notifier<AppStateData> {
  @override
  AppStateData build() {
    return AppStateData.initial;
  }

  /* void setAdmin(bool value) {
    DebugService.log('AppState.setAdmin: $value');
    state = state.copyWith(isAdmin: value);
  }
 */
  void setAdminViewEnabled(bool value) {
    DebugService.log('AppState.setAdminViewEnabled: $value');
    state = state.copyWith(isAdminViewEnabled: value);
  }

  void setPoiEditMode(bool value) {
    DebugService.log('AppState.setPoiEditMode: $value');
    state = state.copyWith(isPoiEditMode: value);
  }

  void setPoiGeomEditMode(bool value) {
    DebugService.log('AppState.setPoiGeomEditMode: $value');
    state = state.copyWith(isPoiGeomEditMode: value);
  }

  void setLocationPermission(bool value) {
    DebugService.log('AppState.setLocationPermission: $value');
    state = state.copyWith(locationPermission: value);
  }

/*   void setUserName(String name) {
    DebugService.log('AppState.setUsername: $name');
    state = state.copyWith(username: name);
  } */
}

final appStateProvider = NotifierProvider<AppStateNotifier, AppStateData>(
  AppStateNotifier.new,
  name: 'appStateProvider',
);
