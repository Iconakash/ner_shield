import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

/// Landing experience — brand, value props, sign-in CTA. Built entirely in
/// Flutter (no HTML/CSS/JS), docs/feature-phases §20.
class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand mark
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.shield_outlined, size: 44, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'NER-SHIELD',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Smart Logistics & Accessibility Intelligence',
                    style: theme.textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'North Eastern Region of India',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.outline),
                  ),
                  const SizedBox(height: 32),
                  const LandingFeature(
                    icon: Icons.route_outlined,
                    title: 'Live road accessibility',
                    subtitle: 'Open, partially open, blocked and unknown road states across all 8 NER states.',
                  ),
                  const SizedBox(height: 14),
                  const LandingFeature(
                    icon: Icons.insights_outlined,
                    title: 'AI disruption prediction',
                    subtitle: 'Explained risk scores with contributing factors and historical trends.',
                  ),
                  const SizedBox(height: 14),
                  const LandingFeature(
                    icon: Icons.my_location_outlined,
                    title: 'Field-first & offline',
                    subtitle: 'Geo-tagged incident reports that survive low connectivity with reliable sync.',
                  ),
                  const SizedBox(height: 14),
                  const LandingFeature(
                    icon: Icons.local_shipping_outlined,
                    title: 'Logistics & convoys',
                    subtitle: 'Shipment tracking, predictive ETA and risk-aware alternative routes.',
                  ),
                  const SizedBox(height: 36),
                  FilledButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Authorized personnel only',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LandingFeature extends StatelessWidget {
  const LandingFeature({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}