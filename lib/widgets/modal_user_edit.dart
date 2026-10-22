import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';

class UserEditModal extends ConsumerStatefulWidget {
  final String username;
  final String email;
  const UserEditModal({
    super.key, required this.username, required this.email});

  @override
  ConsumerState<UserEditModal> createState() => _UserEditModalState();
}

class _UserEditModalState extends ConsumerState<UserEditModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.username);
    _emailController = TextEditingController(
      text: widget.email,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(context, [_nameController.text, _emailController.text]);
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider).languageCode;
    return AlertDialog(
      title: Text(getText("editProfile")),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Benutzername",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "E-Mail",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(getText("cancel", languageCode: languageCode)),
        ),
        ElevatedButton(onPressed: _save, child: Text(getText("save"))),
      ],
    );
  }
}
