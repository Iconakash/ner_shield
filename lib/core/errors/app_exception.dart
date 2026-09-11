/// Application exception tree + mapping from backend error envelope.
///
/// Backend contract (docs/backend-contract.md §2):
/// `{ "error": { "code", "message", "request_id", "detail" } }`
library;

sealed class AppException implements Exception {
  const AppException(this.code, this.message, {this.detail, this.statusCode, this.requestId});

  final String code;
  final String message;
  final Map<String, dynamic>? detail;
  final int? statusCode;
  final String? requestId;

  @override
  String toString() => 'AppException($code): $message';

  /// True when the caller should retry this request later (transient).
  bool get retryable => switch (statusCode) {
        429 || 500 || 502 || 503 || 504 => true,
        _ => false,
      };
}

/// No/invalid credentials, expired or revoked token.
class UnauthenticatedException extends AppException {
  const UnauthenticatedException(
    String message, {
    super.detail,
    super.statusCode,
    super.requestId,
  }) : super('UNAUTHENTICATED', message);
}

/// Missing permission (403 FORBIDDEN_ROLE) or disabled account.
class ForbiddenException extends AppException {
  const ForbiddenException(
    String message, {
    super.detail,
    super.statusCode,
    super.requestId,
  }) : super('FORBIDDEN_ROLE', message);
}

/// Resource outside the caller's geographic scope.
class ForbiddenScopeException extends AppException {
  const ForbiddenScopeException(
    String message, {
    super.detail,
    super.statusCode,
    super.requestId,
  }) : super('FORBIDDEN_SCOPE', message);
}

class NotFoundException extends AppException {
  const NotFoundException(
    String message, {
    super.detail,
    super.statusCode,
    super.requestId,
  }) : super('NOT_FOUND', message);
}

class ConflictException extends AppException {
  const ConflictException(
    String message, {
    super.detail,
    super.statusCode,
    super.requestId,
  }) : super('CONFLICT', message);
}

class ValidationException extends AppException {
  const ValidationException(
    String message, {
    super.detail,
    super.statusCode,
    super.requestId,
  }) : super('VALIDATION_ERROR', message);
}

class RateLimitedException extends AppException {
  const RateLimitedException(
    String message, {
    super.detail,
    super.statusCode,
    super.requestId,
  }) : super('RATE_LIMITED', message);
}

/// Could not reach the server / timeout / DNS.
class NetworkException extends AppException {
  const NetworkException(
    String message, {
    super.detail,
    super.statusCode,
    super.requestId,
  }) : super('NETWORK', message);
}

/// Server returned something we could not parse.
class ParsingException extends AppException {
  const ParsingException(
    String message, {
    super.detail,
    super.statusCode,
    super.requestId,
  }) : super('MALFORMED_RESPONSE', message);
}

/// Storage/secure-storage failure.
class StorageException extends AppException {
  const StorageException(
    String message, {
    super.detail,
    super.statusCode,
    super.requestId,
  }) : super('STORAGE', message);
}

/// Location permission/provisioning failure.
class LocationException extends AppException {
  const LocationException(
    String message, {
    super.detail,
    super.statusCode,
    super.requestId,
  }) : super('LOCATION', message);
}

/// Realtime (SSE) failure.
class RealtimeException extends AppException {
  const RealtimeException(
    String message, {
    super.detail,
    super.statusCode,
    super.requestId,
  }) : super('REALTIME', message);
}

/// Generic unexpected failure (5xx INTERNAL or unmapped).
class InternalException extends AppException {
  const InternalException(
    String message, {
    super.detail,
    super.statusCode,
    super.requestId,
  }) : super('INTERNAL', message);
}