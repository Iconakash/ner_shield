// Phase 6 — OFFLINE risk degradation model (master prompt §6).
//
// The server risk engine stays the ONLY source of scores. Offline, the app
// serves the last synchronised server snapshot and NEVER presents it as live:
// every result carries its original `computed_at`, the local `fetched_at` and
// an explicit freshness/confidence/degraded labelling.

import '../../models/risk_item.dart';

/// Freshness bands for the offline risk snapshot (feature age at the model
/// run instant, `computed_at`). Mirrors the backend data-health vocabulary.
enum RiskFreshness {
  /// Model run within the last 30 minutes.
  live,
  /// Model run within the last 6 hours.
  recent,
  /// Older than 6 hours — must be labelled stale in the UI.
  stale,
}

/// A locally-persisted risk snapshot with explicit degradation metadata.
///
/// `predictions` are byte-for-byte the last server-fused rows. `computedAt`
/// is when the server model produced them; `fetchedAt` is when THIS device
/// last synchronised them. The two ages let the UI say precisely how stale
/// the feature snapshot is without ever suggesting live data.
class OfflineRiskResult {
  const OfflineRiskResult({
    required this.predictions,
    required this.fetchedAt,
    required this.computedAt,
    required this.stale,
    required this.featureFreshness,
    required this.confidence,
    required this.degradedReasons,
  });

  final List<RiskPrediction> predictions;
  /// Local sync instant (survives restart — the authoritative label).
  final DateTime fetchedAt;
  /// Server model-run instant (feature snapshot age).
  final DateTime? computedAt;
  /// True when the snapshot is older than the freshness budget.
  final bool stale;
  final RiskFreshness featureFreshness;
  /// 0..1 — decays with snapshot age (never fabricates a fresh confidence).
  final double confidence;
  /// User-safe reasons shown next to the degraded banner.
  final List<String> degradedReasons;

  /// This snapshot was produced from the last successful server sync.
  bool get servedFromCache => true;
}

/// Default freshness budget for offline risk (§6.2).
const Duration defaultRiskStaleAfter = Duration(hours: 6);

/// Computes the [RiskFreshness] band for a snapshot age (feature age).
RiskFreshness classifyRiskFreshness(Duration age) {
  if (age <= const Duration(minutes: 30)) return RiskFreshness.live;
  if (age <= const Duration(hours: 6)) return RiskFreshness.recent;
  return RiskFreshness.stale;
}

/// Confidence that decays with age: 1.0 fresh → 0.5 at 6h → 0.1 at 48h.
/// Deterministic and monotonic — a snapshot never gains confidence by aging.
/// The result is clamped to [0.1, 1.0] so floating-point drift at the
/// boundaries can never leave the documented band.
double riskConfidenceFor(Duration age) {
  final hours = age.inMinutes / 60.0;
  final double c;
  if (hours <= 0.5) {
    c = 1.0;
  } else if (hours <= 6) {
    c = 1.0 - 0.5 * (hours - 0.5) / 5.5;
  } else if (hours <= 48) {
    c = 0.5 - 0.4 * (hours - 6) / 42;
  } else {
    c = 0.1;
  }
  return c.clamp(0.1, 1.0).toDouble();
}

/// Builds the degraded result from a stored snapshot.
OfflineRiskResult buildOfflineRiskResult({
  required List<RiskPrediction> predictions,
  required DateTime fetchedAt,
  required DateTime? computedAt,
  Duration staleAfter = defaultRiskStaleAfter,
  DateTime? now,
}) {
  final wall = now ?? DateTime.now().toUtc();
  final featureAge = wall.difference(computedAt ?? fetchedAt);
  final freshness = classifyRiskFreshness(featureAge);
  final reasons = <String>[];
  if (freshness != RiskFreshness.live) {
    reasons.add('Risk scores are ${freshness.name} — model ran '
        '${_humanAge(featureAge)}. Verify against the server when online.');
  }
  if (predictions.isEmpty) {
    reasons.add('No segment predictions are cached for this device.');
  }
  return OfflineRiskResult(
    predictions: predictions,
    fetchedAt: fetchedAt,
    computedAt: computedAt,
    stale: featureAge > staleAfter,
    featureFreshness: freshness,
    confidence: riskConfidenceFor(featureAge).toDouble(),
    degradedReasons: reasons,
  );
}

String _humanAge(Duration age) {
  if (age.inMinutes < 1) return 'just now';
  if (age.inHours < 1) return '${age.inMinutes} min ago';
  if (age.inDays < 1) return '${age.inHours} h ago';
  return '${age.inDays} d ago';
}