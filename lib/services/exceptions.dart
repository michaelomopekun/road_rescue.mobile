/// Custom exceptions for API and authentication operations

/// Exception for API errors
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

/// Exception for unauthorized access
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Exception for validation errors
class ValidationException implements Exception {
  final List<String> messages;
  ValidationException(this.messages);

  @override
  String toString() => 'ValidationException: ${messages.join(', ')}';
}

/// Exception for not found errors
class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);

  @override
  String toString() => 'NotFoundException: $message';
}
