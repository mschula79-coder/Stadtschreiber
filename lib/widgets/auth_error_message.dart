import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthOperation {
  login,
  registration,
  passwordReset,
  passwordUpdate,
  emailConfirmation,
}

String getAuthErrorMessage(
  Object error,
  String? languageCode,
  String? countryCode, {
  required AuthOperation operation,
}) {
  if (error is! AuthException) {
    return switch (operation) {
      AuthOperation.login =>
        'Die Anmeldung konnte nicht durchgeführt werden. Bitte versuche es später erneut.',
      AuthOperation.registration =>
        'Die Registrierung konnte nicht durchgeführt werden. Bitte versuche es später erneut.',
      AuthOperation.passwordReset =>
        'Die E-Mail zum Zurücksetzen des Passworts konnte nicht gesendet werden.',
      AuthOperation.passwordUpdate =>
        'Das Passwort konnte nicht geändert werden.',
      AuthOperation.emailConfirmation =>
        'Die E-Mail-Adresse konnte nicht bestätigt werden.',
    };
  }

  final code = error.code?.trim().toLowerCase();
  final statusCode = error.statusCode?.trim();

  switch (code) {
    case 'invalid_credentials':
    case 'user_not_found':
      return getText(
        'authInvalidCredentials',
        languageCode: languageCode,
        countryCode: countryCode,
      );

    case 'email_not_confirmed':
      return 'Bitte bestätige zuerst deine E-Mail-Adresse. Prüfe auch den Spamordner.';

    case 'email_address_invalid':
    case 'validation_failed':
      return 'Bitte gib eine gültige E-Mail-Adresse ein.';

    case 'email_address_not_authorized':
      return 'Diese E-Mail-Adresse kann nicht für die Registrierung verwendet werden.';

    case 'user_already_exists':
    case 'email_exists':
      return 'Für diese E-Mail-Adresse besteht bereits ein Benutzerkonto. Du kannst dich anmelden oder dein Passwort zurücksetzen.';

    case 'weak_password':
      return 'Das Passwort erfüllt die Sicherheitsanforderungen nicht. Verwende mindestens 8 Zeichen.';

    case 'same_password':
      return 'Das neue Passwort muss sich vom bisherigen Passwort unterscheiden.';

    case 'signup_disabled':
      return 'Neue Registrierungen sind momentan nicht möglich.';

    case 'email_provider_disabled':
      return 'Die Anmeldung mit E-Mail und Passwort ist momentan nicht verfügbar.';

    case 'over_email_send_rate_limit':
      return 'Es wurden zu viele E-Mails angefordert. Bitte warte einige Minuten und versuche es erneut.';

    case 'over_request_rate_limit':
    case 'over_sms_send_rate_limit':
      return 'Es wurden zu viele Anfragen gesendet. Bitte warte einen Moment und versuche es erneut.';

    case 'captcha_failed':
      return 'Die Sicherheitsprüfung ist fehlgeschlagen. Bitte versuche es erneut.';

    case 'session_expired':
    case 'session_not_found':
    case 'refresh_token_not_found':
    case 'refresh_token_already_used':
      return 'Deine Sitzung ist abgelaufen. Bitte melde dich erneut an.';

    case 'bad_jwt':
    case 'invalid_jwt':
      return 'Deine Anmeldung ist nicht mehr gültig. Bitte melde dich erneut an.';

    case 'otp_expired':
      return 'Der Bestätigungscode ist abgelaufen. Bitte fordere einen neuen Code an.';

    case 'otp_disabled':
      return 'Die Anmeldung mit einem Bestätigungscode ist momentan nicht verfügbar.';

    case 'flow_state_expired':
    case 'flow_state_not_found':
    case 'bad_code_verifier':
      return 'Der Anmeldevorgang ist abgelaufen. Bitte starte ihn erneut.';

    case 'manual_linking_disabled':
    case 'identity_already_exists':
    case 'identity_not_found':
      return 'Das Benutzerkonto konnte nicht mit dieser Anmeldemethode verknüpft werden.';

    case 'user_banned':
      return 'Dieses Benutzerkonto ist momentan gesperrt.';

    case 'conflict':
      return 'Die Änderung konnte wegen eines Datenkonflikts nicht gespeichert werden. Bitte versuche es erneut.';

    case 'unexpected_failure':
      return 'Beim Authentifizierungsdienst ist ein unerwarteter Fehler aufgetreten. Bitte versuche es später erneut.';

    case null:
      return _getAuthStatusMessage(
        statusCode,
        languageCode,
        countryCode,
        operation: operation,
      );

    default:
      return _getAuthStatusMessage(
        statusCode,
        languageCode,
        countryCode,
        operation: operation,
      );
  }
}

String _getAuthStatusMessage(
  String? statusCode,
  String? languageCode,
  String? countryCode, {
  required AuthOperation operation,
}) {
  switch (statusCode) {
    case '400':
      return switch (operation) {
        AuthOperation.login => getText(
          'authLoginStatus400',
          languageCode: languageCode,
          countryCode: countryCode,
        ),
        AuthOperation.registration =>
          'Die Registrierungsdaten sind ungültig. Bitte prüfe E-Mail-Adresse, Benutzername und Passwort.',
        AuthOperation.passwordReset =>
          'Die Anfrage zum Zurücksetzen des Passworts ist ungültig.',
        AuthOperation.passwordUpdate =>
          'Das neue Passwort konnte nicht übernommen werden.',
        AuthOperation.emailConfirmation =>
          'Der Bestätigungslink ist ungültig oder bereits abgelaufen.',
      };

    case '401':
      return 'Deine Anmeldung ist nicht mehr gültig. Bitte melde dich erneut an.';

    case '403':
      return switch (operation) {
        AuthOperation.emailConfirmation =>
          'Der Bestätigungslink ist ungültig oder bereits abgelaufen.',
        _ => 'Du bist für diese Aktion nicht berechtigt.',
      };

    case '422':
      return switch (operation) {
        AuthOperation.registration => getText(
          'auth_error_422_1',
          languageCode: languageCode,
          countryCode: countryCode,
        ),
        AuthOperation.passwordUpdate => getText(
          'authPasswordUpdateStatus422',
          languageCode: languageCode,
          countryCode: countryCode,
        ),
        _ => getText(
          'authDataStatus422',
          languageCode: languageCode,
          countryCode: countryCode,
        ),
      };

    case '429':
      return getText(
        'authStatus429',
        languageCode: languageCode,
        countryCode: countryCode,
      );

    case '500':
    case '502':
    case '503':
    case '504':
      return 'Der Anmeldedienst ist momentan nicht erreichbar. Bitte versuche es später erneut.';

    default:
      return switch (operation) {
        AuthOperation.login =>
          'Die Anmeldung ist fehlgeschlagen. Bitte prüfe deine Angaben und versuche es erneut.',
        AuthOperation.registration =>
          'Die Registrierung ist fehlgeschlagen. Bitte prüfe deine Angaben und versuche es erneut.',
        AuthOperation.passwordReset =>
          'Die E-Mail zum Zurücksetzen des Passworts konnte nicht gesendet werden.',
        AuthOperation.passwordUpdate =>
          'Das Passwort konnte nicht geändert werden.',
        AuthOperation.emailConfirmation =>
          'Die E-Mail-Adresse konnte nicht bestätigt werden.',
      };
  }
}
