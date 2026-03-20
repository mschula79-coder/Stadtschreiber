bool isValidDateInput(String input) {
  input = input.trim();

  // 1) Jahr: 2000
  if (RegExp(r'^\d{4}$').hasMatch(input)) return true;

  // 2) Monat.Jahr: 12.2025
  if (RegExp(r'^(0?[1-9]|1[0-2])\.\d{4}$').hasMatch(input)) return true;

  // 3) Tag.Monat.Jahr: 31.01.2025
  if (RegExp(
    r'^(0?[1-9]|[12]\d|3[01])\.(0?[1-9]|1[0-2])\.\d{4}$',
  ).hasMatch(input)) {
    return true;
  }
  // 4) Jahresbereich: 2000-2011 oder 2000–2011
  if (RegExp(r'^\d{4}\s*[-–]\s*\d{4}$').hasMatch(input)) return true;

  // 5) Verkürzter Bereich: 1838/40
  if (RegExp(r'^\d{4}/\d{2}$').hasMatch(input)) return true;

  return false;
}

DateTime parseDateInput(String input) {
  input = input.trim();

  // 1) Jahr
  if (RegExp(r'^\d{4}$').hasMatch(input)) {
    return DateTime(int.parse(input));
  }

  // 2) Monat.Jahr
  final monthYear = RegExp(r'^(0?[1-9]|1[0-2])\.(\d{4})$');
  final m = monthYear.firstMatch(input);
  if (m != null) {
    return DateTime(int.parse(m.group(2)!), int.parse(m.group(1)!));
  }

  // 3) Tag.Monat.Jahr
  final dayMonthYear = RegExp(
    r'^(0?[1-9]|[12]\d|3[01])\.(0?[1-9]|1[0-2])\.(\d{4})$',
  );
  final d = dayMonthYear.firstMatch(input);
  if (d != null) {
    return DateTime(
      int.parse(d.group(3)!),
      int.parse(d.group(2)!),
      int.parse(d.group(1)!),
    );
  }

  // 4) Jahresbereich: 2000-2011 oder 2000–2011
  final range = RegExp(r'^(\d{4})\s*[-–]\s*(\d{4})$').firstMatch(input);
  if (range != null) {
    return DateTime(int.parse(range.group(1)!));
  }

  // 5) Verkürzter Bereich: 1838/40
  final shortRange = RegExp(r'^(\d{4})/(\d{2})$').firstMatch(input);
  if (shortRange != null) {
    final startYear = int.parse(shortRange.group(1)!);
    return DateTime(startYear);
  }

  throw FormatException("Ungültiges Datumsformat: $input");
}
