import 'package:freezed_annotation/freezed_annotation.dart';

part 'command_summary.freezed.dart';
part 'command_summary.g.dart';

/// One command-center KPI tile (id + count + the backend's frozen description).
@freezed
sealed class CommandKpi with _$CommandKpi {
  const factory CommandKpi({
    required String id,
    required int count,
    required String description,
  }) = _CommandKpi;

  factory CommandKpi.fromJson(Map<String, dynamic> json) =>
      _$CommandKpiFromJson(json);
}

/// `GET /command/summary` — the frozen six actionable, RLS-scoped KPI tiles.
///
/// Reference `backend/app/command/service.py::summary` returns a flat object:
/// `{critical_alerts, high_risk_roads, active_shipments, critical_shipments,
///   supply_risk_districts, predicted_disruptions, generated_at}`.
@freezed
sealed class CommandSummary with _$CommandSummary {
  const CommandSummary._();

  const factory CommandSummary({
    @Default(0) int criticalAlerts,
    @Default(0) int highRiskRoads,
    @Default(0) int activeShipments,
    @Default(0) int criticalShipments,
    @Default(0) int supplyRiskDistricts,
    @Default(0) int predictedDisruptions,
    String? generatedAt,
  }) = _CommandSummary;

  factory CommandSummary.fromJson(Map<String, dynamic> json) =>
      _$CommandSummaryFromJson(json);

  /// The frozen tile list — the dashboard renders EXACTLY these, in the
  /// backend's order, with the backend's descriptions (kpi_definitions()).
  List<CommandKpi> get kpis => [
        CommandKpi(
          id: 'critical_alerts',
          count: criticalAlerts,
          description: 'Open CRITICAL alerts awaiting action',
        ),
        CommandKpi(
          id: 'high_risk_roads',
          count: highRiskRoads,
          description: 'Road segments with latest risk HIGH/CRITICAL',
        ),
        CommandKpi(
          id: 'active_shipments',
          count: activeShipments,
          description: 'Shipments routed or in transit',
        ),
        CommandKpi(
          id: 'critical_shipments',
          count: criticalShipments,
          description: 'Active shipments carrying critical commodities',
        ),
        CommandKpi(
          id: 'supply_risk_districts',
          count: supplyRiskDistricts,
          description: 'Districts with recent shortage probability >= 55',
        ),
        CommandKpi(
          id: 'predicted_disruptions',
          count: predictedDisruptions,
          description: 'Districts currently flagged by the prediction engine',
        ),
      ];

  /// Number of tiles whose count is greater than zero (used for empty state).
  int get actionCount => kpis.where((k) => k.count > 0).length;
}