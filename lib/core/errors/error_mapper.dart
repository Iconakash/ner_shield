import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../errors/app_exception.dart';

/// Maps transport/Dio errors to the [AppException] tree and produces
/// user-friendly messages (no raw stack traces in the UI).
class ErrorMapper {
  const ErrorMapper();

  /// Parse the backend error envelope body into an [AppException].
  static AppException fromEnvelope(
    int status,
    Map<String, dynamic>? body, {
    String? requestId,
  }) {
    final error = (body?['error'] as Map<String, dynamic>?) ?? const {};
    final code = (error['code'] as String?) ?? 'INTERNAL';
    final message = (error['message'] as String?) ?? defaultMessageFor(status);
    final detail = error['detail'] as Map<String, dynamic>?;
    final rid = (error['request_id'] as String?) ?? requestId;

    switch (code) {
      case 'UNAUTHENTICATED':
        return UnauthenticatedException(message, detail: detail, statusCode: status, requestId: rid);
      case 'FORBIDDEN_ROLE':
        return ForbiddenException(message, detail: detail, statusCode: status, requestId: rid);
      case 'FORBIDDEN_SCOPE':
        return ForbiddenScopeException(message, detail: detail, statusCode: status, requestId: rid);
      case 'NOT_FOUND':
        return NotFoundException(message, detail: detail, statusCode: status, requestId: rid);
      case 'CONFLICT':
        return ConflictException(message, detail: detail, statusCode: status, requestId: rid);
      case 'VALIDATION_ERROR':
        return ValidationException(message, detail: detail, statusCode: status, requestId: rid);
      case 'RATE_LIMITED':
        return RateLimitedException(message, detail: detail, statusCode: status, requestId: rid);
      default:
        return InternalException(message, detail: detail, statusCode: status, requestId: rid);
    }
  }

  /// Convert a thrown [Object] (DioException, SocketException, ...) into an
  /// [AppException] with a stable code.
  static AppException from(Object? error) {
    if (error is AppException) return error;
    if (error is DioException) return _fromDio(error);
    if (error is FormatException) {
      return const ParsingException('The server returned an unreadable response.');
    }
    if (error == null) {
      return const InternalException('Something went wrong. Please try again.');
    }
    return InternalException('Something went wrong. Please try again.');
  }

  static AppException _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException('The server is taking too long to respond.');
      case DioExceptionType.connectionError:
        return const NetworkException('Cannot reach the server. Check your connection.');
      case DioExceptionType.badCertificate:
        return const NetworkException('The server certificate could not be verified.');
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 500;
        final data = e.response?.data;
        return fromEnvelope(
          status,
          data is Map<String, dynamic> ? data : null,
        );
      case DioExceptionType.cancel:
        return const NetworkException('The request was cancelled.');
      case DioExceptionType.unknown:
        return from(e.error);
    }
  }

  static String defaultMessageFor(int status) {
    return switch (status) {
      400 => 'The request was invalid.',
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You do not have permission to do that.',
      404 => 'The requested item was not found.',
      409 => 'That action conflicts with the current state.',
      422 => 'Some of the information provided was not valid.',
      429 => 'Too many requests. Please wait a moment.',
      _ => 'Something went wrong on the server.',
    };
  }

  /// Classify current connectivity into the backend's connectivity classes
  /// (docs/offline-strategy.md). Empty/unknown → OFFLINE.
  static String connectivityClass(List<ConnectivityResult> results) {
    if (results.isEmpty) return 'OFFLINE';
    final best = results.reduce((a, b) => a.index > b.index ? a : b);
    // No fine-grained bandwidth estimate available from connectivity_plus;
    // we map types to the sync policy classes conservatively.
    return switch (best) {
      ConnectivityResult.wifi => 'GOOD',
      ConnectivityResult.ethernet => 'EXCELLENT',
      ConnectivityResult.mobile => 'GOOD',
      ConnectivityResult.vpn => 'GOOD',
      ConnectivityResult.bluetooth => 'WEAK',
      ConnectivityResult.none => 'OFFLINE',
      _ => 'OFFLINE',
    };
  }
}