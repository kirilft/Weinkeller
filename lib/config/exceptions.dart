class NoResponseException implements Exception {
  final String message;

  NoResponseException(this.message);

  @override
  String toString() => 'NoResponseException: $message';
}

// lib/exceptions/wrong_password_exception.dart

class WrongPasswordException implements Exception {
  final String message;
  WrongPasswordException(this.message);
}
