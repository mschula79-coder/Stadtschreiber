class AppStateData {
  final bool isAdminViewEnabled;
  final bool isPoiGeomEditMode;
  final bool locationPermission;
  final bool isPoiEditMode;
  final double panelHeight = 460;
  final bool isPoiListVisible;
  final double mapScreenHeight = 0;

  const AppStateData({
    required this.isAdminViewEnabled,
    required this.isPoiGeomEditMode,
    required this.isPoiEditMode,
    required this.locationPermission,
    required this.isPoiListVisible,
    double? mapScreenHeight,
  });

  AppStateData copyWith({
    bool? isAdminViewEnabled,
    bool? isPoiGeomEditMode,
    bool? locationPermission,
    bool? isPoiEditMode,
    bool? isPoiListVisible,
    double ? mapScreenHeight,
  }) {
    return AppStateData(
      isAdminViewEnabled: isAdminViewEnabled ?? this.isAdminViewEnabled,
      isPoiGeomEditMode: isPoiGeomEditMode ?? this.isPoiGeomEditMode,
      isPoiEditMode: isPoiEditMode ?? this.isPoiEditMode,
      locationPermission: locationPermission ?? this.locationPermission,
      isPoiListVisible: isPoiListVisible ?? this.isPoiListVisible,
      mapScreenHeight: mapScreenHeight ?? this.mapScreenHeight,
    );
  }

  static const initial = AppStateData(
    isAdminViewEnabled: false,
    isPoiGeomEditMode: false,
    locationPermission: false,
    isPoiEditMode: false,
    isPoiListVisible: false,
  );
}
