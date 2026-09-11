import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';
import '../storage/secure_token_storage.dart';

/// Provides a single, configured [Dio] instance.
///
/// - baseUrl from [AppConfig]
/// - Bearer injection from the [SecureTokenStorage]
/// - safe logging (headers redacted)
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokens = ref.watch(secureTokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: '${config.apiBaseUrl}/api/v1',
      connectTimeout: config.httpConnectTimeout,
      receiveTimeout: config.httpReceiveTimeout,
      sendTimeout: config.httpConnectTimeout,
      validateStatus: (status) => status != null && status < 500,
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(tokens),
    SessionExpiryInterceptor(
      () => ref.read(sessionExpiryHandlerProvider)?.call() ?? Future.value(),
    ),
    LogInterceptor(
      requestBody: false,
      responseBody: false,
      requestHeader: false,
      responseHeader: false,
      error: true,
      logPrint: (o) => AppLogger.instance.debug(AppLogger.redact('$o')),
    ),
  ]);

  ref.onDispose(dio.close);
  return dio;
});

/// Injects `Authorization: Bearer <access_token>` when present.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens);

  final SecureTokenStorage _tokens;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      // MFA first-factor sessions may carry a marker while a challenge is in
      // flight (the aal1 session lives server-side in the proxy).
      final marker = await _tokens.mfaMarker;
      if (marker != null && marker.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $marker';
      }
    }
    handler.next(options);
  }
}

/// Observes 401 responses on the shared Dio and invokes the global
/// session-expiry handler (single-flight; no infinite retry loops).
///
/// `dioProvider` validates status < 500, so 401s arrive here as normal
/// responses — guarding them here keeps every service's error mapping intact
/// while still reacting globally to session revocation/expiry.
class SessionExpiryInterceptor extends Interceptor {
  SessionExpiryInterceptor(this._onExpired);

  final Future<void> Function() _onExpired;
  bool _handling = false;

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (response.statusCode == 401 && !_handling) {
      _handling = true;
      try {
        await _onExpired();
      } finally {
        _handling = false;
      }
    }
    handler.next(response);
  }
}