import '../../models/field_report.dart';

/// Pure offline validation for a [FieldReportDraft]. Used by the wizard
/// before queueing and by the sync controller before re-validating after a
/// server `VALIDATION_ERROR` rejection. Server remains authoritative; this
/// is purely a UX safety net so users get fast feedback without burning a
/// round-trip for known-bad inputs.
class OfflineDraftValidator {
  const OfflineDraftValidator();

  /// Returns `null` when the draft is OK; otherwise the human-readable
  /// reason the officer must fix.
  String? validate(FieldReportDraft draft) {
    if (draft.incidentType == null || draft.incidentType!.isEmpty) {
      return 'Choose an incident type.';
    }
    if (!_validIncidentTypes.contains(draft.incidentType)) {
      return 'Unknown incident type "${draft.incidentType}".';
    }
    if (draft.severity == null || draft.severity!.isEmpty) {
      return 'Choose a severity.';
    }
    if (!_validSeverities.contains(draft.severity)) {
      return 'Unknown severity "${draft.severity}".';
    }
    if (draft.lon == null || draft.lat == null) {
      return 'Set the incident location (longitude + latitude).';
    }
    if (!FieldReport.withinBounds(lon: draft.lon!, lat: draft.lat!)) {
      return 'Coordinates fall outside the NER region '
          '(lon 80-98, lat 21-29.5).';
    }
    final desc = draft.description ?? '';
    if (desc.length > 2000) {
      return 'Description exceeds 2000 characters.';
    }
    for (final ref in draft.mediaRefs) {
      final path = ref.localPath;
      if (path.isEmpty) {
        return 'Attached media is missing its local path.';
      }
    }
    return null;
  }

  static const _validIncidentTypes = {
    'LANDSLIDE', 'FLOOD', 'ROAD_DAMAGE',
    'TRAFFIC_BLOCKAGE', 'BRIDGE_PROBLEM', 'OTHER',
  };

  static const _validSeverities = {
    'LOW', 'MEDIUM', 'HIGH', 'CRITICAL',
  };
}