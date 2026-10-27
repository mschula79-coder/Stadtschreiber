import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/address.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';

class AddressEditModal extends ConsumerStatefulWidget {
  final Address address;

  const AddressEditModal({super.key, required this.address});

  @override
  ConsumerState<AddressEditModal> createState() => _AddressEditModalState();
}

class _AddressEditModalState extends ConsumerState<AddressEditModal> {
  late final TextEditingController _streetController;
  late final TextEditingController _houseNumberController;
  late final TextEditingController _zipCodeController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _streetController = TextEditingController(
      text: widget.address.street ?? '',
    );
    _houseNumberController = TextEditingController(
      text: widget.address.houseNumber ?? '',
    );
    _zipCodeController = TextEditingController(
      text: widget.address.postcode ?? '',
    );
    _cityController = TextEditingController(text: widget.address.city ?? '');
    _districtController = TextEditingController(
      text: widget.address.district ?? '',
    );
    _countryController = TextEditingController(
      text: widget.address.country ?? '',
    );
  }

  @override
  void dispose() {
    _streetController.dispose();
    _houseNumberController.dispose();
    _zipCodeController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _save() {
    Address newAddress = widget.address.copyWith(
      street: _streetController.text.trim(),
      houseNumber: _houseNumberController.text.trim(),
      city: _cityController.text.trim(),
      postcode: _zipCodeController.text.trim(),
      district: _districtController.text.trim(),
      country: _countryController.text.trim(),
    );
    Navigator.pop(
      context,
      newAddress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider).languageCode;
    final countryCode = ref.watch(localeProvider).countryCode;

    return AlertDialog(
      title: Text(getText('editArticle', languageCode: languageCode, countryCode: countryCode)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: "Strasse",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _houseNumberController,
              decoration: const InputDecoration(
                labelText: "Hausnummer",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _zipCodeController,
              decoration: const InputDecoration(
                labelText: "Postleitzahl",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: "Stadt",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _districtController,
              decoration: const InputDecoration(
                labelText: "Stadtteil",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: "Land",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(getText('cancel', languageCode: languageCode, countryCode: countryCode)),
        ),
        ElevatedButton(onPressed: _save, child: Text(getText('save', languageCode: languageCode, countryCode: countryCode))),
      ],
    );
  }
}
