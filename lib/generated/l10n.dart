// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name =
        (locale.countryCode?.isEmpty ?? false)
            ? locale.languageCode
            : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `All Wines`
  String get allWines {
    return Intl.message('All Wines', name: 'allWines', desc: '', args: []);
  }

  /// `WineID: #{wineId}`
  String wineId(Object wineId) {
    return Intl.message(
      'WineID: #$wineId',
      name: 'wineId',
      desc: '',
      args: [wineId],
    );
  }

  /// `User ID: {userId}`
  String userId(Object userId) {
    return Intl.message(
      'User ID: $userId',
      name: 'userId',
      desc: '',
      args: [userId],
    );
  }

  /// `Most Weight: {mostWeight}`
  String mostWeight(Object mostWeight) {
    return Intl.message(
      'Most Weight: $mostWeight',
      name: 'mostWeight',
      desc: '',
      args: [mostWeight],
    );
  }

  /// `Harvest Date: {harvestDate}`
  String harvestDate(Object harvestDate) {
    return Intl.message(
      'Harvest Date: $harvestDate',
      name: 'harvestDate',
      desc: '',
      args: [harvestDate],
    );
  }

  /// `Volume (HectoLitre): {volumeInHectoLitre}`
  String volume(Object volumeInHectoLitre) {
    return Intl.message(
      'Volume (HectoLitre): $volumeInHectoLitre',
      name: 'volume',
      desc: '',
      args: [volumeInHectoLitre],
    );
  }

  /// `Container: {container}`
  String container(Object container) {
    return Intl.message(
      'Container: $container',
      name: 'container',
      desc: '',
      args: [container],
    );
  }

  /// `Production Type: {productionType}`
  String productionType(Object productionType) {
    return Intl.message(
      'Production Type: $productionType',
      name: 'productionType',
      desc: '',
      args: [productionType],
    );
  }

  /// `Most Treatment ID: {mostTreatmentId}`
  String mostTreatmentId(Object mostTreatmentId) {
    return Intl.message(
      'Most Treatment ID: $mostTreatmentId',
      name: 'mostTreatmentId',
      desc: '',
      args: [mostTreatmentId],
    );
  }

  /// `Changelog`
  String get changelog {
    return Intl.message('Changelog', name: 'changelog', desc: '', args: []);
  }

  /// `Redirecting to the changelog...`
  String get redirectingToChangelog {
    return Intl.message(
      'Redirecting to the changelog...',
      name: 'redirectingToChangelog',
      desc: '',
      args: [],
    );
  }

  /// `Could not open the changelog website`
  String get errorOpeningChangelog {
    return Intl.message(
      'Could not open the changelog website',
      name: 'errorOpeningChangelog',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get account {
    return Intl.message('Account', name: 'account', desc: '', args: []);
  }

  /// `Name`
  String get name {
    return Intl.message('Name', name: 'name', desc: '', args: []);
  }

  /// `Email`
  String get email {
    return Intl.message('Email', name: 'email', desc: '', args: []);
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Confirm Password`
  String get confirmPassword {
    return Intl.message(
      'Confirm Password',
      name: 'confirmPassword',
      desc: '',
      args: [],
    );
  }

  /// `Validation Error`
  String get validationError {
    return Intl.message(
      'Validation Error',
      name: 'validationError',
      desc: '',
      args: [],
    );
  }

  /// `Passwords do not match.`
  String get passwordMismatch {
    return Intl.message(
      'Passwords do not match.',
      name: 'passwordMismatch',
      desc: '',
      args: [],
    );
  }

  /// `Registration Error`
  String get registerError {
    return Intl.message(
      'Registration Error',
      name: 'registerError',
      desc: '',
      args: [],
    );
  }

  /// `Login Error`
  String get loginError {
    return Intl.message('Login Error', name: 'loginError', desc: '', args: []);
  }

  /// `Account created but failed to log in automatically.`
  String get accountCreationFailed {
    return Intl.message(
      'Account created but failed to log in automatically.',
      name: 'accountCreationFailed',
      desc: '',
      args: [],
    );
  }

  /// `Create Account`
  String get createAccount {
    return Intl.message(
      'Create Account',
      name: 'createAccount',
      desc: '',
      args: [],
    );
  }

  /// `Register`
  String get register {
    return Intl.message('Register', name: 'register', desc: '', args: []);
  }

  /// `History`
  String get history {
    return Intl.message('History', name: 'history', desc: '', args: []);
  }

  /// `No history available.`
  String get noHistoryAvailable {
    return Intl.message(
      'No history available.',
      name: 'noHistoryAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Density: {density}`
  String density(Object density) {
    return Intl.message(
      'Density: $density',
      name: 'density',
      desc: '',
      args: [density],
    );
  }

  /// `Date: {date}`
  String date(Object date) {
    return Intl.message('Date: $date', name: 'date', desc: '', args: [date]);
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `Manual Entry`
  String get manualEntry {
    return Intl.message(
      'Manual Entry',
      name: 'manualEntry',
      desc: '',
      args: [],
    );
  }

  /// `Enter WineID`
  String get enterWineId {
    return Intl.message(
      'Enter WineID',
      name: 'enterWineId',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `OK`
  String get ok {
    return Intl.message('OK', name: 'ok', desc: '', args: []);
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `QR Scanner`
  String get qrScanner {
    return Intl.message('QR Scanner', name: 'qrScanner', desc: '', args: []);
  }

  /// `Login`
  String get login {
    return Intl.message('Login', name: 'login', desc: '', args: []);
  }

  /// `Forgot Password?`
  String get forgotPassword {
    return Intl.message(
      'Forgot Password?',
      name: 'forgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `Login failed`
  String get loginFailed {
    return Intl.message(
      'Login failed',
      name: 'loginFailed',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settingsTitle {
    return Intl.message('Settings', name: 'settingsTitle', desc: '', args: []);
  }

  /// `Base URL`
  String get baseUrl {
    return Intl.message('Base URL', name: 'baseUrl', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Appearance`
  String get appearance {
    return Intl.message('Appearance', name: 'appearance', desc: '', args: []);
  }

  /// `Light`
  String get lightMode {
    return Intl.message('Light', name: 'lightMode', desc: '', args: []);
  }

  /// `Dark`
  String get darkMode {
    return Intl.message('Dark', name: 'darkMode', desc: '', args: []);
  }

  /// `Clear Cache`
  String get clearCache {
    return Intl.message('Clear Cache', name: 'clearCache', desc: '', args: []);
  }

  /// `Cache cleared`
  String get cacheCleared {
    return Intl.message(
      'Cache cleared',
      name: 'cacheCleared',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to Weinkeller App`
  String get welcomeTitle {
    return Intl.message(
      'Welcome to Weinkeller App',
      name: 'welcomeTitle',
      desc: '',
      args: [],
    );
  }

  /// `Create Account`
  String get createAccountButton {
    return Intl.message(
      'Create Account',
      name: 'createAccountButton',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get loginButton {
    return Intl.message('Login', name: 'loginButton', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'de'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
