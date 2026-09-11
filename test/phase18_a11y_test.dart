import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations (Phase 18 l10n)', () {
    testWidgets('loads English strings from the ARB', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context);
              expect(l, isNotNull);
              expect(l.appTitle, 'NER-SHIELD');
              expect(l.authSignIn, isNotEmpty);
              expect(l.commonRetry, isNotEmpty);
              expect(l.dashboardTitle, isNotEmpty);
              expect(l.mapTitle, isNotEmpty);
              expect(l.alertsTitle, isNotEmpty);
              expect(l.shipmentsTitle, isNotEmpty);
              expect(l.riskTitle, isNotEmpty);
              expect(l.routingTitle, isNotEmpty);
              expect(l.historicalTitle, isNotEmpty);
              expect(l.tasksTitle, isNotEmpty);
              expect(l.emergencyTitle, isNotEmpty);
              expect(l.incidentsTitle, isNotEmpty);
              expect(l.notificationsPrefsTitle, isNotEmpty);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('Semantics exposure (Phase 18 a11y)', () {
    testWidgets('a labeled FilledButton exposes its label to Semantics',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () {},
                child: const Text('Save shipment'),
              ),
            ),
          ),
        ),
      );
      final sem = tester.getSemantics(find.text('Save shipment'));
      expect(sem.label, contains('Save shipment'));
      // Button role is exposed via the semantics flags collection; the
      // public API does not expose a hasFlag helper any more.
      expect(sem.toString(), contains('Save shipment'));
    });
  });
}