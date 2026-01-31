import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool _isAdmin = false;
  bool _locationPermission = false;
  bool get isAdmin => _isAdmin;
  bool get locationPermission => _locationPermission;

  void setAdmin(bool value) {
    _isAdmin = value;
    notifyListeners();
  }

  void setLocationPermission(bool value) {
    _locationPermission = value;
    notifyListeners();
  }

}
