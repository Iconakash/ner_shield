import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/status_chip.dart';
import '../alerts/alerts_screen.dart';
import '../auth/auth_controller.dart';
import '../dashboard/dashboard_screen.dart';
import '../emergency/emergency_screen.dart';
import '../historical/historical_screen.dart';
import '../incidents/reports_screen.dart';
import '../maps/map_screen.dart';
import '../predictions/risk_screen.dart';
import '../routing/route_planner_screen.dart';
import '../shipments/shipments_screen.dart';
import '../tasks/tasks_screen.dart';

/// Role-aware application shell (docs/ui-ux-plan.md §role shell).
///
/// The shell derives its sections from the server-provided role/scopes. This
/// is a *display* layer — the backend remains the enforceable authority.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, this.focusId});

  /// The active shell section path segment (e.g. `dashboard`, `map`).
  final String location;

  /// Deep-link focus id (`?focus=...`) forwarded to the section screen so a
  /// notification tap can highlight/auto-open a row.
  final String? focusId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final principal = auth?.principal;
    if (principal == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final sections = _sectionsFor(principal.role);
    final index = _indexFor(sections, location);
    final active = index < 0 ? 0 : index;
    final activeSection = sections[active];
    final focus = focusId;

    final Widget body;
    // Deep-link focus targets render their sections with the focus forwarded
    // (the screens auto-open the matching row once data is available).
    if (focus != null && focus.isNotEmpty && activeSection.id == 'alerts') {
      body = AlertsScreen(focusId: focus);
    } else if (focus != null &&
        focus.isNotEmpty &&
        activeSection.id == 'shipments') {
      body = ShipmentsScreen(focusId: focus);
    } else {
      body = activeSection.builder(context, principal);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('NER-SHIELD · ${principal.role.replaceAll('_', ' ')}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: StatusChip(
                label: principal.language.toUpperCase(),
                icon: Icons.language,
                color: const Color(0xFF00639C),
                dense: true,
              ),
            ),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: active,
        onDestinationSelected: (i) => context.go('/shell/${sections[i].id}'),
        destinations: [
          for (final s in sections)
            NavigationDestination(icon: Icon(s.icon), label: s.label),
        ],
      ),
    );
  }

  int _indexFor(List<ShellSection> sections, String location) {
    final i = sections.indexWhere((s) => s.id == location);
    return i < 0 ? 0 : i;
  }

  List<ShellSection> _sectionsFor(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
      case 'REGIONAL_AUTHORITY':
        return const [
          ShellSection(
              'dashboard', 'Command', Icons.dashboard_outlined, _buildDashboard),
          ShellSection('map', 'Map', Icons.map_outlined, _buildMap),
          ShellSection('risk', 'Risk', Icons.insights_outlined, _buildRisk),
          ShellSection(
              'alerts', 'Alerts', Icons.notifications_outlined, _buildAlerts),
          ShellSection(
              'historical', 'Historical', Icons.history, _buildHistorical),
          ShellSection('profile', 'Profile', Icons.person_outline),
        ];
      case 'DISTRICT_OFFICER':
      case 'LOGISTICS_OFFICER':
        return const [
          ShellSection(
              'dashboard', 'Overview', Icons.dashboard_outlined, _buildDashboard),
          ShellSection('map', 'Map', Icons.map_outlined, _buildMap),
          ShellSection(
              'routing', 'Routing', Icons.alt_route_outlined, _buildRouting),
          ShellSection('shipments', 'Logistics', Icons.local_shipping_outlined,
              _buildShipments),
          ShellSection('risk', 'Risk', Icons.insights_outlined, _buildRisk),
          ShellSection(
              'alerts', 'Alerts', Icons.notifications_outlined, _buildAlerts),
          ShellSection(
              'tasks', 'Tasks', Icons.task_alt_outlined, _buildTasks),
          ShellSection(
              'emergency', 'Emergency', Icons.emergency_outlined, _buildEmergency),
          ShellSection('profile', 'Profile', Icons.person_outline),
        ];
      case 'FIELD_OFFICER':
        return const [
          ShellSection(
              'dashboard', 'Overview', Icons.dashboard_outlined, _buildDashboard),
          ShellSection('map', 'Map', Icons.map_outlined, _buildMap),
          ShellSection(
              'reports', 'Reports', Icons.campaign_outlined, _buildReports),
          ShellSection(
              'alerts', 'Alerts', Icons.notifications_outlined, _buildAlerts),
          ShellSection('profile', 'Profile', Icons.person_outline),
        ];
      default:
        return const [
          ShellSection(
              'dashboard', 'Command', Icons.dashboard_outlined, _buildDashboard),
          ShellSection('map', 'Map', Icons.map_outlined, _buildMap),
          ShellSection('risk', 'Risk', Icons.insights_outlined, _buildRisk),
          ShellSection(
              'alerts', 'Alerts', Icons.notifications_outlined, _buildAlerts),
          ShellSection(
              'historical', 'Historical', Icons.history, _buildHistorical),
          ShellSection('profile', 'Profile', Icons.person_outline),
        ];
    }
  }
}

/// Const tear-off adapter: the dashboard needs no principal input (the
/// backend scopes everything to the caller's RLS geography).
Widget _buildDashboard(BuildContext context, dynamic principal) =>
    const DashboardScreen();

/// Const tear-off adapter: the map screen likewise needs no principal input
/// (every layer is RLS-scoped server-side).
Widget _buildMap(BuildContext context, dynamic principal) => const MapScreen();

/// Const tear-off adapter: the field officer's reports inbox (Phase 9).
Widget _buildReports(BuildContext context, dynamic principal) =>
    const ReportsScreen();

/// Const tear-off adapter: the route planner (Phase 10).
Widget _buildRouting(BuildContext context, dynamic principal) =>
    const RoutePlannerScreen();

/// Const tear-off adapter: the shipments console (Phase 11). Every row is
/// RLS-scoped server-side; the client renders what the backend returns.
Widget _buildShipments(BuildContext context, dynamic principal) =>
    const ShipmentsScreen();

/// Const tear-off adapter: the alerts inbox (Phase 12). Available to every
/// role — individual alert visibility is permission-filtered server-side.
Widget _buildAlerts(BuildContext context, dynamic principal) =>
    const AlertsScreen();

/// Const tear-off adapter: the risk/prediction view (Phase 13) — display-only
/// presentation of backend ML output (master prompt §32: no client ML).
Widget _buildRisk(BuildContext context, dynamic principal) =>
    const RiskScreen();

/// Const tear-off adapter: historical validation analytics (Phase 14).
Widget _buildHistorical(BuildContext context, dynamic principal) =>
    const HistoricalScreen();

/// Const tear-off adapter: emergency response tasks (Phase 15).
Widget _buildEmergency(BuildContext context, dynamic principal) =>
    const EmergencyScreen();

/// Const tear-off adapter: action-center tasks (Phase 16).
Widget _buildTasks(BuildContext context, dynamic principal) =>
    const TasksScreen();

/// One shell section: id + nav label + icon + optional real screen builder.
class ShellSection {
  const ShellSection(this.id, this.label, this.icon, [this.screen]);

  final String id;
  final String label;
  final IconData icon;

  /// Real feature screen for this section, when implemented. Real feature
  /// screens replace [SectionPlaceholder] as phases land.
  final Widget Function(BuildContext context, dynamic principal)? screen;

  /// Renders the destination screen for this section.
  Widget builder(BuildContext context, dynamic principal) {
    final real = screen;
    if (real != null) return real(context, principal);
    return SectionPlaceholder(title: '$label (in development)');
  }
}

/// Temporary placeholder for sections whose feature screen is not yet
/// implemented. Must never present fake data (docs/security-plan.md).
class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'This section is being implemented.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}