// Typed exceptions thrown by data-layer components.
// These are caught and converted to [Failure] objects at the repository boundary.

class NetworkException implements Exception {
  const NetworkException([this.message = 'Network error']);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  const AuthException([this.message = 'Auth error']);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}

class UnauthorizedException implements Exception {
  const UnauthorizedException([this.message = 'Unauthorized']);
  final String message;
  @override
  String toString() => 'UnauthorizedException: $message';
}

class NotFoundException implements Exception {
  const NotFoundException([this.message = 'Not found']);
  final String message;
  @override
  String toString() => 'NotFoundException: $message';
}

class ValidationException implements Exception {
  const ValidationException([this.message = 'Validation failed']);
  final String message;
  @override
  String toString() => 'ValidationException: $message';
}

class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);
  final String message;
  @override
  String toString() => 'ServerException: $message';
}

class DuplicateException implements Exception {
  const DuplicateException([this.message = 'Duplicate resource']);
  final String message;
  @override
  String toString() => 'DuplicateException: $message';
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error']);
  final String message;
  @override
  String toString() => 'CacheException: $message';
}
