import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/core/logging/app_logger.dart';

void main() {
  group('AppLogger redaction (Phase 19 security)', () {
    test('redacts authorization header value', () {
      final out = AppLogger.redact(
        'Authorization: Bearer abc.def.ghi sent',
      );
      expect(out, contains('[REDACTED]'));
      expect(out, isNot(contains('Bearer abc.def')));
    });

    test('redacts password field', () {
      final out = AppLogger.redact('password=hunter2');
      expect(out, contains('[REDACTED]'));
      expect(out, isNot(contains('hunter2')));
    });

    test('redacts api_key', () {
      final out = AppLogger.redact('api_key=sk_live_XYZ');
      expect(out, contains('[REDACTED]'));
      expect(out, isNot(contains('sk_live_XYZ')));
    });

    test('redacts service_role_key', () {
      final out = AppLogger.redact('service_role_key=service-XYZ');
      expect(out, contains('[REDACTED]'));
      expect(out, isNot(contains('service-XYZ')));
    });

    test('passes through benign strings', () {
      final out = AppLogger.redact('Loading dashboard tiles');
      expect(out, 'Loading dashboard tiles');
    });
  });

  group('Secrets surface in build output', () {
    test('.gitignore blocks .env files', () async {
      final f = File('.gitignore');
      final content = await f.readAsString();
      expect(content, contains('.env'));
    });

    test('.env.example contains no obvious secrets', () async {
      final f = File('.env.example');
      if (!await f.exists()) return;
      final content = await f.readAsString();
      for (final line in content.split('\n')) {
        if (line.startsWith('#') || line.trim().isEmpty) continue;
        if (!line.contains('=')) continue;
        final value = line.split('=').last.trim();
        if (value.isEmpty) continue;
        expect(value.contains('sk_live_'), isFalse);
        expect(value.contains('Bearer '), isFalse);
      }
    });
  });
}

