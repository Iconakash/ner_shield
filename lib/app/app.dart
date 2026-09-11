import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/realtime/reconnection_reconciler.dart';
import '../routing/app_router.dart';
import '../theme/app_theme.dart';

/// Root application widget. Owns the ProviderScope state (via main) and the
/// MaterialApp.router which wires the theme and navigation.
///
/// Phase 11 — also mounts the reconciliation coordinator once for the whole
/// app lifetime (reconnect/session-restored listeners are lazy in Riverpod:
/// a provider only runs when something reads it) and forwards app-resume
/// events so offline queue flush + cache refresh happen when the officer
/// returns to the app (master prompt §1.4, §11).
class NerShieldApp extends ConsumerStatefulWidget {
  const NerShieldApp({super.key});

  @override
  ConsumerState<NerShieldApp> createState() => _NerShieldAppState();
}

class _NerShieldAppState extends ConsumerState<NerShieldApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Mounting registers the coordinator's connectivity/session listeners.
    // Nothing is reconciled here — triggers are event-driven.
    ref.read(reconciliationCoordinatorProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(reconciliationCoordinatorProvider).onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'NER-SHIELD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('as'),
        Locale('mni'),
      ],
    );
  }
}