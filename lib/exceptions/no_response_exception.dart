/// Exception for when there is no response from the server or network issues.
class NoResponseException implements Exception {
  final String message;

  NoResponseException(this.message);

  @override
  String toString() => 'NoResponseException: $message';
}
