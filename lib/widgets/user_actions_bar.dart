import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/main.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/provider/user_profile_repository_provider.dart';
import 'package:stadtschreiber/widgets/_icon_getter.dart';
import 'package:stadtschreiber/widgets/modal_user_edit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserActionsBar extends ConsumerWidget {
  final VoidCallback onClose;
  final VoidCallback onChangeStyle;

  const UserActionsBar({
    super.key,
    required this.onClose,
    required this.onChangeStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(supabaseUserStateProvider);

    final isAdmin = appUser.isAdmin;

    final isAdminViewEnabled = ref.watch(appStateProvider).isAdminViewEnabled;
    final currentLocale = ref.watch(localeProvider);

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

          // Spracheinstellung
          FloatingActionButton(
            heroTag: "Sprache",
            mini: true,
            child: getIcon(currentLocale.languageCode, 24, null),
            onPressed: () {
              onClose();
              showModalBottomSheet(
                context: context,
                builder: (_) => const _LocaleBar(),
              );
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
              child: isAdminViewEnabled
                  ? const Icon(Icons.admin_panel_settings)
                  : const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () {
                ref
                    .read(appStateProvider.notifier)
                    .setAdminViewEnabled(!isAdminViewEnabled);
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

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAuth = Supabase.instance.client.auth.currentUser;
    final user = ref.watch(supabaseUserStateProvider);
    String role = '';

    if (userAuth == null) return SizedBox.shrink();

    if (user.isAdmin) {
      role = "Admin";
    } else if (user.isAuthor) {
      role = "Admin";
    } else {
      role = "Benutzer";
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Benutzer", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),

          Text("Benutzername: ${user.username}"),

          const SizedBox(height: 8),

          Text("Email: ${userAuth.email}"),

          const SizedBox(height: 8),

          Text("Rolle: $role"),

          const SizedBox(height: 8),

          ElevatedButton.icon(
            onPressed: () async {
              final updatedProfile = await showDialog<List<String>>(
                context: context,
                barrierDismissible: false,
                builder: (_) => UserEditModal(
                  email: userAuth.email!,
                  username: user.username,
                ),
              );

              if (!context.mounted) return;
              if (updatedProfile == null) return;

              final newName = updatedProfile[0];
              final newEmail = updatedProfile[1];

              final repo = ref.read(userRepositoryProvider);

              bool changed = false;

              // Username ändern
              if (newName != user.username) {
                await repo.updateUsername(newName);
                changed = true;
              }

              // E-Mail ändern
              if (newEmail != userAuth.email) {
                await repo.updateEmail(newEmail);
                changed = true;

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bitte bestätige deine neue E-Mail-Adresse."),
                  ),
                );
              }

              if (changed) {
                await ref
                    .read(supabaseUserStateProvider.notifier)
                    .loadProfile(userAuth.id);
              }
            },
            icon: const Icon(Icons.person),
            label: const Text("Profil bearbeiten"),
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => const _ChangePasswordSheet(),
              );
            },
            icon: const Icon(Icons.lock),
            label: const Text("Passwort ändern"),
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: () async {
              final userId = Supabase.instance.client.auth.currentUser!.id;

              await Supabase.instance.client.functions.invoke(
                'delete-user',
                body: {'user_id': userId},
              );

              await Supabase.instance.client.auth.signOut();

              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text("Benutzer löschen"),
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

class _LocaleBar extends ConsumerWidget {
  const _LocaleBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: Column(
        children: [
          ...supportedLocales.map((locale) {
            return Text(locale.languageCode);
          }), // Logout
        ],
      ),
    );
  }
}
