// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NER-SHIELD';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonOffline => 'You are offline';

  @override
  String get commonErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authMfaTitle => 'Two-factor verification';

  @override
  String get authMfaBody =>
      'Enter the 6-digit code from your authenticator app to complete sign-in.';

  @override
  String get authMfaVerify => 'Verify';

  @override
  String get authMfaUseDifferent => 'Use a different account';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authRestoreFailed =>
      'Session could not be restored. Please sign in again.';

  @override
  String get dashboardTitle => 'Command center';

  @override
  String get dashboardKpiActiveIncidents => 'Active incidents';

  @override
  String get dashboardKpiOpenAlerts => 'Open alerts';

  @override
  String get dashboardKpiInTransit => 'In transit shipments';

  @override
  String get dashboardKpiHighRiskRoads => 'High-risk roads';

  @override
  String get dashboardKpiDataHealth => 'Data health';

  @override
  String get dashboardKpiLastRefresh => 'Last refresh';

  @override
  String get mapTitle => 'Map';

  @override
  String get mapLayerSegments => 'Segments';

  @override
  String get mapLayerFacilities => 'Facilities';

  @override
  String get mapLayerHighRisk => 'High-risk roads';

  @override
  String get mapLayerDisruptions => 'Disruptions';

  @override
  String get mapLayerShipments => 'Shipments';

  @override
  String get mapLayerWeather => 'Weather';

  @override
  String get mapLocateButton => 'Locate';

  @override
  String get mapSearchHint => 'Search by coordinates (lon, lat)';

  @override
  String get mapStaleBanner => 'Showing cached data — connect to refresh';

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get alertsInboxEmpty => 'No alerts in your scope';

  @override
  String get alertsAcknowledge => 'Acknowledge';

  @override
  String get alertsResolve => 'Resolve';

  @override
  String get shipmentsTitle => 'Logistics';

  @override
  String get shipmentsFilterAll => 'All';

  @override
  String get shipmentsFilterActive => 'Active';

  @override
  String get shipmentsFilterCritical => 'Critical';

  @override
  String get shipmentsConfirmDelivery => 'Confirm delivery';

  @override
  String get shipmentsEtaTitle => 'Estimated arrival';

  @override
  String get riskTitle => 'Risk predictions';

  @override
  String get riskEmpty => 'No predictions published';

  @override
  String get riskWhy => 'Why this score?';

  @override
  String riskModel(String model) {
    return 'Model: $model';
  }

  @override
  String get routingTitle => 'Route planner';

  @override
  String get routingOriginHint => 'Origin (facility code or lon, lat)';

  @override
  String get routingDestHint => 'Destination';

  @override
  String get routingPlanButton => 'Plan';

  @override
  String get routingSwap => 'Swap';

  @override
  String get routingWhy => 'Why this route?';

  @override
  String get historicalTitle => 'Historical validation';

  @override
  String get historicalDetailTitle => 'Historical event';

  @override
  String get historicalLatestRun => 'Latest validation run';

  @override
  String get historicalDataMeasured => 'MEASURED';

  @override
  String get historicalDataSample => 'SAMPLE';

  @override
  String get historicalDataSimulated => 'SIMULATED';

  @override
  String get historicalDataNoDataset => 'NO_DATASET';

  @override
  String get tasksTitle => 'Action Center';

  @override
  String get tasksEmpty => 'No assigned tasks';

  @override
  String get emergencyTitle => 'Emergency response';

  @override
  String get emergencyEmpty => 'No assigned tasks';

  @override
  String get incidentsTitle => 'Reports';

  @override
  String get incidentsSubmitReport => 'New report';

  @override
  String get incidentsQueueTitle => 'Validation queue';

  @override
  String get incidentsTrustTitle => 'Reporter trust';

  @override
  String get notificationsPrefsTitle => 'Notifications';

  @override
  String get notificationsChannels => 'Channels';

  @override
  String get notificationsMinSeverity => 'Minimum severity';
}
