/// Error types surfaced to the UI. Each carries a user-friendly message.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Unable to reach the server. Check your internet connection and try again.',
  ]);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Visitor not found.']);
}

class ServerException extends AppException {
  const ServerException([super.message = 'The server returned an error. Please try again.']);
}

class InvalidResponseException extends AppException {
  const InvalidResponseException([
    super.message = 'Received an unexpected response from the server.',
  ]);
}

/// Thrown when a status change violates the Registered -> Checked In -> Checked Out workflow.
class BusinessRuleException extends AppException {
  const BusinessRuleException(super.message);
}
