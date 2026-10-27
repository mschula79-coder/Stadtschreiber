import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/main.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/provider/user_profile_repository_provider.dart';
import 'package:stadtschreiber/screens/osm_poi_import_screen.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
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
    final appUser = ref.watch(
      supabaseUserStateProvider,
    );

    final isAdmin = appUser.isAdmin;

    final isAdminViewEnabled = ref.watch(
      appStateProvider.select(
        (state) => state.isAdminViewEnabled,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black26,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'Logout',
            mini: true,
            onPressed: () async {
              onClose();

              await Supabase.instance.client.auth.signOut();

              if (!context.mounted) {
                return;
              }

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
            child: const Icon(Icons.logout),
          ),
          const SizedBox(width: 4),
          const _LanguageMenuButton(),
          const SizedBox(width: 4),
          FloatingActionButton(
            heroTag: 'Einstellungen',
            mini: true,
            onPressed: () {
              onClose();

              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (sheetContext) {
                  return const _SettingsSheet();
                },
              );
            },
            child: const Icon(Icons.settings),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 4),
            FloatingActionButton(
              heroTag: 'Admin UI',
              mini: true,
              onPressed: () {
                ref
                    .read(appStateProvider.notifier)
                    .setAdminViewEnabled(
                      !isAdminViewEnabled,
                    );
              },
              child: Icon(
                isAdminViewEnabled
                    ? Icons.admin_panel_settings
                    : Icons.admin_panel_settings_outlined,
              ),
            ),
          ],
          const SizedBox(width: 4),
          FloatingActionButton(
            heroTag: 'changeStyle',
            mini: true,
            onPressed: onChangeStyle,
            child: const Icon(
              Icons.color_lens_outlined,
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 4),
            FloatingActionButton(
              heroTag: 'OSM_import',
              mini: true,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) {
                      return const OsmPoiImportScreen();
                    },
                  ),
                );
              },
              child: const Icon(Icons.cloud_upload),
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguageMenuButton extends ConsumerWidget {
  const _LanguageMenuButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return Builder(
      builder: (buttonContext) {
        return FloatingActionButton(
          heroTag: 'Sprache',
          mini: true,
          onPressed: () async {
            final buttonRenderBox =
                buttonContext.findRenderObject()
                    as RenderBox?;

            final overlayRenderBox = Overlay.of(
              buttonContext,
              rootOverlay: true,
            ).context.findRenderObject() as RenderBox?;

            if (buttonRenderBox == null ||
                overlayRenderBox == null) {
              return;
            }

            final buttonPosition =
                buttonRenderBox.localToGlobal(
              Offset.zero,
              ancestor: overlayRenderBox,
            );

            final buttonSize = buttonRenderBox.size;
            final overlaySize = overlayRenderBox.size;

            const menuItemHeight = 48.0;
            const menuVerticalPadding = 16.0;
            const menuMargin = 8.0;

            final menuHeight =
                supportedLocales.length *
                    menuItemHeight +
                menuVerticalPadding;

            final preferredTop =
                buttonPosition.dy -
                menuHeight -
                menuMargin;

            final maximumTop =
                overlaySize.height -
                menuHeight -
                menuMargin;

            final menuTop = preferredTop.clamp(
              menuMargin,
              maximumTop < menuMargin
                  ? menuMargin
                  : maximumTop,
            );

            final selectedLocale =
                await showMenu<Locale>(
              context: buttonContext,
              useRootNavigator: true,
              initialValue: currentLocale,
              position: RelativeRect.fromLTRB(
                buttonPosition.dx,
                menuTop,
                overlaySize.width -
                    buttonPosition.dx -
                    buttonSize.width,
                overlaySize.height -
                    buttonPosition.dy,
              ),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
              constraints: const BoxConstraints(
                minWidth: 180,
                maxWidth: 220,
              ),
              items: supportedLocales.map((locale) {
                final isSelected =
                    locale.languageCode ==
                        currentLocale.languageCode &&
                    locale.countryCode ==
                        currentLocale.countryCode;

                return PopupMenuItem<Locale>(
                  value: locale,
                  height: menuItemHeight,
                  child: Row(
                    children: [
                      getIcon(
                        _localeIconCode(locale),
                        24,
                        null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _localeName(locale),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 20,
                          color: Theme.of(
                            buttonContext,
                          ).colorScheme.primary,
                        ),
                    ],
                  ),
                );
              }).toList(),
            );

            if (selectedLocale == null ||
                selectedLocale == currentLocale) {
              return;
            }

            ref
                .read(localeProvider.notifier)
                .state = selectedLocale;
          },
          child: getIcon(
            _localeIconCode(currentLocale),
            24,
            null,
          ),
        );
      },
    );
  }

  static String _localeIconCode(Locale locale) {
    if (locale.languageCode == 'de' &&
        locale.countryCode == 'CH') {
      return 'CH';
    }

    return locale.countryCode ??
        locale.languageCode;
  }

  static String _localeName(Locale locale) {
    if (locale.languageCode == 'de' &&
        locale.countryCode == 'CH') {
      return 'Baseldeutsch';
    }

    switch (locale.languageCode) {
      case 'de':
        return 'Deutsch';
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      default:
        return locale.toLanguageTag();
    }
  }
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;

    final userAuth =
        Supabase.instance.client.auth.currentUser;

    final user = ref.watch(
      supabaseUserStateProvider,
    );

    if (userAuth == null) {
      return const SizedBox.shrink();
    }

    final role = user.isAdmin
        ? 'Admin'
        : user.isEditor
        ? 'Editor'
        : getText(
            'user',
            languageCode: languageCode,
            countryCode: countryCode,
          );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(context).bottom +
              24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                getText(
                  'user',
                  languageCode: languageCode,
                  countryCode: countryCode,
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${getText('username', languageCode: languageCode, countryCode: countryCode)}: ${user.username}',
              ),
              const SizedBox(height: 8),
              Text(
                '${getText('email', languageCode: languageCode, countryCode: countryCode)}: ${userAuth.email ?? ''}',
              ),
              const SizedBox(height: 8),
              Text(
                '${getText('role', languageCode: languageCode, countryCode: countryCode)}: $role',
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final email = userAuth.email;

                  if (email == null) {
                    return;
                  }

                  final updatedProfile =
                      await showDialog<List<String>>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) {
                      return UserEditModal(
                        email: email,
                        username: user.username,
                      );
                    },
                  );

                  if (!context.mounted ||
                      updatedProfile == null ||
                      updatedProfile.length < 2) {
                    return;
                  }

                  final newName =
                      updatedProfile[0].trim();

                  final newEmail =
                      updatedProfile[1].trim();

                  final repository = ref.read(
                    userRepositoryProvider,
                  );

                  var changed = false;

                  if (newName.isNotEmpty &&
                      newName != user.username) {
                    await repository.updateUsername(
                      newName,
                    );

                    changed = true;
                  }

                  if (newEmail.isNotEmpty &&
                      newEmail != email) {
                    await repository.updateEmail(
                      newEmail,
                    );

                    changed = true;

                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      SnackBar(
                        content: Text(
                          getText(
                            'confirmEmail',
                            languageCode:
                                languageCode,
                            countryCode:
                                countryCode,
                          ),
                        ),
                      ),
                    );
                  }

                  if (changed) {
                    await ref
                        .read(
                          supabaseUserStateProvider
                              .notifier,
                        )
                        .loadProfile(userAuth.id);
                  }
                },
                icon: const Icon(Icons.person),
                label: Text(
                  getText(
                    'editProfile',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) {
                      return const _ChangePasswordSheet();
                    },
                  );
                },
                icon: const Icon(Icons.lock),
                label: Text(
                  getText(
                    'changePassword',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final currentUser = Supabase
                      .instance
                      .client
                      .auth
                      .currentUser;

                  if (currentUser == null) {
                    return;
                  }

                  await Supabase
                      .instance
                      .client
                      .functions
                      .invoke(
                        'delete-user',
                        body: {
                          'user_id': currentUser.id,
                        },
                      );

                  await Supabase
                      .instance
                      .client
                      .auth
                      .signOut();

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.pushReplacementNamed(
                    context,
                    '/login',
                  );
                },
                icon: const Icon(
                  Icons.delete_forever,
                ),
                label: Text(
                  getText(
                    'deleteUser',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordSheet
    extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet>
  createState() {
    return _ChangePasswordSheetState();
  }
}

class _ChangePasswordSheetState
    extends ConsumerState<_ChangePasswordSheet> {
  final TextEditingController pass1 =
      TextEditingController();

  final TextEditingController pass2 =
      TextEditingController();

  String? error;
  bool loading = false;

  @override
  void dispose() {
    pass1.dispose();
    pass2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(context).bottom +
              24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                getText(
                  'changePassword',
                  languageCode: languageCode,
                  countryCode: countryCode,
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pass1,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: getText(
                    'newPassword',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                  border:
                      const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pass2,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: getText(
                    'confirm',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                  border:
                      const OutlineInputBorder(),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(
                  error!,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : _submitPasswordChange,
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        getText(
                          'save',
                          languageCode:
                              languageCode,
                          countryCode:
                              countryCode,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitPasswordChange() async {
    final firstPassword = pass1.text.trim();
    final secondPassword = pass2.text.trim();

    final locale = ref.read(localeProvider);
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;

    if (firstPassword != secondPassword) {
      setState(() {
        error = getText(
          'passwordsDoNotMatch',
          languageCode: languageCode,
          countryCode: countryCode,
        );
      });

      return;
    }

    if (firstPassword.isEmpty) {
      setState(() {
        error = getText(
          'newPassword',
          languageCode: languageCode,
          countryCode: countryCode,
        );
      });

      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: firstPassword,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getText(
              'passwordChanged',
              languageCode: languageCode,
              countryCode: countryCode,
            ),
          ),
        ),
      );
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        error =
            '${getText('error', languageCode: languageCode, countryCode: countryCode)}: $exception';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }
}