import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/main.dart' show supportedLocales;
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:stadtschreiber/widgets/_icon_getter.dart';
import 'package:stadtschreiber/widgets/modal_message_box.dart';
import 'package:stadtschreiber/widgets/modal_photo_gallery.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  String? errorMessage;
  bool checkEmail = false;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    final languageCode = ref.watch(localeProvider).languageCode;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 600 ? 24.0 : 48.0;

            final availableHeight = constraints.maxHeight - 48.0;

            return SingleChildScrollView(
              physics: keyboardVisible
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: availableHeight.clamp(0.0, constraints.maxHeight),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: AutofillGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (loading) ...[
                            const CircularProgressIndicator(),
                            const SizedBox(height: 24),
                          ],
                          const SizedBox(height: 40),

                          Text(
                            'Stadtschreiber Basel',
                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 0),
                          Text(
                            getText('slogan', languageCode: languageCode),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              final imageUrls = List<String>.generate(13, (
                                index,
                              ) {
                                final number = (index + 1).toString().padLeft(
                                  2,
                                  '0',
                                );

                                return 'https://pub-f79c7b584e8a408282353176df4c42e6.r2.dev/Folie$number.JPG';
                              });

                              PhotoGalleryModal.open(
                                context,
                                imageUrls: imageUrls,
                                initialUrl: imageUrls.first,
                              );
                            },
                            child: Text(
                              getText('newHere', languageCode: languageCode),
                            ),
                          ),

                          const SizedBox(height: 20),
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.email,
                              AutofillHints.username,
                            ],
                            decoration: InputDecoration(
                              labelText: getText(
                                'email',
                                languageCode: languageCode,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) {
                              if (!loading) {
                                _login();
                              }
                            },
                            decoration: InputDecoration(
                              labelText: getText(
                                'password',
                                languageCode: languageCode,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          if (errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: loading ? null : _resetPassword,
                              child: Text(
                                getText(
                                  'passwordForgotten',
                                  languageCode: languageCode,
                                ),
                              ),
                            ),
                          ),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              buildLanguageDropdown(context, ref),
                              ElevatedButton(
                                onPressed: loading ? null : _login,
                                child: Text(
                                  getText('login', languageCode: languageCode),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: loading
                                    ? null
                                    : () async {
                                        if (passwordController.text
                                                .trim()
                                                .length >=
                                            8) {
                                          await _askUsernameAndRegister();
                                        } else {
                                          if (!context.mounted) {
                                            return;
                                          }

                                          messageBox(
                                            context,
                                            'Bitte Passwort mit min. 8 Zeichen setzen',
                                            '',
                                          );
                                        }
                                      },
                                child: Text(
                                  getText(
                                    'register',
                                    languageCode: languageCode,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (checkEmail) ...[
                            const SizedBox(height: 16),
                            Text(
                              getText('checkEmail', languageCode: languageCode),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],

                          SizedBox(height: 40),

                          Text(
                            getText(
                              'underConstruction',
                              languageCode: languageCode,
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              final imageUrls = List<String>.generate(13, (
                                index,
                              ) {
                                final number = (index + 1).toString().padLeft(
                                  2,
                                  '0',
                                );

                                return 'https://pub-f79c7b584e8a408282353176df4c42e6.r2.dev/Folie$number.JPG';
                              });

                              PhotoGalleryModal.open(
                                context,
                                imageUrls: imageUrls,
                                initialUrl: imageUrls.first,
                              );
                            },
                            child: Text(
                              getText('joinus1', languageCode: languageCode),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            getText('joinus2', languageCode: languageCode),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: getIcon("instagram", 24, null),
                                onPressed: () {
                                  launchUrl(
                                    Uri.parse(
                                      'https://www.instagram.com/stadtschreiber.basel/',
                                    ),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                              ),
                              IconButton(
                                icon: getIcon("email", 24, null),
                                onPressed: () {
                                  launchUrl(
                                    Uri.parse(
                                      'mailto:stadtschreiber.basel@gmail.com',
                                    ),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    emailController.text = prefs.getString('last_email') ?? '';
  }

  Future<void> _login() async {
    await _authAction(() async {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('last_email', emailController.text.trim());
  }

  Future<void> _askUsernameAndRegister() async {
    final usernameController = TextEditingController();

    final username = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.chooseUserName),
          content: TextField(
            controller: usernameController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(dialogContext)!.userName,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              Navigator.pop(dialogContext, value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(AppLocalizations.of(dialogContext)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, usernameController.text.trim());
              },
              child: Text(AppLocalizations.of(dialogContext)!.goOn),
            ),
          ],
        );
      },
    );

    usernameController.dispose();

    if (username == null || username.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('pending_username', username);

    await _register();
  }

  Future<void> _register() async {
    if (!mounted) {
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
      checkEmail = false;
    });

    try {
      await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        emailRedirectTo: 'stadtschreiber://auth-callback',
      );

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('last_email', emailController.text.trim());

      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = null;
        checkEmail = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _authAction(Future<void> Function() action) async {
    if (!mounted) {
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
      checkEmail = false;
    });

    try {
      await action();

      final session = Supabase.instance.client.auth.currentSession;

      if (!mounted) {
        return;
      }

      if (session == null) {
        setState(() {
          errorMessage = 'Authentication failed';
        });

        return;
      }

      Navigator.pushReplacementNamed(context, '/map');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final emailControllerForReset = TextEditingController(
      text: emailController.text,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.resetPassword),
          content: TextField(
            controller: emailControllerForReset,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofocus: true,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(dialogContext)!.email,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              Navigator.pop(dialogContext);
              _sendResetEmail(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(AppLocalizations.of(dialogContext)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final email = emailControllerForReset.text.trim();

                Navigator.pop(dialogContext);
                _sendResetEmail(email);
              },
              child: Text(AppLocalizations.of(dialogContext)!.send),
            ),
          ],
        );
      },
    );

    emailControllerForReset.dispose();
  }

  Future<void> _sendResetEmail(String email) async {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final resetLinkSent = AppLocalizations.of(context)!.resetLinkSent;

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'stadtschreiber://auth-callback',
      );

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(resetLinkSent)));
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text('Fehler: $error')));
    }
  }

  Widget buildLanguageDropdown(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: currentLocale,
          isDense: true,
          borderRadius: BorderRadius.circular(20),
          dropdownColor: colorScheme.surfaceContainer,
          focusColor: Colors.transparent,
          iconEnabledColor: colorScheme.primary.withValues(alpha: 0.8),
          iconDisabledColor: colorScheme.primary.withValues(alpha: 0.38),
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          onChanged: loading
              ? null
              : (locale) {
                  if (locale == null) {
                    return;
                  }

                  ref.read(localeProvider.notifier).state = locale;
                },
          selectedItemBuilder: (context) {
            return supportedLocales.map((locale) {
              return Center(
                child: getIcon(
                  locale.countryCode ?? locale.languageCode,
                  24,
                  colorScheme.onPrimary,
                ),
              );
            }).toList();
          },
          items: supportedLocales.map((locale) {
            /* final languageName = switch (locale.countryCode) {
              'CH' => 'Schweizerdeutsch',
              _ => switch (locale.languageCode) {
                'de' => 'Deutsch',
                'en' => 'English',
                'fr' => 'Français',
                _ => locale.languageCode,
              },
            }; */

            return DropdownMenuItem<Locale>(
              value: locale,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  getIcon(
                    locale.countryCode ?? locale.languageCode,
                    24,
                    colorScheme.onSecondary,
                  ),
                  /* const SizedBox(width: 8),
                  Text(
                    languageName,
                    style: TextStyle(color: colorScheme.onPrimary),
                  ), */
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  } 
}
