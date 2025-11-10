// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(container) => "Container: ${container}";

  static String m1(date) => "Date: ${date}";

  static String m2(density) => "Density: ${density}";

  static String m3(harvestDate) => "Harvest Date: ${harvestDate}";

  static String m4(mostTreatmentId) => "Most Treatment ID: ${mostTreatmentId}";

  static String m5(mostWeight) => "Most Weight: ${mostWeight}";

  static String m6(productionType) => "Production Type: ${productionType}";

  static String m7(userId) => "User ID: ${userId}";

  static String m8(volumeInHectoLitre) =>
      "Volume (HectoLitre): ${volumeInHectoLitre}";

  static String m9(wineId) => "WineID: #${wineId}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "account": MessageLookupByLibrary.simpleMessage("Account"),
    "accountCreationFailed": MessageLookupByLibrary.simpleMessage(
      "Account created but failed to log in automatically.",
    ),
    "allWines": MessageLookupByLibrary.simpleMessage("All Wines"),
    "appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
    "baseUrl": MessageLookupByLibrary.simpleMessage("Base URL"),
    "cacheCleared": MessageLookupByLibrary.simpleMessage("Cache cleared"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "changelog": MessageLookupByLibrary.simpleMessage("Changelog"),
    "clearCache": MessageLookupByLibrary.simpleMessage("Clear Cache"),
    "confirmPassword": MessageLookupByLibrary.simpleMessage("Confirm Password"),
    "container": m0,
    "createAccount": MessageLookupByLibrary.simpleMessage("Create Account"),
    "createAccountButton": MessageLookupByLibrary.simpleMessage(
      "Create Account",
    ),
    "darkMode": MessageLookupByLibrary.simpleMessage("Dark"),
    "date": m1,
    "density": m2,
    "email": MessageLookupByLibrary.simpleMessage("Email"),
    "enterWineId": MessageLookupByLibrary.simpleMessage("Enter WineID"),
    "errorOpeningChangelog": MessageLookupByLibrary.simpleMessage(
      "Could not open the changelog website",
    ),
    "forgotPassword": MessageLookupByLibrary.simpleMessage("Forgot Password?"),
    "harvestDate": m3,
    "history": MessageLookupByLibrary.simpleMessage("History"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "lightMode": MessageLookupByLibrary.simpleMessage("Light"),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "loginButton": MessageLookupByLibrary.simpleMessage("Login"),
    "loginError": MessageLookupByLibrary.simpleMessage("Login Error"),
    "loginFailed": MessageLookupByLibrary.simpleMessage("Login failed"),
    "manualEntry": MessageLookupByLibrary.simpleMessage("Manual Entry"),
    "mostTreatmentId": m4,
    "mostWeight": m5,
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "noHistoryAvailable": MessageLookupByLibrary.simpleMessage(
      "No history available.",
    ),
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "passwordMismatch": MessageLookupByLibrary.simpleMessage(
      "Passwords do not match.",
    ),
    "productionType": m6,
    "qrScanner": MessageLookupByLibrary.simpleMessage("QR Scanner"),
    "redirectingToChangelog": MessageLookupByLibrary.simpleMessage(
      "Redirecting to the changelog...",
    ),
    "register": MessageLookupByLibrary.simpleMessage("Register"),
    "registerError": MessageLookupByLibrary.simpleMessage("Registration Error"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "settingsTitle": MessageLookupByLibrary.simpleMessage("Settings"),
    "userId": m7,
    "validationError": MessageLookupByLibrary.simpleMessage("Validation Error"),
    "volume": m8,
    "welcomeTitle": MessageLookupByLibrary.simpleMessage(
      "Welcome to Weinkeller App",
    ),
    "wineId": m9,
  };
}
