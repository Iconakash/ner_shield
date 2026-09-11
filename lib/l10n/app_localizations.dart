import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application display name shown on the landing screen and launcher.
  ///
  /// In en, this message translates to:
  /// **'NER-SHIELD'**
  String get appTitle;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get commonOffline;

  /// No description provided for @commonErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonErrorGeneric;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authMfaTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-factor verification'**
  String get authMfaTitle;

  /// No description provided for @authMfaBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app to complete sign-in.'**
  String get authMfaBody;

  /// No description provided for @authMfaVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authMfaVerify;

  /// No description provided for @authMfaUseDifferent.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get authMfaUseDifferent;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Session could not be restored. Please sign in again.'**
  String get authRestoreFailed;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Command center'**
  String get dashboardTitle;

  /// No description provided for @dashboardKpiActiveIncidents.
  ///
  /// In en, this message translates to:
  /// **'Active incidents'**
  String get dashboardKpiActiveIncidents;

  /// No description provided for @dashboardKpiOpenAlerts.
  ///
  /// In en, this message translates to:
  /// **'Open alerts'**
  String get dashboardKpiOpenAlerts;

  /// No description provided for @dashboardKpiInTransit.
  ///
  /// In en, this message translates to:
  /// **'In transit shipments'**
  String get dashboardKpiInTransit;

  /// No description provided for @dashboardKpiHighRiskRoads.
  ///
  /// In en, this message translates to:
  /// **'High-risk roads'**
  String get dashboardKpiHighRiskRoads;

  /// No description provided for @dashboardKpiDataHealth.
  ///
  /// In en, this message translates to:
  /// **'Data health'**
  String get dashboardKpiDataHealth;

  /// No description provided for @dashboardKpiLastRefresh.
  ///
  /// In en, this message translates to:
  /// **'Last refresh'**
  String get dashboardKpiLastRefresh;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTitle;

  /// No description provided for @mapLayerSegments.
  ///
  /// In en, this message translates to:
  /// **'Segments'**
  String get mapLayerSegments;

  /// No description provided for @mapLayerFacilities.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get mapLayerFacilities;

  /// No description provided for @mapLayerHighRisk.
  ///
  /// In en, this message translates to:
  /// **'High-risk roads'**
  String get mapLayerHighRisk;

  /// No description provided for @mapLayerDisruptions.
  ///
  /// In en, this message translates to:
  /// **'Disruptions'**
  String get mapLayerDisruptions;

  /// No description provided for @mapLayerShipments.
  ///
  /// In en, this message translates to:
  /// **'Shipments'**
  String get mapLayerShipments;

  /// No description provided for @mapLayerWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get mapLayerWeather;

  /// No description provided for @mapLocateButton.
  ///
  /// In en, this message translates to:
  /// **'Locate'**
  String get mapLocateButton;

  /// No description provided for @mapSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by coordinates (lon, lat)'**
  String get mapSearchHint;

  /// No description provided for @mapStaleBanner.
  ///
  /// In en, this message translates to:
  /// **'Showing cached data — connect to refresh'**
  String get mapStaleBanner;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// No description provided for @alertsInboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No alerts in your scope'**
  String get alertsInboxEmpty;

  /// No description provided for @alertsAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get alertsAcknowledge;

  /// No description provided for @alertsResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get alertsResolve;

  /// No description provided for @shipmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get shipmentsTitle;

  /// No description provided for @shipmentsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get shipmentsFilterAll;

  /// No description provided for @shipmentsFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get shipmentsFilterActive;

  /// No description provided for @shipmentsFilterCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get shipmentsFilterCritical;

  /// No description provided for @shipmentsConfirmDelivery.
  ///
  /// In en, this message translates to:
  /// **'Confirm delivery'**
  String get shipmentsConfirmDelivery;

  /// No description provided for @shipmentsEtaTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimated arrival'**
  String get shipmentsEtaTitle;

  /// No description provided for @riskTitle.
  ///
  /// In en, this message translates to:
  /// **'Risk predictions'**
  String get riskTitle;

  /// No description provided for @riskEmpty.
  ///
  /// In en, this message translates to:
  /// **'No predictions published'**
  String get riskEmpty;

  /// No description provided for @riskWhy.
  ///
  /// In en, this message translates to:
  /// **'Why this score?'**
  String get riskWhy;

  /// No description provided for @riskModel.
  ///
  /// In en, this message translates to:
  /// **'Model: {model}'**
  String riskModel(String model);

  /// No description provided for @routingTitle.
  ///
  /// In en, this message translates to:
  /// **'Route planner'**
  String get routingTitle;

  /// No description provided for @routingOriginHint.
  ///
  /// In en, this message translates to:
  /// **'Origin (facility code or lon, lat)'**
  String get routingOriginHint;

  /// No description provided for @routingDestHint.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get routingDestHint;

  /// No description provided for @routingPlanButton.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get routingPlanButton;

  /// No description provided for @routingSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get routingSwap;

  /// No description provided for @routingWhy.
  ///
  /// In en, this message translates to:
  /// **'Why this route?'**
  String get routingWhy;

  /// No description provided for @historicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Historical validation'**
  String get historicalTitle;

  /// No description provided for @historicalDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Historical event'**
  String get historicalDetailTitle;

  /// No description provided for @historicalLatestRun.
  ///
  /// In en, this message translates to:
  /// **'Latest validation run'**
  String get historicalLatestRun;

  /// No description provided for @historicalDataMeasured.
  ///
  /// In en, this message translates to:
  /// **'MEASURED'**
  String get historicalDataMeasured;

  /// No description provided for @historicalDataSample.
  ///
  /// In en, this message translates to:
  /// **'SAMPLE'**
  String get historicalDataSample;

  /// No description provided for @historicalDataSimulated.
  ///
  /// In en, this message translates to:
  /// **'SIMULATED'**
  String get historicalDataSimulated;

  /// No description provided for @historicalDataNoDataset.
  ///
  /// In en, this message translates to:
  /// **'NO_DATASET'**
  String get historicalDataNoDataset;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Action Center'**
  String get tasksTitle;

  /// No description provided for @tasksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No assigned tasks'**
  String get tasksEmpty;

  /// No description provided for @emergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency response'**
  String get emergencyTitle;

  /// No description provided for @emergencyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No assigned tasks'**
  String get emergencyEmpty;

  /// No description provided for @incidentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get incidentsTitle;

  /// No description provided for @incidentsSubmitReport.
  ///
  /// In en, this message translates to:
  /// **'New report'**
  String get incidentsSubmitReport;

  /// No description provided for @incidentsQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Validation queue'**
  String get incidentsQueueTitle;

  /// No description provided for @incidentsTrustTitle.
  ///
  /// In en, this message translates to:
  /// **'Reporter trust'**
  String get incidentsTrustTitle;

  /// No description provided for @notificationsPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsPrefsTitle;

  /// No description provided for @notificationsChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get notificationsChannels;

  /// No description provided for @notificationsMinSeverity.
  ///
  /// In en, this message translates to:
  /// **'Minimum severity'**
  String get notificationsMinSeverity;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
