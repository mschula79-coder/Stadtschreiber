class AppStateData {
  final bool isAdminViewEnabled;
  final bool isPoiGeomEditMode;
  final bool locationPermission;
  final bool isPoiEditMode;

  const AppStateData({
    required this.isAdminViewEnabled,
    required this.isPoiGeomEditMode,
    required this.isPoiEditMode,
    required this.locationPermission,
  });

  AppStateData copyWith({
    bool? isAdminViewEnabled,
    bool? isPoiGeomEditMode,
    bool? locationPermission,
    bool? isPoiEditMode
  }) {
    return AppStateData(
      isAdminViewEnabled: isAdminViewEnabled ?? this.isAdminViewEnabled,
      isPoiGeomEditMode: isPoiGeomEditMode ?? this.isPoiGeomEditMode,
      isPoiEditMode: isPoiEditMode ?? this.isPoiEditMode,
      locationPermission: locationPermission ?? this.locationPermission,
    );
  }

  static const initial = AppStateData(
    isAdminViewEnabled: false,
    isPoiGeomEditMode: false,
    locationPermission: false,
    isPoiEditMode: false,
  );
}
