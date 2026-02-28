import 'package:flutter/material.dart';
import '../services/debug_service.dart';

class AppState extends ChangeNotifier {
  bool _isAdmin = false;
  bool _isAdminViewEnabled = false;
  bool _locationPermission = false;
  bool get isAdmin => _isAdmin;
  bool get locationPermission => _locationPermission;
  bool _isPoiEditMode = false;

  void setAdmin(bool value) {
    _isAdmin = value;
    DebugService.log('AppState.setAdmin: $_isAdmin - notifyListeners');
    notifyListeners();
  }

  bool get isAdminViewEnabled => _isAdminViewEnabled;

  void setAdminViewEnabled(bool value) {
    _isAdminViewEnabled = value;
        DebugService.log('AppState.setAdminViewEnabled: $_isAdminViewEnabled - notifyListeners');

    notifyListeners();
  }

  void setPoiEditMode(bool value) {
    _isPoiEditMode = value;
    DebugService.log('AppState.setPoiEditMode: $_isPoiEditMode - notifyListeners');

    notifyListeners();
  }

  bool get isPoiEditMode => _isPoiEditMode;

  void setLocationPermission(bool value) {
    _locationPermission = value;
    DebugService.log('AppState.setLocationPermission: $_locationPermission - notifyListeners');
    notifyListeners();
  }
}
