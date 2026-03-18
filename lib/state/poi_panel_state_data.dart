class PoiPanelStateData {
  final bool isPanelOpen;

  const PoiPanelStateData({required this.isPanelOpen});

  PoiPanelStateData copyWith({bool? isPanelOpen}) {
    return PoiPanelStateData(isPanelOpen: isPanelOpen ?? this.isPanelOpen);
  }

  static const initial = PoiPanelStateData(isPanelOpen: false);
}
