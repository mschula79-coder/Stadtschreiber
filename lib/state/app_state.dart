import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool _isAdmin = false;
  bool _isAdminViewEnabled = false; 
  bool _locationPermission = false;
  bool get isAdmin => _isAdmin;
  bool get locationPermission => _locationPermission;

  void setAdmin(bool value) {
    _isAdmin = value;
    notifyListeners();
  }

   void setAdminViewEnabled(bool value) {
    _isAdminViewEnabled = value;
    notifyListeners();
  }

  bool get isAdminViewEnabled => _isAdminViewEnabled;

  void setLocationPermission(bool value) {
    _locationPermission = value;
    notifyListeners();
  }

}
