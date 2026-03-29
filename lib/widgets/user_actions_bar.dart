import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserActionsBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onChangeStyle;

  const UserActionsBar({
    super.key,
    required this.onClose,
    required this.onChangeStyle,
  });

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final roles = user?.appMetadata['roles'] ?? [];

    final isAdmin = roles.contains("admin");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: Row(
        children: [
          // Logout
          FloatingActionButton(
            heroTag: "Logout",
            mini: true,
            child: const Icon(Icons.logout),
            onPressed: () async {
              onClose();
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                );
              }
            },
          ),
          
          // Einstellungen Modal öffnen
          FloatingActionButton(
            heroTag: "Einstellungen",
            mini: true,
            child: const Icon(Icons.settings),
            onPressed: () {
              onClose();
              showModalBottomSheet(
                context: context,
                builder: (_) => const _SettingsSheet(),
              );
            },
          ),

          // Admin UI (nur wenn admin)
          if (isAdmin)
            FloatingActionButton(
              heroTag: "Admin UI",
              mini: true,
              child: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                onClose();
                Navigator.pushNamed(context, "/admin");
              },
            ),

          

          //change style
          FloatingActionButton(
            heroTag: "changeStyle",
            onPressed: onChangeStyle,
            mini: true,
            child: const Icon(Icons.color_lens_outlined),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final roles = user?.appMetadata['roles'] ?? [];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Benutzername", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),

          Text("Email: ${user?.email}"),

          const SizedBox(height: 8),

          Text("Rollen: ${roles.join(', ')}"),

          const SizedBox(height: 8),

          // Passwort ändern
          IconButton(
            tooltip: "Passwort ändern",
            icon: const Icon(Icons.lock),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => const _ChangePasswordSheet(),
              );
            },
          ),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // hier kannst du später Profil bearbeiten einbauen
            },
            icon: const Icon(Icons.person),
            label: const Text("Profil bearbeiten"),
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // hier kannst du später Passwort ändern einbauen
            },
            icon: const Icon(Icons.lock),
            label: const Text("Passwort ändern"),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final pass1 = TextEditingController();
  final pass2 = TextEditingController();
  String? error;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Passwort ändern",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: pass1,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Neues Passwort",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: pass2,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Passwort wiederholen",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: loading
                ? null
                : () {
                    // 1) Dialog sofort schließen
                    Navigator.pop(context);

                    // 2) Danach async ausführen
                    _performPasswordChange(
                      pass1.text.trim(),
                      pass2.text.trim(),
                    );
                  },
            child: loading
                ? const CircularProgressIndicator()
                : const Text("Speichern"),
          ),
        ],
      ),
    );
  }

  Future<void> _performPasswordChange(String p1, String p2) async {
    final messenger = ScaffoldMessenger.of(context);

    if (p1 != p2) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Passwörter stimmen nicht überein")),
      );
      return;
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: p1),
      );

      messenger.showSnackBar(
        const SnackBar(content: Text("Passwort erfolgreich geändert")),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Fehler: $e")));
    }
  }
}
