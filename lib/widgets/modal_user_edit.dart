import 'package:flutter/material.dart';

class UserEditModal extends StatefulWidget {
  final String username;
  final String email;
  const UserEditModal({
    super.key, required this.username, required this.email});

  @override
  State<UserEditModal> createState() => _UserEditModalState();
}

class _UserEditModalState extends State<UserEditModal> {
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
    return AlertDialog(
      title: const Text("Profil bearbeiten"),
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
          child: const Text("Abbrechen"),
        ),
        ElevatedButton(onPressed: _save, child: const Text("Speichern")),
      ],
    );
  }
}
