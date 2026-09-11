import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ner_shield/app/providers.dart';
import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/core/network/api_client.dart';
import 'package:ner_shield/core/storage/secure_token_storage.dart';
import 'package:ner_shield/features/auth/auth_controller.dart';
import 'package:ner_shield/features/auth/login_screen.dart';
import 'package:ner_shield/services/auth_service.dart';

/// Phase 4 gate (master prompt §16, tests T1-T5): login contract (incl. MFA),
/// challenge/verify dance, session expiry handling, and the auth controller
/// + login screen MFA step.
void main() {
  group('T1 — AuthService.login contract', () {
    test('mfa_required response keeps the marker and returns no session',
        () async {
      final tokens = _stubTokens();
      final dio = _dioWith(_jsonMap({'mfa_required': true}));
      final service = AuthService(dio, tokens);

      final result = await service.login(email: 'a@b.c', password: 'secret');

      expect(result.mfaRequired, isTrue);
      expect(result.hasSession, isFalse);
      verify(() => tokens.saveMfaMarker('pending-mfa')).called(1);
      verifyNever(() => tokens.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
          accountEmail: any(named: 'accountEmail')));
    });

    test('full session response persists tokens', () async {
      final tokens = _stubTokens();
      final dio = _dioWith(_jsonMap({
        'access_token': 'at1',
        'refresh_token': 'rt1',
        'expires_in': 3600,
      }));
      final service = AuthService(dio, tokens);

      final result = await service.login(email: 'a@b.c', password: 'secret');

      expect(result.hasSession, isTrue);
      expect(result.accessToken, 'at1');
      verify(() => tokens.saveTokens(
          accessToken: 'at1',
          refreshToken: 'rt1',
          accountEmail: 'a@b.c')).called(1);
    });

    test('missing access token raises ParsingException', () async {
      final tokens = _stubTokens();
      final dio = _dioWith(_jsonMap({'refresh_token': 'rt'}));
      final service = AuthService(dio, tokens);

      expect(
        () => service.login(email: 'a@b.c', password: 'secret'),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('T2 — MFA challenge + verify', () {
    test('mfaChallenge parses factor/challenge ids', () async {
      final tokens = _stubTokens();
      final dio = _dioWith(_jsonMap({
        'factor_id': 'fac1',
        'challenge_id': 'chal1',
        'expires_at': '2030-01-01T00:00:00Z',
      }));
      final service = AuthService(dio, tokens);

      final challenge = await service.mfaChallenge();

      expect(challenge.factorId, 'fac1');
      expect(challenge.challengeId, 'chal1');
    });

    test('mfaVerify persists session and clears the marker', () async {
      final tokens = _stubTokens();
      final dio = _dioWith(_jsonMap({
        'access_token': 'at2',
        'refresh_token': 'rt2',
        'expires_in': 3600,
      }));
      final service = AuthService(dio, tokens);

      await service.mfaVerify(
        factorId: 'fac1',
        challengeId: 'chal1',
        code: '123456',
        accountEmail: 'a@b.c',
      );

      verify(() => tokens.saveTokens(
          accessToken: 'at2',
          refreshToken: 'rt2',
          accountEmail: 'a@b.c')).called(1);
      verify(() => tokens.clearMfaMarker()).called(1);
    });
  });

  group('T3 — AuthController sign-in state machine', () {
    test('MFA-required login moves to mfa state and returns false', () async {
      final service = _MockAuthService();
      when(() => service.login(
              email: any(named: 'email'),
              password: any(named: 'password')))
          .thenAnswer((_) async => const LoginResult(mfaRequired: true));

      final container = ProviderContainer(overrides: [
        authServiceProvider.overrideWithValue(service),
        secureTokenStorageProvider.overrideWithValue(_stubTokens()),
      ]);
      addTearDown(container.dispose);

      final authenticated = await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@b.c', password: 'secret');

      expect(authenticated, isFalse);
      final state = container.read(authControllerProvider).valueOrNull;
      expect(state?.mfaPending, isTrue);
      verifyNever(() => service.me());
    });

    test('non-MFA login resolves principal and returns true', () async {
      final service = _MockAuthService();
      when(() => service.login(
              email: any(named: 'email'),
              password: any(named: 'password')))
          .thenAnswer((_) async => const LoginResult(
              accessToken: 'at', refreshToken: 'rt', expiresIn: 3600));
      when(() => service.me()).thenAnswer((_) async => _principal());

      final container = ProviderContainer(overrides: [
        authServiceProvider.overrideWithValue(service),
        secureTokenStorageProvider.overrideWithValue(_stubTokens()),
      ]);
      addTearDown(container.dispose);

      final ok = await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@b.c', password: 'secret');

      expect(ok, isTrue);
      expect(container.read(authControllerProvider).valueOrNull?.principal?.role,
          'DISTRICT_OFFICER');
    });
  });
group('T3b — verifyMfa flow', () {
    test('verifyMfa runs challenge → verify → me', () async {
      final service = _MockAuthService();
      when(() => service.login(
              email: any(named: 'email'),
              password: any(named: 'password')))
          .thenAnswer((_) async => const LoginResult(mfaRequired: true));
      when(() => service.mfaChallenge())
          .thenAnswer((_) async => const MfaChallenge(
              factorId: 'fac1', challengeId: 'chal1'));
      when(() => service.mfaVerify(
              factorId: any(named: 'factorId'),
              challengeId: any(named: 'challengeId'),
              code: any(named: 'code'),
              accountEmail: any(named: 'accountEmail')))
          .thenAnswer((_) async {});
      when(() => service.me()).thenAnswer((_) async => _principal());

      final tokens = _stubTokens();
      when(() => tokens.accountEmail).thenAnswer((_) async => 'a@b.c');

      final container = ProviderContainer(overrides: [
        authServiceProvider.overrideWithValue(service),
        secureTokenStorageProvider.overrideWithValue(tokens),
      ]);
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@b.c', password: 'secret');
      await container
          .read(authControllerProvider.notifier)
          .verifyMfa(code: '123456');

      final state = container.read(authControllerProvider).valueOrNull;
      expect(state?.isAuthenticated, isTrue);
      verify(() => service.mfaChallenge()).called(1);
      verify(() => service.mfaVerify(
              factorId: 'fac1',
              challengeId: 'chal1',
              code: '123456',
              accountEmail: 'a@b.c'))
          .called(1);
    });

    test('verifyMfa without a pending challenge rejects', () async {
      final service = _MockAuthService();
      when(() => service.me()).thenAnswer((_) async => _principal());
      final container = ProviderContainer(overrides: [
        authServiceProvider.overrideWithValue(service),
        secureTokenStorageProvider.overrideWithValue(_stubTokens()),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(authControllerProvider.notifier).verifyMfa(code: '123456'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('T4 — session expiry handling', () {
    test('SessionExpiryInterceptor fires the handler on a 401 response',
        () async {
      var calls = 0;
      final dio = Dio(BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (status) => status != null && status < 500,
      ));
      dio.httpClientAdapter = _QueueAdapter([
        _jsonMap({
          'error': {'code': 'UNAUTHENTICATED', 'message': 'expired'},
        },
            status: 401),
      ]);
      dio.interceptors.add(SessionExpiryInterceptor(() async => calls++));

      final res = await dio.get<Object?>('/protected');

      expect(res.statusCode, 401);
      expect(calls, 1);
    });

    test('controller.expire clears a resolved session', () async {
      final service = _MockAuthService();
      when(() => service.login(
              email: any(named: 'email'),
              password: any(named: 'password')))
          .thenAnswer((_) async => const LoginResult(
              accessToken: 'at', refreshToken: 'rt', expiresIn: 3600));
      when(() => service.me()).thenAnswer((_) async => _principal());
      final tokens = _stubTokens(access: 'at');

      final container = ProviderContainer(overrides: [
        authServiceProvider.overrideWithValue(service),
        secureTokenStorageProvider.overrideWithValue(tokens),
      ]);
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@b.c', password: 'secret');
      expect(
          container.read(authControllerProvider).valueOrNull?.isAuthenticated,
          isTrue);

      await container.read(authControllerProvider.notifier).expire();

      expect(
          container.read(authControllerProvider).valueOrNull?.isAuthenticated,
          isFalse);
      verify(() => tokens.clear()).called(1);
    });
  });
group('T5 — login screen MFA step', () {
    testWidgets('renders the TOTP step when MFA is pending', (tester) async {
      final container = ProviderContainer(overrides: [
        authControllerProvider.overrideWith(() => _MfaPendingController()),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LoginScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Two-factor verification'), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);
      expect(find.text('Use a different account'), findsOneWidget);
    });
  });
}

AppPrincipal _principal() => const AppPrincipal(
      userId: 'u1',
      email: 'a@b.c',
      role: 'DISTRICT_OFFICER',
      language: 'en',
      scopes: [GeoScope(level: 'state', stateCode: 'IN-AS')],
    );

class _MockTokens extends Mock implements SecureTokenStorage {}

_MockTokens _stubTokens({String? access}) {
  final t = _MockTokens();
  when(() => t.saveMfaMarker(any())).thenAnswer((_) async {});
  when(() => t.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
          accountEmail: any(named: 'accountEmail')))
      .thenAnswer((_) async {});
  when(() => t.clearMfaMarker()).thenAnswer((_) async {});
  when(() => t.clear()).thenAnswer((_) async {});
  when(() => t.hasSession).thenAnswer((_) async => access != null);
  when(() => t.accessToken).thenAnswer((_) async => access);
  when(() => t.refreshToken).thenAnswer((_) async => null);
  when(() => t.userId).thenAnswer((_) async => null);
  when(() => t.accountEmail).thenAnswer((_) async => null);
  when(() => t.mfaMarker).thenAnswer((_) async => null);
  return t;
}

class _MockAuthService extends Mock implements AuthService {}

class _MfaPendingController extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.mfa();
}

Dio _dioWith(ResponseBody body) {
  final dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'));
  dio.httpClientAdapter = _QueueAdapter([body]);
  return dio;
}

ResponseBody _jsonMap(
  Map<String, dynamic> body, {
  int status = 200,
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {'content-type': ['application/json']},
  );
}

/// Minimal sequential-response adapter (dio's HttpClientAdapter contract).
class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter(this._bodies);

  final List<ResponseBody> _bodies;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_bodies.length > 1) return _bodies.removeAt(0);
    return _bodies.first;
  }

  @override
  void close({bool force = false}) {}
}