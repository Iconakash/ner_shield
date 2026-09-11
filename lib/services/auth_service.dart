import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_responses.dart';
import '../core/storage/secure_token_storage.dart';

/// Session bundle returned by login.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
}

/// Result of POST /auth/login.
///
/// When the account has MFA enabled the backend returns only
/// `{"mfa_required": true}` (no tokens). The client then runs the challenge
/// → verify dance (documented contract: login → MFA_REQUIRED → challenge →
/// verify).
class LoginResult {
  const LoginResult({
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.mfaRequired = false,
    this.mfaMarker,
    this.accountEmail,
  });

  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final bool mfaRequired;

  /// First-factor session marker while MFA is pending (the reference backend
  /// currently passes `pending-mfa`; if it later returns an aal1 token it is
  /// preserved here).
  final String? mfaMarker;

  /// Email the credentials were submitted with (kept so MFA verify can
  /// associate the new session).
  final String? accountEmail;

  bool get hasSession => accessToken != null && accessToken!.isNotEmpty;
}

/// GET /auth/mfa/challenge payload.
class MfaChallenge {
  const MfaChallenge({
    required this.factorId,
    required this.challengeId,
    this.expiresAt,
  });

  final String factorId;
  final String challengeId;
  final String? expiresAt;

  factory MfaChallenge.fromJson(Map<String, dynamic> json) => MfaChallenge(
        factorId: json['factor_id'] as String,
        challengeId: json['challenge_id'] as String,
        expiresAt: json['expires_at'] as String?,
      );
}

/// Current authenticated principal (mirrors GET /auth/me).
class AppPrincipal {
  const AppPrincipal({
    required this.userId,
    required this.email,
    required this.role,
    this.orgId,
    this.language = 'en',
    this.scopes = const [],
    this.permissions = const {},
    this.fullName,
  });

  final String userId;
  final String email;
  final String role;
  final String? orgId;
  final String language;
  final List<GeoScope> scopes;
  final Set<String> permissions;
  final String? fullName;

  bool hasPermission(String permission) => permissions.contains(permission);

  bool hasAnyPermission(Iterable<String> required) =>
      required.any(permissions.contains);

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isRegionalAuthority => role == 'REGIONAL_AUTHORITY';
  bool get isDistrictOfficer => role == 'DISTRICT_OFFICER';
  bool get isLogisticsOfficer => role == 'LOGISTICS_OFFICER';
  bool get isFieldOfficer => role == 'FIELD_OFFICER';
  bool get isAnalystViewer => role == 'ANALYST_VIEWER';

  factory AppPrincipal.fromJson(Map<String, dynamic> json) {
    return AppPrincipal(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      orgId: json['org_id'] as String?,
      language: (json['language'] as String?) ?? 'en',
      scopes: ((json['scopes'] as List?) ?? const [])
          .map((s) => GeoScope.fromJson(s as Map<String, dynamic>))
          .toList(),
      permissions: ((json['permissions'] as List?) ?? const [])
          .map((p) => p as String)
          .toSet(),
    );
  }
}

class GeoScope {
  const GeoScope({required this.level, this.stateCode, this.districtCode});

  final String level;
  final String? stateCode;
  final String? districtCode;

  factory GeoScope.fromJson(Map<String, dynamic> json) => GeoScope(
        level: json['level'] as String,
        stateCode: json['state_code'] as String?,
        districtCode: json['district_code'] as String?,
      );
}

class AuthService {
  AuthService(this._dio, this._tokens);

  final Dio _dio;
  final SecureTokenStorage _tokens;

  /// POST /api/v1/auth/login (proxied Supabase password grant).
  ///
  /// Returns an MFA-required result without tokens when the account has a
  /// second factor (the backend does not leak the aal1 token); the caller must
  /// then run [mfaChallenge] → [mfaVerify].
  Future<LoginResult> login({required String email, required String password}) async {
    try {
      final res = await _dio.post<Object?>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final body = requireJsonObject(res);
      if (body['mfa_required'] == true) {
        final marker = (body['mfa_marker'] as String?) ?? 'pending-mfa';
        await _tokens.saveMfaMarker(marker);
        return LoginResult(
          mfaRequired: true,
          mfaMarker: marker,
          accountEmail: email,
        );
      }
      final token = body['access_token'];
      if (token is! String || token.isEmpty) {
        throw const ParsingException(
          'The server did not return a session token.',
        );
      }
      final session = AuthSession(
        accessToken: token,
        refreshToken: (body['refresh_token'] as String?) ?? '',
        expiresIn: (body['expires_in'] as num?)?.toInt() ?? 3600,
      );
      await _tokens.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        accountEmail: email,
      );
      return LoginResult(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        expiresIn: session.expiresIn,
        accountEmail: email,
      );
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /api/v1/auth/mfa/challenge — starts a TOTP challenge against the
  /// first-factor session. The backend reads the Authorization header it
  /// established at login; no role selection happens client-side.
  Future<MfaChallenge> mfaChallenge() async {
    try {
      final res = await _dio.get<Object?>('/auth/mfa/challenge');
      final body = requireJsonObject(res);
      try {
        return MfaChallenge.fromJson(body);
      } on TypeError {
        throw const ParsingException('MFA challenge was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// POST /api/v1/auth/mfa/verify — exchanges TOTP code for a full session.
  Future<void> mfaVerify({
    required String factorId,
    required String challengeId,
    required String code,
    String? accountEmail,
  }) async {
    try {
      final res = await _dio.post<Object?>(
        '/auth/mfa/verify',
        data: {'factor_id': factorId, 'challenge_id': challengeId, 'code': code},
      );
      final body = requireJsonObject(res);
      final token = body['access_token'];
      if (token is! String || token.isEmpty) {
        throw const ParsingException(
          'MFA verification did not return a session token.',
        );
      }
      await _tokens.saveTokens(
        accessToken: token,
        refreshToken: (body['refresh_token'] as String?) ?? '',
        accountEmail: accountEmail,
      );
      await _tokens.clearMfaMarker();
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /api/v1/auth/me — returns role/scopes/permissions (server truth).
  Future<AppPrincipal> me() async {
    try {
      final res = await _dio.get<Object?>('/auth/me');
      final body = requireJsonObject(res);
      try {
        return AppPrincipal.fromJson(body);
      } on TypeError {
        throw const ParsingException('The session profile was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// POST /api/v1/auth/logout — revokes server-side; then clears local.
  Future<void> logout() async {
    try {
      await _dio.post<Map<String, dynamic>>('/auth/logout');
    } on AppException {
      // Still clear local even if the server call failed — better to be
      // safely logged out locally than stuck.
    } on DioException {
      // Same policy: best-effort server revoke.
    }
    await _tokens.clear();
  }
}