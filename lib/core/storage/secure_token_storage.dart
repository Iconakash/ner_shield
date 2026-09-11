import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

/// Persists session tokens. On Android this uses the platform keystore /
/// EncryptedSharedPreferences (docs/security-plan.md).
///
/// Tokens are transient credentials: the backend re-auth window is ≤72h
/// (OFF-05), so we never cache them in plaintext shared prefs.
class SecureTokenStorage {
  SecureTokenStorage(this._storage, {this.useMemory = false}) : _memory = {};

  /// Selects the backend for the current platform.
  ///
  /// Native: keystore-backed `FlutterSecureStorage`
  /// (EncryptedSharedPreferences, docs/security-plan.md).
  /// Web / non-secure: in-memory store — the re-auth window is ≤72h (OFF-05) so
  /// we trade persistence for guaranteed, throw-free writes (flutter_secure_storage
  /// 9.x on web delegates to WebCrypto and can throw at runtime, which silently
  /// breaks the login → /auth/me chain).
  factory SecureTokenStorage.platform({bool useSecureStorage = true}) {
    final useMemory = kIsWeb || !useSecureStorage;
    if (useMemory) {
      AppLogger.instance.debug(
        'SecureTokenStorage: in-memory backend active (web / non-secure context)',
      );
    }
        return SecureTokenStorage(
      FlutterSecureStorage(
        aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      ),
      useMemory: useMemory,
    );
  }

  static const _kAccessToken = 'ner_access_token';
  static const _kRefreshToken = 'ner_refresh_token';
  static const _kUserId = 'ner_user_id';
  static const _kAccountEmail = 'ner_account_email';
  static const _kMfaSession = 'ner_mfa_session';

    final FlutterSecureStorage _storage;
  final bool useMemory;
  final Map<String, String> _memory;

  /// Unified write — in-memory map on web / disabled secure storage, keystore
  /// otherwise. Never throws for the in-memory backend.
    Future<void> _write(String key, String value) async {
    if (useMemory) {
      _memory[key] = value;
    } else {
      await _storage.write(key: key, value: value);
    }
  }

    Future<String?> _read(String key) async {
    if (useMemory) return _memory[key];
    try {
      return await _storage.read(key: key);
    } on Object {
      return null;
    }
  }

    Future<void> _delete(String key) async {
    if (useMemory) {
      _memory.remove(key);
    } else {
      await _storage.delete(key: key);
    }
  }

    Future<void> _deleteAll() async {
    if (useMemory) {
      _memory.clear();
    } else {
      await _storage.deleteAll();
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? userId,
    String? accountEmail,
  }) async {
    try {
      // Write access token last so a crash mid-write never leaves a
      // newer refresh token paired with the previous access token.
            if (refreshToken != null) {
        await _write(_kRefreshToken, refreshToken);
      }
      if (userId != null) {
        await _write(_kUserId, userId);
      }
      if (accountEmail != null) {
        await _write(_kAccountEmail, accountEmail);
      }
      await _write(_kAccessToken, accessToken);
    } on Object catch (e, s) {
      AppLogger.instance.error('failed to persist session', e, s);
      throw const StorageException('Could not secure-save your session.');
    }
  }

  Future<String?> get accessToken async {
    try {
            return await _read(_kAccessToken);
    } on Object {
      return null;
    }
  }

  Future<String?> get refreshToken async {
    try {
      return await _read(_kRefreshToken);
    } on Object {
      return null;
    }
  }

  Future<String?> get userId async {
    try {
      return await _read(_kUserId);
    } on Object {
      return null;
    }
  }

  Future<String?> get accountEmail async {
    try {
      return await _read(_kAccountEmail);
    } on Object {
      return null;
    }
  }

  /// First-factor (aal1) session marker while an MFA challenge is in flight.
  ///
  /// The current backend returns only `{"mfa_required": true}` at login, so
  /// this is usually a marker; when the backend returns a first-factor token,
  /// it is stored here and attached by the auth interceptor until MFA
  /// verification replaces the session.
    Future<void> saveMfaMarker(String marker) async {
    try {
      await _write(_kMfaSession, marker);
    } on Object catch (e, s) {
      AppLogger.instance.error('failed to persist MFA marker', e, s);
    }
  }

  Future<String?> get mfaMarker async {
    try {
            return await _read(_kMfaSession);
    } on Object {
      return null;
    }
  }

  Future<void> clearMfaMarker() async {
    try {
            await _delete(_kMfaSession);
    } on Object catch (e, s) {
      AppLogger.instance.error('failed to clear MFA marker', e, s);
    }
  }

  Future<void> clear() async {
        try {
      await _deleteAll();
    } on Object catch (e, s) {
      AppLogger.instance.error('failed to clear session', e, s);
      throw const StorageException('Could not clear your session.');
    }
  }

  Future<bool> get hasSession async {
    final token = await accessToken;
    final refresh = await refreshToken;
    return token != null || refresh != null;
  }
}