import 'package:stadtschreiber/models/poi.dart';

class Address {
  final String? street;
  final String? houseNumber;
  final String? postcode;
  final String? city;
  final String? district;
  final String? country;

  const Address({
    this.street,
    this.houseNumber,
    this.postcode,
    this.city,
    this.district,
    this.country,
  });

  static Address? fromPoi(PointOfInterest poi) {
    final a = poi.address;
    if (a == null) return null;

    return Address(
      street: a.street,
      houseNumber: a.houseNumber,
      postcode: a.postcode,
      city: a.city,
      district: a.district,
      country: a.country,
    );
  }

  /// Build Address from Supabase row
  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'],
      houseNumber: map['house_number'],
      postcode: map['postcode'],
      city: map['city'],
      district: map['district'],
      country: map['country'],
    );
  }

  /// Convert to Supabase-compatible map
  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'house_number': houseNumber,
      'postcode': postcode,
      'city': city,
      'district': district,
      'country': country,
    };
  }

  /// Create modified copy
  Address copyWith({
    String? street,
    String? houseNumber,
    String? postcode,
    String? city,
    String? district,
    String? country,
  }) {
    return Address(
      street: street ?? this.street,
      houseNumber: houseNumber ?? this.houseNumber,
      postcode: postcode ?? this.postcode,
      city: city ?? this.city,
      district: district ?? this.district,
      country: country ?? this.country,
    );
  }

  /// Check if all fields are empty
  bool get isEmpty {
    return [
      street,
      houseNumber,
      postcode,
      city,
      district,
      country,
    ].every((e) => e == null || e.trim().isEmpty);
  }

  /// Nicely formatted address
  String? displayAddress() {
    final parts = [
      if (street?.trim().isNotEmpty == true) street!.trim(),
      if (houseNumber?.trim().isNotEmpty == true) houseNumber!.trim(),
      if (postcode?.trim().isNotEmpty == true) postcode!.trim(),
      if (city?.trim().isNotEmpty == true) city!.trim(),
    ];

    if (parts.isEmpty) return null;

    return parts.join(' ');
  }
}
