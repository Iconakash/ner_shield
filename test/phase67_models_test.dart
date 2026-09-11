import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/models/alert.dart';
import 'package:ner_shield/models/command_summary.dart';
import 'package:ner_shield/models/geojson.dart';
import 'package:ner_shield/models/risk_item.dart';
import 'package:ner_shield/models/shipment.dart';

void main() {
  group('CommandSummary (verified /command/summary shape)', () {
    test('parses the flat six-KPI payload', () {
      final s = CommandSummary.fromJson(const {
        'critical_alerts': 2,
        'high_risk_roads': 5,
        'active_shipments': 11,
        'critical_shipments': 3,
        'supply_risk_districts': 1,
        'predicted_disruptions': 4,
        'generated_at': '2026-08-31T10:00:00+00:00',
      });
      expect(s.criticalAlerts, 2);
      expect(s.highRiskRoads, 5);
      expect(s.activeShipments, 11);
      expect(s.criticalShipments, 3);
      expect(s.supplyRiskDistricts, 1);
      expect(s.predictedDisruptions, 4);
      expect(s.generatedAt, '2026-08-31T10:00:00+00:00');
    });

    test('kpis render the frozen tile list in backend order', () {
      const s = CommandSummary(criticalAlerts: 1, activeShipments: 2);
      expect(s.kpis.map((k) => k.id).toList(), const [
        'critical_alerts',
        'high_risk_roads',
        'active_shipments',
        'critical_shipments',
        'supply_risk_districts',
        'predicted_disruptions',
      ]);
      expect(s.kpis.first.description,
          'Open CRITICAL alerts awaiting action');
      expect(s.actionCount, 2);
    });
  });

  group('RiskPrediction (verified /risk/latest columns)', () {
    test('parses latest_predictions row', () {
      final r = RiskPrediction.fromJson(const {
        'segment_id': 'seg-1',
        'road_code': 'NH-2',
        'district_code': 'KAMRUP',
        'district_name': 'Kamrup',
        'overall_label': 'CRITICAL',
        // severity is a String label (risk/service.py SEVERITY_BY_LABEL),
        // not a number.
        'severity': 'CATASTROPHIC',
        'top_factors': [
          {'feature': 'rainfall_mm_24h', 'contribution': 0.4, 'label': 'Rain'},
        ],
        'summary_sentence': 'CRITICAL disruption risk on NH-2 near Kamrup.',
        'base_value': 45.0,
        'mode': 'xgb',
        'model_name': 'disruption_xgb',
        'model_version': 'm1',
        'computed_at': '2026-08-31T09:00:00+00:00',
      });
      expect(r.segmentId, 'seg-1');
      expect(r.overallLabel, 'CRITICAL');
      expect(r.isActionable, isTrue);
      expect(r.topFactors?.single['feature'], 'rainfall_mm_24h');
    });
  });

  group('Shipment (verified /shipments list row)', () {
    test('parses list row + helpers', () {
      final s = Shipment.fromJson(const {
        'id': 'abc',
        'code': 'SHP-TEST-1',
        'title': 'Medicine run',
        'commodity': 'MEDICINE',
        'priority': 'CRITICAL',
        'status': 'IN_TRANSIT',
        'origin_name': 'Guwahati Central Store',
        'dest_name': 'Tawang CHC',
        'vehicle_code': 'V-12',
        'dest_state': 'ARUNACHAL_PRADESH',
        'dest_district': 'TAWANG',
        'eta_at': '2026-08-31T12:00:00+00:00',
      });
      expect(s.isActive, isTrue);
      expect(s.isCritical, isTrue);
      expect(s.vehicleCode, 'V-12');
    });

    test('ETA payload parses', () {
      final e = ShipmentEta.fromJson(
        const {'id': 'abc', 'eta_minutes': 90, 'calculated_at': 'x'},
      );
      expect(e.etaMinutes, 90);
    });
  });

  group('Alert (verified /alerts/inbox + i18n merge)', () {
    test('parses row with localized fields and open-state helper', () {
      final a = Alert.fromJson(const {
        'id': 'a1',
        'level': 'CRITICAL',
        'alert_type': 'FLOOD_RISK',
        'title': 'Flood risk',
        'message': 'Heavy rainfall predicted',
        'status': 'ESCALATED',
        'current_role': 'REGIONAL_AUTHORITY',
        'district_code': 'KAMRUP',
        'localized_title': 'बाढ़ का खतरा',
        'localized_message': 'भारी वर्षा की संभावना',
        'emergency_instruction': 'Move to higher ground',
      });
      expect(a.isOpen, isTrue);
      expect(a.displayTitle, 'बाढ़ का खतरा');
    });

    test('displayTitle falls back to server title', () {
      final a = Alert.fromJson(const {
        'id': 'a2',
        'title': 'Road warning',
        'status': 'ACTIVE',
      });
      expect(a.displayTitle, 'Road warning');
    });
  });

  group('GeoJSON layers (verified /command/layers shape)', () {
    test('parses FeatureCollection with properties', () {
      final fc = GeoJsonFeatureCollection.fromJson(const {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [91.7, 26.1],
            },
            'properties': {
              'kind': 'disruption',
              'district_code': 'KAMRUP',
              'overall_label': 'HIGH',
              'risk_current': 0.7,
            },
          },
        ],
      });
      expect(fc.features, hasLength(1));
      expect(fc.features.single.properties['kind'], 'disruption');
    });
  });
}
