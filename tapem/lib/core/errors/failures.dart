import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Network error. Please check your connection.',
  ]);
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'You are not authorized to perform this action.',
  ]);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'The requested resource was not found.',
  ]);
}

final class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed.']);
}

final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Server error. Please try again later.',
  ]);
}

final class OfflineFailure extends Failure {
  const OfflineFailure([
    super.message = 'You are offline. Data saved locally.',
  ]);
}

final class DuplicateFailure extends Failure {
  const DuplicateFailure([super.message = 'This resource already exists.']);
}

final class TenantIsolationFailure extends Failure {
  const TenantIsolationFailure([super.message = 'Cross-tenant access denied.']);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error.']);
}
