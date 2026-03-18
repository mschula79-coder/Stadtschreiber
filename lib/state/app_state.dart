class AppStateData {
  final bool isAdminViewEnabled;
  final bool isPoiEditMode;
  final bool locationPermission;

  const AppStateData({
    required this.isAdminViewEnabled,
    required this.isPoiEditMode,
    required this.locationPermission,
  });

  AppStateData copyWith({
    bool? isAdmin,
    bool? isAdminViewEnabled,
    bool? isPoiEditMode,
    bool? locationPermission,
    String? username
  }) {
    return AppStateData(
      isAdminViewEnabled: isAdminViewEnabled ?? this.isAdminViewEnabled,
      isPoiEditMode: isPoiEditMode ?? this.isPoiEditMode,
      locationPermission: locationPermission ?? this.locationPermission,
    );
  }

  static const initial = AppStateData(
    isAdminViewEnabled: false,
    isPoiEditMode: false,
    locationPermission: false,
  );
}
