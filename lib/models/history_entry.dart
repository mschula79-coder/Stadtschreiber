import 'package:stadtschreiber/services/datetime_service.dart';

class HistoryEntry {
  final String rawStart;
  final String? rawEnd;
  final DateTime start;
  final DateTime? end;
  final String description;

  HistoryEntry({
    required this.rawStart,
    this.rawEnd,
    required this.start,
    this.end,
    required this.description,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawStart = json['rawStart'] as String;
    final rawEnd = json['rawEnd'] as String?;
    final description = json['description'] as String? ?? '';

    // parseDateInput kommt aus deinem DateTimeService
    final start = parseDateInput(rawStart);
    final end = rawEnd != null && rawEnd.isNotEmpty
        ? parseDateInput(rawEnd)
        : null;

    return HistoryEntry(
      rawStart: rawStart,
      rawEnd: rawEnd,
      start: start,
      end: end,
      description: description,
    );
  }

  Map<String, dynamic> toJson() => {
    'rawStart': rawStart,
    'rawEnd': rawEnd,
    'start': start.toIso8601String(),
    'end': end?.toIso8601String(),
    'description': description,
  };

  String getLabel() {
    if (rawEnd == null || rawEnd!.isEmpty) {
      return rawStart;
    }
    return "$rawStart – $rawEnd";
  }
}
