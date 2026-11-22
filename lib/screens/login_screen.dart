import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/main.dart' show supportedLocales;
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:stadtschreiber/widgets/_icon_getter.dart';
import 'package:stadtschreiber/widgets/auth_error_message.dart';
import 'package:stadtschreiber/widgets/modal_about.dart';
import 'package:stadtschreiber/widgets/modal_message_box.dart';
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
  static const String _backgroundImageUrl =
      'https://pub-a3b6ec9e27e54bfa8694c78d3794399e.r2.dev/blick_von_dreirosenbruecke_1778771451102.webp';
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
    final countryCode = ref.watch(localeProvider).countryCode;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.network(
              _backgroundImageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return ColoredBox(color: Theme.of(context).colorScheme.surface);
              },
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.38)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 600
                    ? 24.0
                    : 48.0;

                final availableHeight = constraints.maxHeight - 48.0;

                return SingleChildScrollView(
                  physics: keyboardVisible
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: availableHeight.clamp(
                        0.0,
                        constraints.maxHeight,
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.28),
                                blurRadius: 24,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: AutofillGroup(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (loading) ...[
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 24),
                                ],
                                const SizedBox(height: 16),
                                const Text(
                                  'Stadtschreiber Basel',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                Text(
                                  getText(
                                    'slogan',
                                    languageCode: languageCode,
                                    countryCode: countryCode,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  getText(
                                    'underConstruction',
                                    languageCode: languageCode,
                                    countryCode: countryCode,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 28),
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
                                      countryCode: countryCode,
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(
                                      context,
                                    ).colorScheme.surface,
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
                                      countryCode: countryCode,
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(
                                      context,
                                    ).colorScheme.surface,
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
                                        countryCode: countryCode,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Align(
                                  alignment: Alignment.center,
                                  child: Wrap(
                                    alignment: WrapAlignment.start,
                                    spacing: 12,
                                    runSpacing: 12,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      buildLanguageDropdown(context, ref),
                                      ElevatedButton(
                                        onPressed: loading ? null : _login,
                                        child: Text(
                                          getText(
                                            'login',
                                            languageCode: languageCode,
                                            countryCode: countryCode,
                                          ),
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
                                                    getText(
                                                      'passwordTooShort',
                                                      languageCode:
                                                          languageCode,
                                                      countryCode: countryCode,
                                                    ),
                                                    '',
                                                  );
                                                }
                                              },
                                        child: Text(
                                          getText(
                                            'register',
                                            languageCode: languageCode,
                                            countryCode: countryCode,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (checkEmail) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    getText(
                                      'checkEmail',
                                      languageCode: languageCode,
                                      countryCode: countryCode,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                                const SizedBox(height: 40),
                                Text(
                                  getText(
                                    'joinus2',
                                    languageCode: languageCode,
                                    countryCode: countryCode,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                  onPressed: () {
                                    AboutModal.open(context);
                                  },
                                  child: Text(
                                    getText(
                                      'joinus1',
                                      languageCode: languageCode,
                                      countryCode: countryCode,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: getIcon('instagram', 24, null),
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
                                      icon: getIcon('email', 24, null),
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
                  ),
                );
              },
            ),
          ),
        ],
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
    final email = emailController.text.trim().toLowerCase();

    final loginSuccessful = await _authAction(() async {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: passwordController.text,
      );
    }, operation: AuthOperation.login);

    if (!loginSuccessful) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('last_email', email);
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
              Navigator.of(dialogContext).pop(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(AppLocalizations.of(dialogContext)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(usernameController.text.trim());
              },
              child: Text(AppLocalizations.of(dialogContext)!.goOn),
            ),
          ],
        );
      },
    );

    usernameController.dispose();

    if (username == null || username.trim().isEmpty) {
      return;
    }

    await _register(username.trim());
  }

  Future<void> _register(String username) async {
    if (!mounted) {
      return;
    }
    final languageCode = ref.watch(localeProvider).languageCode;
    final countryCode = ref.watch(localeProvider).countryCode;

    final email = emailController.text.trim();

    final password = passwordController.text.trim();

    final normalizedUsername = username.trim();

    setState(() {
      loading = true;
      errorMessage = null;
      checkEmail = false;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'stadtschreiber://auth-callback',
        data: <String, dynamic>{'username': normalizedUsername},
      );

      final registeredUser = response.user;

      if (registeredUser == null) {
        throw const AuthException('registration_failed');
      }

      final storedUsername = registeredUser.userMetadata?['username']
          ?.toString()
          .trim();

      if (storedUsername != normalizedUsername) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: <String, dynamic>{'username': normalizedUsername},
          ),
        );
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('last_email', email);

      await prefs.remove('pending_username');

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
        errorMessage = getAuthErrorMessage(
          error,
          languageCode,
          countryCode ?? '',
          operation: AuthOperation.registration,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<bool> _authAction(
    Future<void> Function() action, {
    required AuthOperation operation,
  }) async {
    if (!mounted) {
      return false;
    }
    final languageCode = ref.watch(localeProvider).languageCode;
    final countryCode = ref.watch(localeProvider).countryCode;

    setState(() {
      loading = true;
      errorMessage = null;
      checkEmail = false;
    });

    try {
      await action();

      final session = Supabase.instance.client.auth.currentSession;

      /* print(
  'ACCESS_TOKEN=${session?.accessToken}'
    );
 */
      if (session == null) {
        throw const AuthException('session_missing');
      }

      if (!mounted) {
        return false;
      }

      Navigator.pushReplacementNamed(context, '/map');

      return true;
    } on AuthException catch (error) {
      if (!mounted) {
        return false;
      }

      setState(() {
        errorMessage = getAuthErrorMessage(
          error,
          languageCode,
          countryCode ?? '',
          operation: operation,
        );
      });

      return false;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      setState(() {
        errorMessage = getAuthErrorMessage(
          error,
          languageCode,
          countryCode,
          operation: operation,
        );
      });

      return false;
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

    final normalizedEmail = email.trim().toLowerCase();

    final messenger = ScaffoldMessenger.of(context);

    final resetLinkSent = getText(
      'resetLinkSent',
      languageCode: ref.read(localeProvider).languageCode,
      countryCode: ref.read(localeProvider).countryCode,
    );

    final languageCode = ref.watch(localeProvider).languageCode;
    final countryCode = ref.watch(localeProvider).countryCode;

    if (normalizedEmail.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            getText(
              'enterEmail',
              languageCode: languageCode,
              countryCode: countryCode,
            ),
          ),
        ),
      );
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        normalizedEmail,
        redirectTo: kIsWeb
            ? 'https://stadtschreiber.app/?passwordRecovery=true'
            : 'stadtschreiber://auth-callback',
      );

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(resetLinkSent)));
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = getAuthErrorMessage(
        error,
        languageCode,
        countryCode ?? '',
        operation: AuthOperation.passwordReset,
      );

      setState(() {
        errorMessage = message;
      });

      messenger.showSnackBar(SnackBar(content: Text(message)));
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
