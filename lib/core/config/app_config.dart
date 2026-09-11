import 'package:flutter/foundation.dart';

/// Environment-agnostic client configuration.
///
/// Only CLIENT-SAFE values live here. Private secrets (service-role keys,
/// DB URLs, provider API keys) must never be compiled into the client —
/// see docs/security-plan.md. Overrides may be supplied via
/// `--dart-define=API_BASE_URL=...` etc.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.apiPublicUrl,
    this.outboundTileUrl =
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    this.env = AppEnv.dev,
    this.dataMode = DataMode.demo,
    this.useSecureStorage = true,
    this.httpConnectTimeout = const Duration(seconds: 12),
    this.httpReceiveTimeout = const Duration(seconds: 25),
    this.syncMaxBatch = 50,
  });

  /// FastAPI endpoint for all /api/v1/* calls.
  final String apiBaseUrl;

  /// Public origin (may be used for derived links / asset URLs).
  final String apiPublicUrl;

  /// OSM-compatible tile template URL (configurable/provider-swappable).
  final String outboundTileUrl;

  final AppEnv env;
  final DataMode dataMode;

  /// Whether access tokens are stored in the platform keystore.
  final bool useSecureStorage;

  final Duration httpConnectTimeout;
  final Duration httpReceiveTimeout;

  /// Maximum number of offline ops batched per /sync/push.
  final int syncMaxBatch;

  /// Convenience default: local development backend.
  ///
  /// - Android emulator: `http://10.0.2.2:8000` reaches the host loopback.
  /// - Desktop/test: `http://localhost:8000`.
  factory AppConfig.defaults() {
    const emulatorHost = String.fromEnvironment('API_BASE_URL');
    if (emulatorHost.isNotEmpty) {
      return AppConfig.fromEnvironment(envValue: emulatorHost);
    }
    final base = (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS)
        ? 'http://localhost:8000'
        : 'http://10.0.2.2:8000';
    return AppConfig.fromEnvironment(envValue: base, public: base);
  }

  /// Reads overrides from --dart-define and falls back to [base].
  factory AppConfig.fromEnvironment({
    String? envValue,
    String? public,
  }) {
    final base = envValue ??
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.0.2.2:8000',
        );
    final publicUrl = public ??
        const String.fromEnvironment(
          'API_PUBLIC_URL',
          defaultValue: 'http://10.0.2.2:8000',
        );
    final envName = const String.fromEnvironment('ENV', defaultValue: 'dev');
    final dataModeName = const String.fromEnvironment(
      'DATA_MODE',
      defaultValue: 'demo',
    );
    final useSecure = const bool.fromEnvironment(
      'USE_SECURE_STORAGE',
      defaultValue: true,
    );
    return AppConfig(
      apiBaseUrl: base,
      apiPublicUrl: publicUrl,
      env: AppEnv.values.firstWhere(
        (e) => e.name == envName,
        orElse: () => AppEnv.dev,
      ),
      dataMode: DataMode.values.firstWhere(
        (m) => m.name == dataModeName,
        orElse: () => DataMode.demo,
      ),
      useSecureStorage: useSecure,
    );
  }
}

enum AppEnv { dev, staging, prod }

enum DataMode {
  /// Demo/seed data from backend: server labels SIMULATED/DEMO — the UI must
  /// keep those badges visible, never strip them.
  demo,

  /// Authorized live data only.
  live,
}