// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a de locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'de';

  static String m0(container) => "Behälter: ${container}";

  static String m1(date) => "Datum: ${date}";

  static String m2(density) => "Dichte: ${density}";

  static String m3(harvestDate) => "Erntedatum: ${harvestDate}";

  static String m4(mostTreatmentId) => "Mostbehandlungs-ID: ${mostTreatmentId}";

  static String m5(mostWeight) => "Mostgewicht: ${mostWeight}";

  static String m6(productionType) => "Produktionstyp: ${productionType}";

  static String m7(userId) => "Benutzer-ID: ${userId}";

  static String m8(volumeInHectoLitre) =>
      "Volumen (Hektoliter): ${volumeInHectoLitre}";

  static String m9(wineId) => "Wein-ID: #${wineId}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "account": MessageLookupByLibrary.simpleMessage("Konto"),
    "accountCreationFailed": MessageLookupByLibrary.simpleMessage(
      "Konto erstellt, aber die automatische Anmeldung ist fehlgeschlagen.",
    ),
    "allWines": MessageLookupByLibrary.simpleMessage("Alle Weine"),
    "appearance": MessageLookupByLibrary.simpleMessage("Erscheinungsbild"),
    "baseUrl": MessageLookupByLibrary.simpleMessage("Basis-URL"),
    "cacheCleared": MessageLookupByLibrary.simpleMessage("Cache geleert"),
    "cancel": MessageLookupByLibrary.simpleMessage("Abbrechen"),
    "changelog": MessageLookupByLibrary.simpleMessage("Änderungsprotokoll"),
    "clearCache": MessageLookupByLibrary.simpleMessage("Cache leeren"),
    "confirmPassword": MessageLookupByLibrary.simpleMessage(
      "Passwort bestätigen",
    ),
    "container": m0,
    "createAccount": MessageLookupByLibrary.simpleMessage("Konto erstellen"),
    "createAccountButton": MessageLookupByLibrary.simpleMessage(
      "Konto erstellen",
    ),
    "darkMode": MessageLookupByLibrary.simpleMessage("Dunkel"),
    "date": m1,
    "density": m2,
    "email": MessageLookupByLibrary.simpleMessage("E-Mail"),
    "enterWineId": MessageLookupByLibrary.simpleMessage("Wein-ID eingeben"),
    "errorOpeningChangelog": MessageLookupByLibrary.simpleMessage(
      "Konnte die Website des Änderungsprotokolls nicht öffnen",
    ),
    "forgotPassword": MessageLookupByLibrary.simpleMessage(
      "Passwort vergessen?",
    ),
    "harvestDate": m3,
    "history": MessageLookupByLibrary.simpleMessage("Verlauf"),
    "home": MessageLookupByLibrary.simpleMessage("Startseite"),
    "lightMode": MessageLookupByLibrary.simpleMessage("Hell"),
    "login": MessageLookupByLibrary.simpleMessage("Anmelden"),
    "loginButton": MessageLookupByLibrary.simpleMessage("Anmelden"),
    "loginError": MessageLookupByLibrary.simpleMessage("Anmeldefehler"),
    "loginFailed": MessageLookupByLibrary.simpleMessage(
      "Anmeldung fehlgeschlagen",
    ),
    "manualEntry": MessageLookupByLibrary.simpleMessage("Manuelle Eingabe"),
    "mostTreatmentId": m4,
    "mostWeight": m5,
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "noHistoryAvailable": MessageLookupByLibrary.simpleMessage(
      "Kein Verlauf verfügbar.",
    ),
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
    "password": MessageLookupByLibrary.simpleMessage("Passwort"),
    "passwordMismatch": MessageLookupByLibrary.simpleMessage(
      "Passwörter stimmen nicht überein.",
    ),
    "productionType": m6,
    "qrScanner": MessageLookupByLibrary.simpleMessage("QR-Scanner"),
    "redirectingToChangelog": MessageLookupByLibrary.simpleMessage(
      "Weiterleitung zum Änderungsprotokoll...",
    ),
    "register": MessageLookupByLibrary.simpleMessage("Registrieren"),
    "registerError": MessageLookupByLibrary.simpleMessage(
      "Registrierungsfehler",
    ),
    "save": MessageLookupByLibrary.simpleMessage("Speichern"),
    "settings": MessageLookupByLibrary.simpleMessage("Einstellungen"),
    "settingsTitle": MessageLookupByLibrary.simpleMessage("Einstellungen"),
    "userId": m7,
    "validationError": MessageLookupByLibrary.simpleMessage(
      "Validierungsfehler",
    ),
    "volume": m8,
    "welcomeTitle": MessageLookupByLibrary.simpleMessage(
      "Willkommen zur Weinkeller App",
    ),
    "wineId": m9,
  };
}
