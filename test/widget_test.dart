import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ner_shield/app/app.dart';
import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/core/errors/error_mapper.dart';
import 'package:ner_shield/features/auth/login_screen.dart';
import 'package:ner_shield/features/landing/landing_screen.dart';

void main() {
  group('ErrorMapper', () {
    test('maps backend envelope 401 to UnauthenticatedException', () {
      final e = ErrorMapper.fromEnvelope(401, {
        'error': {'code': 'UNAUTHENTICATED', 'message': 'invalid credentials'},
      });
      expect(e, isA<UnauthenticatedException>());
      expect(e.message, 'invalid credentials');
    });

    test('unknown error maps to InternalException', () {
      final e = ErrorMapper.from(StateError('boom'));
      expect(e, isA<InternalException>());
    });

    test('format errors become ParsingException', () {
      final e = ErrorMapper.from(FormatException('x'));
      expect(e, isA<ParsingException>());
    });
  });

  group('App bootstrap', () {
    testWidgets('app boots and shows landing when signed out',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: NerShieldApp()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LandingScreen), findsOneWidget);
      expect(find.text('NER-SHIELD'), findsWidgets);
    });

    testWidgets('login screen renders form', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );
      await tester.pump();
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Sign in'), findsOneWidget);
    });
  });
}