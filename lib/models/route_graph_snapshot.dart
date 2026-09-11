// Phase 5 — transport model for `GET /routing/graph-snapshot`.
//
// Internal transport model (plain JSON parsing, no codegen): it is consumed
// only by the offline graph store, never rendered directly. Field names
// mirror the backend response exactly (snake_case).

/// One routable (non-CLOSED) segment with the server-computed weights.
class RouteGraphSegment {
  const RouteGraphSegment({
    required this.segmentId,
    required this.roadCode,
    required this.seq,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.lengthKm,
    required this.accessibility,
    required this.riskPct,
  });

  final String segmentId;
  final String roadCode;
  final int seq;
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double lengthKm;
  final double accessibility;
  final double riskPct;

  factory RouteGraphSegment.fromJson(Map<String, dynamic> j) {
    return RouteGraphSegment(
      segmentId: j['segment_id'] as String,
      roadCode: j['road_code'] as String,
      seq: (j['seq'] as num?)?.toInt() ?? 0,
      x1: (j['x1'] as num).toDouble(),
      y1: (j['y1'] as num).toDouble(),
      x2: (j['x2'] as num).toDouble(),
      y2: (j['y2'] as num).toDouble(),
      lengthKm: (j['length_km'] as num).toDouble(),
      accessibility: (j['accessibility'] as num).toDouble(),
      riskPct: (j['risk_pct'] as num).toDouble(),
    );
  }
}

/// One CLOSED segment (informational only — never routable).
class RouteGraphClosedSegment {
  const RouteGraphClosedSegment({
    required this.segmentId,
    required this.roadCode,
    required this.seq,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  final String segmentId;
  final String roadCode;
  final int seq;
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  factory RouteGraphClosedSegment.fromJson(Map<String, dynamic> j) {
    return RouteGraphClosedSegment(
      segmentId: j['segment_id'] as String,
      roadCode: j['road_code'] as String,
      seq: (j['seq'] as num?)?.toInt() ?? 0,
      x1: (j['x1'] as num).toDouble(),
      y1: (j['y1'] as num).toDouble(),
      x2: (j['x2'] as num).toDouble(),
      y2: (j['y2'] as num).toDouble(),
    );
  }
}

/// The `/routing/graph-snapshot` envelope.
class RouteGraphSnapshot {
  const RouteGraphSnapshot({
    required this.fetchedAt,
    required this.openSegments,
    required this.closedSegments,
  });

  final DateTime fetchedAt;
  final List<RouteGraphSegment> openSegments;
  final List<RouteGraphClosedSegment> closedSegments;

  factory RouteGraphSnapshot.fromJson(Map<String, dynamic> j) {
    final fetched = DateTime.tryParse(j['fetched_at'] as String? ?? '') ??
        DateTime.now().toUtc();
    final open = (j['open_segments'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RouteGraphSegment.fromJson)
        .toList();
    final closed = (j['closed_segments'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RouteGraphClosedSegment.fromJson)
        .toList();
    return RouteGraphSnapshot(
      fetchedAt: fetched.toUtc(),
      openSegments: open,
      closedSegments: closed,
    );
  }
}