# -*- coding: utf-8 -*-
"""Translation catalogs (Phase 17 · FR-C15.1).

Design rules (source-mandated honesty over breadth):
  * THREE languages only: en (canonical), hi (Hindi), as (Assamese — the
    selected NER language; first of the frozen MVP set in docs/requirements.md).
  * Flat dotted keys so catalog PARITY is unit-testable (every language must
    carry every key — a missing key is a test failure, not a runtime surprise).
  * Operational information first: alerts, emergency instructions, field
    instructions, incident forms, recommendations. Chrome (Dashboard /
    Settings / Login) is included but secondary.
  * {placeholders} are interpolated by service.t(); identical across languages.
  * Native review note: hi/as strings are short operational sentences intended
    for native-speaker sign-off before production rollout.
"""

EN: dict[str, str] = {
    # ------------------------------------------------------------- chrome / nav
    "app.name": "NER-SHIELD",
    "nav.dashboard": "Dashboard",
    "nav.settings": "Settings",
    "nav.login": "Login",
    "nav.logout": "Log out",
    "nav.alerts": "Alerts",
    "nav.map": "Map",
    "nav.incidents": "Incidents",
    "nav.shipments": "Shipments",
    "nav.supply": "Supply",
    "nav.action_center": "Action Center",
    "nav.analytics": "Analytics",
    "nav.report": "Report Incident",
    "settings.language": "Language",

    # ------------------------------------------------------------ alert levels
    "alerts.level.INFO": "Info",
    "alerts.level.WARNING": "Warning",
    "alerts.level.HIGH": "High",
    "alerts.level.CRITICAL": "Critical",

    # ----------------------------------------------------------- alert statuses
    "alerts.status.ACTIVE": "Active",
    "alerts.status.ESCALATED": "Escalated",
    "alerts.status.ACKNOWLEDGED": "Acknowledged",
    "alerts.status.RESOLVED": "Resolved",

    # -------------------------------------------------------------- alert types
    "alerts.type.ROAD_WARNING": "Road warning",
    "alerts.type.CRITICAL_SHIPMENT": "Critical shipment alert",
    "alerts.type.REGIONAL_SUPPLY_CRISIS": "Regional supply crisis",
    "alerts.type.DISRUPTION_PREDICTED": "Disruption predicted",
    "alerts.type.SHORTAGE_PREDICTED": "Shortage predicted",
    "alerts.type.IMPACT_ALERT": "Impact alert",
    "alerts.type.SYSTEM": "System notice",

    # ------------------------------------------- alert templates (per language)
    "alerts.title.ROAD_WARNING":
        "Road disruption in {district} ({level})",
    "alerts.message.ROAD_WARNING":
        "{incident_type} validated in {district}. Avoid the affected stretch "
        "and follow district administration instructions.",
    "alerts.title.CRITICAL_SHIPMENT":
        "Critical shipment at risk ({level})",
    "alerts.message.CRITICAL_SHIPMENT":
        "A shipment serving {district} faces high disruption risk. "
        "Review alternate routing before departure.",
    "alerts.title.REGIONAL_SUPPLY_CRISIS":
        "Regional supply crisis declared ({level})",
    "alerts.message.REGIONAL_SUPPLY_CRISIS":
        "Multiple districts face critical shortages. Regional-level response "
        "is required.",
    "alerts.title.DISRUPTION_PREDICTED":
        "Disruption predicted near {district} ({level})",
    "alerts.message.DISRUPTION_PREDICTED":
        "The prediction engine flags elevated disruption probability. Verify "
        "ground truth before dispatch decisions.",
    "alerts.title.SHORTAGE_PREDICTED":
        "Shortage predicted in {district} ({level})",
    "alerts.message.SHORTAGE_PREDICTED":
        "Forecast indicates a supply shortfall within the exposure horizon. "
        "Review the watchlist and pre-positioning options.",
    "alerts.title.IMPACT_ALERT":
        "Impact assessment updated for {district} ({level})",
    "alerts.message.IMPACT_ALERT":
        "Accessibility was re-assessed after new evidence. Review cut-off "
        "risk for affected districts.",
    "alerts.title.SYSTEM": "System notice ({level})",
    "alerts.message.SYSTEM": "{message}",
    # ------------------------------- EMERGENCY INSTRUCTIONS (field-actionable)
    "alerts.emergency.LANDSLIDE":
        "Do not cross the debris. Move away from the slope to open ground — "
        "more material may fall.",
    "alerts.emergency.FLOOD":
        "Move to higher ground immediately. Never walk or drive through "
        "floodwater.",
    "alerts.emergency.BRIDGE_PROBLEM":
        "Do not use the bridge until it is officially reopened.",
    "alerts.emergency.ROAD_DAMAGE":
        "The road is damaged. Slow down and use an alternate route where "
        "available.",
    "alerts.emergency.TRAFFIC_BLOCKAGE":
        "The route is blocked. Plan an alternate route and inform your "
        "control room.",
    "alerts.emergency.GENERIC":
        "Follow the instructions of the district administration.",
    "alerts.emergency.OTHER":
        "Follow the instructions of the district administration.",

    # ------------------------------------------------- field report vocabulary
    "field.incident_type.LANDSLIDE": "Landslide",
    "field.incident_type.FLOOD": "Flood",
    "field.incident_type.ROAD_DAMAGE": "Road damage",
    "field.incident_type.TRAFFIC_BLOCKAGE": "Traffic blockage",
    "field.incident_type.BRIDGE_PROBLEM": "Bridge problem",
    "field.incident_type.OTHER": "Other",

    "field.severity.LOW": "Low",
    "field.severity.MEDIUM": "Medium",
    "field.severity.HIGH": "High",
    "field.severity.CRITICAL": "Critical",

    "field.status.SUBMITTED": "Awaiting validation",
    "field.status.VALIDATED": "Validated",
    "field.status.REJECTED": "Rejected",

    # ------------------------------------------------- incident form + labels
    "field.form.title": "Report Incident",
    "field.form.token": "Access token",
    "field.form.type": "Incident type",
    "field.form.severity": "Severity",
    "field.form.photo": "Photo",
    "field.form.description": "Description",
    "field.form.submit": "SUBMIT",

    # ---------------------------------------------------- FIELD INSTRUCTIONS
    "field.instruction.gps":
        "Location is attached automatically. Keep the device outdoors for "
        "better accuracy.",
    "field.instruction.photo":
        "Attach a photo when it is safe to do so — it raises report "
        "confidence.",
    "field.instruction.offline":
        "No network is fine: the report is queued on the device and sent "
        "automatically later.",
    "field.result.submitted":
        "Submitted ✔ confidence {confidence}% — awaiting validation",
    "field.error.token": "Access token required",
    "field.error.gps": "GPS not ready yet — wait for a fix",

    # -------------------------------------------------- supply RECOMMENDATIONS
    "supply.action.PRE_POSITION":
        "Pre-position stock at forward facilities now",
    "supply.action.ACCELERATE_INCOMING":
        "Accelerate incoming shipments to cover the gap",
    "supply.action.MONITOR_CLOSELY":
        "Monitor closely; re-check within 6 hours",
    "supply.action.MONITOR":
        "Monitor only; no action needed right now",

    "supply.demand.HIGH": "High demand pressure",
    "supply.demand.MEDIUM": "Medium demand pressure",
    "supply.demand.NORMAL": "Normal demand",
    "supply.demand.LOW": "Low demand",
}

HI: dict[str, str] = {
    # ------------------------------------------------------------- chrome / nav
    "app.name": "NER-SHIELD",
    "nav.dashboard": "डैशबोर्ड",
    "nav.settings": "सेटिंग्स",
    "nav.login": "लॉगिन",
    "nav.logout": "लॉग आउट",
    "nav.alerts": "अलर्ट",
    "nav.map": "नक्शा",
    "nav.incidents": "घटनाएँ",
    "nav.shipments": "खेपें",
    "nav.supply": "आपूर्ति",
    "nav.action_center": "कार्य केंद्र",
    "nav.analytics": "विश्लेषण",
    "nav.report": "घटना की रिपोर्ट करें",
    "settings.language": "भाषा",

    # ------------------------------------------------------------ alert levels
    "alerts.level.INFO": "सूचना",
    "alerts.level.WARNING": "चेतावनी",
    "alerts.level.HIGH": "उच्च",
    "alerts.level.CRITICAL": "गंभीर",

    # ----------------------------------------------------------- alert statuses
    "alerts.status.ACTIVE": "सक्रिय",
    "alerts.status.ESCALATED": "आगे भेजा गया",
    "alerts.status.ACKNOWLEDGED": "पावती मिली",
    "alerts.status.RESOLVED": "हल हो गया",

    # -------------------------------------------------------------- alert types
    "alerts.type.ROAD_WARNING": "सड़क चेतावनी",
    "alerts.type.CRITICAL_SHIPMENT": "गंभीर खेप अलर्ट",
    "alerts.type.REGIONAL_SUPPLY_CRISIS": "क्षेत्रीय आपूर्ति संकट",
    "alerts.type.DISRUPTION_PREDICTED": "अवरोध की भविष्यवाणी",
    "alerts.type.SHORTAGE_PREDICTED": "कमी की भविष्यवाणी",
    "alerts.type.IMPACT_ALERT": "प्रभाव अलर्ट",
    "alerts.type.SYSTEM": "प्रणाली सूचना",

    # ------------------------------------------- alert templates (per language)
    "alerts.title.ROAD_WARNING": "{district} में सड़क अवरोध ({level})",
    "alerts.message.ROAD_WARNING":
        "{district} में {incident_type} की पुष्टि हुई है। प्रभावित मार्ग से "
        "बचें और ज़िला प्रशासन के निर्देशों का पालन करें।",
    "alerts.title.CRITICAL_SHIPMENT": "गंभीर खेप जोखिम में ({level})",
    "alerts.message.CRITICAL_SHIPMENT":
        "{district} को सेवा दे रही एक खेप पर उच्च अवरोध जोखिम है। रवानगी से "
        "पहले वैकल्पिक मार्ग देखें।",
    "alerts.title.REGIONAL_SUPPLY_CRISIS":
        "क्षेत्रीय आपूर्ति संकट घोषित ({level})",
    "alerts.message.REGIONAL_SUPPLY_CRISIS":
        "कई ज़िलों में गंभीर कमी है। क्षेत्रीय स्तर की कार्रवाई आवश्यक है।",
    "alerts.title.DISRUPTION_PREDICTED":
        "{district} के पास अवरोध की भविष्यवाणी ({level})",
    "alerts.message.DISRUPTION_PREDICTED":
        "भविष्यवाणी इंजन उच्च अवरोध संभावना दिखा रहा है। भेजने से पहले "
        "मैदानी हालत की पुष्टि करें।",
    "alerts.title.SHORTAGE_PREDICTED":
        "{district} में कमी की भविष्यवाणी ({level})",
    "alerts.message.SHORTAGE_PREDICTED":
        "अनुमान के अनुसार अवधि में आपूर्ति की कमी होगी। वॉचलिस्ट और "
        "अग्रिम-स्थापना विकल्प देखें।",
    "alerts.title.IMPACT_ALERT":
        "{district} के लिए प्रभाव मूल्यांकन अद्यतन ({level})",
    "alerts.message.IMPACT_ALERT":
        "नए साक्ष्य के बाद पहुँच का पुनर्मूल्यांकन हुआ है। प्रभावित ज़िलों के "
        "कट-ऑफ जोखिम की समीक्षा करें।",
    "alerts.title.SYSTEM": "प्रणाली सूचना ({level})",
    "alerts.message.SYSTEM": "{message}",
    # ------------------------------- EMERGENCY INSTRUCTIONS (field-actionable)
    "alerts.emergency.LANDSLIDE":
        "मलबे को पार करने की कोशिश न करें। ढलान से दूर खुले क्षेत्र में "
        "जाएँ — मलबा फिर गिर सकता है।",
    "alerts.emergency.FLOOD":
        "तुरंत ऊँची ज़मीन पर जाएँ। बहते पानी में न चलें, न गाड़ी ले जाएँ।",
    "alerts.emergency.BRIDGE_PROBLEM":
        "आधिकारिक रूप से फिर खोले जाने तक पुल का उपयोग न करें।",
    "alerts.emergency.ROAD_DAMAGE":
        "सड़क क्षतिग्रस्त है। धीमे चलें और जहाँ संभव हो वैकल्पिक मार्ग "
        "अपनाएँ।",
    "alerts.emergency.TRAFFIC_BLOCKAGE":
        "मार्ग अवरुद्ध है। वैकल्पिक मार्ग चुनें और नियंत्रण कक्ष को बताएँ।",
    "alerts.emergency.GENERIC":
        "ज़िला प्रशासन के निर्देशों का पालन करें।",
    "alerts.emergency.OTHER":
        "ज़िला प्रशासन के निर्देशों का पालन करें।",

    # ------------------------------------------------- field report vocabulary
    "field.incident_type.LANDSLIDE": "भूस्खलन",
    "field.incident_type.FLOOD": "बाढ़",
    "field.incident_type.ROAD_DAMAGE": "सड़क क्षति",
    "field.incident_type.TRAFFIC_BLOCKAGE": "यातायात अवरोध",
    "field.incident_type.BRIDGE_PROBLEM": "पुल समस्या",
    "field.incident_type.OTHER": "अन्य",

    "field.severity.LOW": "कम",
    "field.severity.MEDIUM": "मध्यम",
    "field.severity.HIGH": "उच्च",
    "field.severity.CRITICAL": "गंभीर",

    "field.status.SUBMITTED": "सत्यापन प्रतीक्षित",
    "field.status.VALIDATED": "सत्यापित",
    "field.status.REJECTED": "अस्वीकृत",

    # ------------------------------------------------- incident form + labels
    "field.form.title": "घटना की रिपोर्ट करें",
    "field.form.token": "एक्सेस टोकन",
    "field.form.type": "घटना का प्रकार",
    "field.form.severity": "गंभीरता",
    "field.form.photo": "फ़ोटो",
    "field.form.description": "विवरण",
    "field.form.submit": "जमा करें",

    # ---------------------------------------------------- FIELD INSTRUCTIONS
    "field.instruction.gps":
        "स्थान स्वयं जुड़ जाता है। बेहतर सटीकता के लिए डिवाइस खुले में रखें।",
    "field.instruction.photo":
        "सुरक्षित होने पर फ़ोटो जोड़ें — इससे रिपोर्ट की विश्वसनीयता बढ़ती है।",
    "field.instruction.offline":
        "नेटवर्क न हो तो ठीक है: रिपोर्ट डिवाइस पर कतार में रहेगी और बाद "
        "में स्वयं भेज दी जाएगी।",
    "field.result.submitted":
        "जमा हुआ ✔ विश्वसनीयता {confidence}% — सत्यापन प्रतीक्षित",
    "field.error.token": "एक्सेस टोकन आवश्यक है",
    "field.error.gps": "GPS तैयार नहीं है — थोड़ा प्रतीक्षा करें",

    # -------------------------------------------------- supply RECOMMENDATIONS
    "supply.action.PRE_POSITION":
        "अग्रिम केंद्रों पर अभी स्टॉक तैनात करें",
    "supply.action.ACCELERATE_INCOMING":
        "आ रही खेपों को तेज़ करें",
    "supply.action.MONITOR_CLOSELY":
        "बारीकी से निगरानी करें; 6 घंटे में फिर जाँचें",
    "supply.action.MONITOR":
        "केवल निगरानी करें; अभी कोई कार्रवाई आवश्यक नहीं",

    "supply.demand.HIGH": "उच्च माँग दबाव",
    "supply.demand.MEDIUM": "मध्यम माँग दबाव",
    "supply.demand.NORMAL": "सामान्य माँग",
    "supply.demand.LOW": "कम माँग",
}

AS: dict[str, str] = {
    # ------------------------------------------------------------- chrome / nav
    "app.name": "NER-SHIELD",
    "nav.dashboard": "ডেশব'ৰ্ড",
    "nav.settings": "ছেটিংছ",
    "nav.login": "লগইন",
    "nav.logout": "লগ আউট",
    "nav.alerts": "আলাৰ্ট",
    "nav.map": "মানচিত্ৰ",
    "nav.incidents": "ঘটনাসমূহ",
    "nav.shipments": "চালানসমূহ",
    "nav.supply": "যোগান",
    "nav.action_center": "কাৰ্য কেন্দ্ৰ",
    "nav.analytics": "বিশ্লেষণ",
    "nav.report": "ঘটনা জনাওক",
    "settings.language": "ভাষা",

    # ------------------------------------------------------------ alert levels
    "alerts.level.INFO": "তথ্য",
    "alerts.level.WARNING": "সতৰ্কবাণী",
    "alerts.level.HIGH": "উচ্চ",
    "alerts.level.CRITICAL": "গুৰুতৰ",

    # ----------------------------------------------------------- alert statuses
    "alerts.status.ACTIVE": "সক্ৰিয়",
    "alerts.status.ESCALATED": "আগুৱাই দিয়া হৈছে",
    "alerts.status.ACKNOWLEDGED": "গ্ৰহণ কৰা হৈছে",
    "alerts.status.RESOLVED": "সমাধান হৈছে",

    # -------------------------------------------------------------- alert types
    "alerts.type.ROAD_WARNING": "পথ সতৰ্কবাণী",
    "alerts.type.CRITICAL_SHIPMENT": "গুৰুতৰ চালানৰ আলাৰ্ট",
    "alerts.type.REGIONAL_SUPPLY_CRISIS": "আঞ্চলিক যোগান সংকট",
    "alerts.type.DISRUPTION_PREDICTED": "অৱৰোধৰ পূৰ্বানুমান",
    "alerts.type.SHORTAGE_PREDICTED": "টানাকনিৰ পূৰ্বানুমান",
    "alerts.type.IMPACT_ALERT": "প্ৰভাৱ আলাৰ্ট",
    "alerts.type.SYSTEM": "প্ৰণালীৰ সূচনা",

    # ------------------------------------------- alert templates (per language)
    "alerts.title.ROAD_WARNING": "{district}ত পথ অৱৰোধ ({level})",
    "alerts.message.ROAD_WARNING":
        "{district}ত {incident_type}ৰ সত্যাপন হৈছে। ক্ষতিগ্ৰস্ত পথ এৰক আৰু "
        "জিলা প্ৰশাসনৰ নিৰ্দেশ মানক।",
    "alerts.title.CRITICAL_SHIPMENT": "গুৰুতৰ চালান বিপদত ({level})",
    "alerts.message.CRITICAL_SHIPMENT":
        "{district}লৈ যোৱা এখন চালানৰ ওপৰত উচ্চ অৱৰোধৰ বিপদ আছে। ৰাওনা "
        "হোৱাৰ আগতে বিকল্প পথ চাওক।",
    "alerts.title.REGIONAL_SUPPLY_CRISIS":
        "আঞ্চলিক যোগান সংকট ঘোষিত ({level})",
    "alerts.message.REGIONAL_SUPPLY_CRISIS":
        "কেইবাটাও জিলাত গুৰুতৰ টানাকনি আছে। আঞ্চলিক পৰ্যায়ৰ কাৰ্য প্ৰয়োজন।",
    "alerts.title.DISRUPTION_PREDICTED":
        "{district}ৰ ওচৰত অৱৰোধৰ পূৰ্বানুমান ({level})",
    "alerts.message.DISRUPTION_PREDICTED":
        "পূৰ্বানুমান ইঞ্জিনে উচ্চ অৱৰোধৰ সম্ভাৱনা দেখুৱাইছে। পঠিয়াবৰ আগতে "
        "প্ৰকৃত অৱস্থা নিশ্চিত কৰক।",
    "alerts.title.SHORTAGE_PREDICTED":
        "{district}ত টানাকনিৰ পূৰ্বানুমান ({level})",
    "alerts.message.SHORTAGE_PREDICTED":
        "পূৰ্বানুমানত সময়সীমাৰ ভিতৰত যোগানৰ টানাকনি দেখা গৈছে। ৱাচলিষ্ট "
        "আৰু আগতে সাজু ৰাখাৰ বিকল্প চাওক।",
    "alerts.title.IMPACT_ALERT":
        "{district}ৰ প্ৰভাৱ মূল্যায়ন আধুনিক ({level})",
    "alerts.message.IMPACT_ALERT":
        "নতুন প্ৰমাণৰ পিছত সুগমতা পুনৰ মূল্যায়ন কৰা হৈছে। প্ৰভাৱিত "
        "জিলাসমূহৰ কাট-অফৰ বিপদ চাওক।",
    "alerts.title.SYSTEM": "প্ৰণালীৰ সূচনা ({level})",
    "alerts.message.SYSTEM": "{message}",
    # ------------------------------- EMERGENCY INSTRUCTIONS (field-actionable)
    "alerts.emergency.LANDSLIDE":
        "মাটি-বোলা পাৰ হ'বলৈ চেষ্টা নকৰিব। ঢালৰ পৰা আঁতৰি খোলা ঠাইলৈ "
        "যাওক — আকৌ মাটি পৰিব পাৰে।",
    "alerts.emergency.FLOOD":
        "লগে লগে ওখ ঠাইলৈ যাওক। বৈ থকা পানীত খোজ কঢ়া বা গাড়ী চলোৱা "
        "একেবাৰেই নহয়।",
    "alerts.emergency.BRIDGE_PROBLEM":
        "আধিকাৰিকভাৱে পুনৰ খোলা নহ'লৈকে সাঁকো ব্যৱহাৰ নকৰিব।",
    "alerts.emergency.ROAD_DAMAGE":
        "পথটো ক্ষতিগ্ৰস্ত। লাহে লাহে যাওক আৰু সম্ভৱ হ'লে বিকল্প পথ লওক।",
    "alerts.emergency.TRAFFIC_BLOCKAGE":
        "পথ অৱৰুদ্ধ। বিকল্প পথ লওক আৰু নিয়ন্ত্ৰণ কক্ষক জনাওক।",
    "alerts.emergency.GENERIC":
        "জিলা প্ৰশাসনৰ নিৰ্দেশ মানক।",
    "alerts.emergency.OTHER":
        "জিলা প্ৰশাসনৰ নিৰ্দেশ মানক।",

    # ------------------------------------------------- field report vocabulary
    "field.incident_type.LANDSLIDE": "ভূমিস্খলন",
    "field.incident_type.FLOOD": "বান",
    "field.incident_type.ROAD_DAMAGE": "পথৰ ক্ষতি",
    "field.incident_type.TRAFFIC_BLOCKAGE": "যাতায়াত অৱৰোধ",
    "field.incident_type.BRIDGE_PROBLEM": "সাঁকোৰ সমস্যা",
    "field.incident_type.OTHER": "অন্যান্য",

    "field.severity.LOW": "কম",
    "field.severity.MEDIUM": "মধ্যম",
    "field.severity.HIGH": "উচ্চ",
    "field.severity.CRITICAL": "গুৰুতৰ",

    "field.status.SUBMITTED": "সত্যাপনৰ অপেক্ষাত",
    "field.status.VALIDATED": "সত্যাপিত",
    "field.status.REJECTED": "নাকচ",

    # ------------------------------------------------- incident form + labels
    "field.form.title": "ঘটনা জনাওক",
    "field.form.token": "এক্সেছ ট'কেন",
    "field.form.type": "ঘটনাৰ প্ৰকাৰ",
    "field.form.severity": "গুৰুতৰতা",
    "field.form.photo": "ফটো",
    "field.form.description": "বিৱৰণ",
    "field.form.submit": "দাখিল কৰক",

    # ---------------------------------------------------- FIELD INSTRUCTIONS
    "field.instruction.gps":
        "স্থান স্বয়ংক্ৰিয়ভাৱে যোগ হয়। ভাল স্পষ্টতাৰ বাবে ডিভাইচ মুকলি "
        "ঠাইত ৰাখক।",
    "field.instruction.photo":
        "সুৰক্ষিত হ'লে ফটো যোগ কৰক — ই ৰিপৰ্টৰ বিশ্বাসযোগ্যতা বঢ়ায়।",
    "field.instruction.offline":
        "নেটৱৰ্ক নাথাকিলেও সমস্যা নাই: ৰিপৰ্ট ডিভাইচত লাইনত থাকিব আৰু "
        "পিছত স্বয়ংক্ৰিয়ভাৱে পঠিয়াই দিয়া হ'ব।",
    "field.result.submitted":
        "দাখিল হ'ল ✔ বিশ্বাসযোগ্যতা {confidence}% — সত্যাপনৰ অপেক্ষাত",
    "field.error.token": "এক্সেছ ট'কেন প্ৰয়োজন",
    "field.error.gps": "GPS সাজু নহয় — অলপ ৰ'ব",

    # -------------------------------------------------- supply RECOMMENDATIONS
    "supply.action.PRE_POSITION":
        "আগ্ৰিম কেন্দ্ৰত এতিয়াই ষ্টক সাজু ৰাখক",
    "supply.action.ACCELERATE_INCOMING":
        "আহি থকা চালান দ্ৰুত কৰক",
    "supply.action.MONITOR_CLOSELY":
        "ওত প্ৰোতে লক্ষ্য ৰাখক; ৬ ঘণ্টাৰ ভিতৰত পুনৰ পৰীক্ষা কৰক",
    "supply.action.MONITOR":
        "কেৱল লক্ষ্য ৰাখক; এতিয়া কোনো কাৰ্য নালাগে",

    "supply.demand.HIGH": "উচ্চ চাহিদাৰ চাপ",
    "supply.demand.MEDIUM": "মধ্যম চাহিদাৰ চাপ",
    "supply.demand.NORMAL": "স্বাভাৱিক চাহিদা",
    "supply.demand.LOW": "কম চাহিদা",
}

# ---------------------------------------------------------------- SIH26002 P8
# Manipuri / Meitei (mni) — DEMO TRANSLATIONS, pending native-speaker review.
# Romanized Meiteilon with common English loanwords (real-world usage style);
# NOT an official translation set. Parity with EN keys is enforced by test so
# coverage claims stay honest.
MNI: dict[str, str] = {
    # ------------------------------------------------------------- chrome / nav
    "app.name": "NER-SHIELD",
    "nav.dashboard": "Command Center",
    "nav.settings": "Settings",
    "nav.login": "Login touba",
    "nav.logout": "Logout touba",
    "nav.alerts": "Alerts",
    "nav.map": "Map",
    "nav.incidents": "Incidents",
    "nav.shipments": "Shipments",
    "nav.supply": "Supply",
    "nav.action_center": "Action Center",
    "nav.analytics": "Analytics",
    "nav.report": "Incident report touba",
    "settings.language": "Language",

    # ------------------------------------------------------------ alert levels
    "alerts.level.INFO": "Info",
    "alerts.level.WARNING": "Warning",
    "alerts.level.HIGH": "Phibam adum",
    "alerts.level.CRITICAL": "Phibam magi macha",

    # ----------------------------------------------------------- alert statuses
    "alerts.status.ACTIVE": "Matougi touba",
    "alerts.status.ESCALATED": "Atopgi khangba",
    "alerts.status.ACKNOWLEDGED": "Loukhatpa",
    "alerts.status.RESOLVED": "Thokchatpi",

    # -------------------------------------------------------------- alert types
    "alerts.type.ROAD_WARNING": "Lamjel chumbang",
    "alerts.type.CRITICAL_SHIPMENT": "Maru suhailak chumbang",
    "alerts.type.REGIONAL_SUPPLY_CRISIS": "Leikol supply thugairiba",
    "alerts.type.DISRUPTION_PREDICTED": "Ei chumba thoklabasu",
    "alerts.type.SHORTAGE_PREDICTED": "Supply kamajaba thoklabasu",
    "alerts.type.IMPACT_ALERT": "Pal khongthatchaba chumbang",
    "alerts.type.SYSTEM": "System thianba",

    # ------------------------------------------- alert templates (per language)
    "alerts.title.ROAD_WARNING":
        "{district} da lamjel ei ({level})",
    "alerts.message.ROAD_WARNING":
        "{district} da {incident_type} ngaklamme. Ei chumlamda chatlu "
        "amadi district administration gi nongsinbi chumnachaba chaabi.",
    "alerts.title.CRITICAL_SHIPMENT":
        "Maru suhailak phibada ({level})",
    "alerts.message.CRITICAL_SHIPMENT":
        "{district} chathokpa suhailak adu ei phibam adumda lei. "
        "Chatlammak thadokpadagi nouraba amasung alternate lamjel "
        "sengnabiyou.",
    "alerts.title.REGIONAL_SUPPLY_CRISIS":
        "Leikol supply thugairiba ({level})",
    "alerts.message.REGIONAL_SUPPLY_CRISIS":
        "District kaya amadi maru supply kamajaba leiri. Leikol-level "
        "gi tougee yodre.",
    "alerts.title.DISRUPTION_PREDICTED":
        "{district} achouba ei chumba thoklabasu ({level})",
    "alerts.message.DISRUPTION_PREDICTED":
        "Prediction engine na ei chumba thokpiba phibam adum ngakpane. "
        "Dispatch touba matangda ground truth ngakpiyou.",
    "alerts.title.SHORTAGE_PREDICTED":
        "{district} da supply kamajaba thoklabasu ({level})",
    "alerts.message.SHORTAGE_PREDICTED":
        "Forecast na supply kamajaba thokpana ngakpi. Watchlist amasung "
        "pre-positioning tougee nongiye.",
    "alerts.title.SYSTEM": "System thianba ({level})",
    "alerts.message.SYSTEM": "{message}",
    "alerts.title.IMPACT_ALERT":
        "{district} da pal khongthatchaba ({level})",
    "alerts.message.IMPACT_ALERT":
        "Ei pal khongthatchabagi maram wari. Nouraba ngakpiyou.",

    # ------------------------------------------------- emergency instructions
    "alerts.emergency.LANDSLIDE":
        "Ching-singba thoklabasu — ching-singda chatu, officials gi "
        "nongsinbi chumnachaba chaabi.",
    "alerts.emergency.FLOOD":
        "Panba thoklabasu — pukning chumnadaba nattana chatlu; officials "
        "gi nongsinbi chaabi.",
    "alerts.emergency.ROAD_DAMAGE":
        "Lamjel ei thoklabasu — ei chumlam adu khangnabiyou; slow chatu.",
    "alerts.emergency.TRAFFIC_BLOCKAGE":
        "Lamjel ei — nungshihaiba alternate lamjel sengnabiyou.",
    "alerts.emergency.BRIDGE_PROBLEM":
        "Sanglen ei — sanglen adugidamak chatlammak khallou.",
    "alerts.emergency.GENERIC":
        "Nakhok ki phibang nattana, officials gi nongsinbi chumnachaba "
        "chaabi.",
    "alerts.emergency.OTHER":
        "Nakhok ki phibang nattana, officials gi nongsinbi chumnachaba "
        "chaabi.",

    # ------------------------------------------------------- field report form
    "field.form.title": "Incident Report",
    "field.form.type": "Ei chumlabagi mapal",
    "field.form.severity": "Phibam",
    "field.form.photo": "Photo (JPEG/PNG/WebP)",
    "field.form.description": "Wari mayek",
    "field.form.token": "Access token",
    "field.form.submit": "Thokpa",

    "field.incident_type.LANDSLIDE": "Ching-singba",
    "field.incident_type.FLOOD": "Panba",
    "field.incident_type.ROAD_DAMAGE": "Lamjel ei",
    "field.incident_type.TRAFFIC_BLOCKAGE": "Lamjel ei",
    "field.incident_type.BRIDGE_PROBLEM": "Sanglen ei",
    "field.incident_type.OTHER": "Atopa",

    "field.severity.LOW": "Tambam leite",
    "field.severity.MEDIUM": "Mapan thokpa",
    "field.severity.HIGH": "Phibam adum",
    "field.severity.CRITICAL": "Phibam magi macha",

    "field.status.SUBMITTED": "Thokpare",
    "field.status.VALIDATED": "Ngakpare",
    "field.status.REJECTED": "Khallare",

    "field.instruction.gps":
        "GPS khangnabiyou — location sajjana thokpiyou.",
    "field.instruction.photo":
        "Photo yoduna report gi biswasano cheksinbiyou.",
    "field.instruction.offline":
        "Network nattaba matangda problem neite: report deviceta "
        "leitrakaduna pithok auto-thokpiyou.",
    "field.result.submitted":
        "Report thokpare ✓ — biswasano {confidence}% — ngakpana "
        "officials gi maram wari.",
    "field.error.token": "Token sajana you",
    "field.error.gps": "GPS sajjana leite — alappa chumiyou",

    # -------------------------------------------------- supply recommendations
    "supply.action.PRE_POSITION":
        "Supply maru leikolda chumlaga thabaklou",
    "supply.action.ACCELERATE_INCOMING":
        "Ahallakpa supply chumnaduna thokpa",
    "supply.action.MONITOR_CLOSELY":
        "Chumnachaba ngakpiyou; 6 hours da pithok ngakpiyou",
    "supply.action.MONITOR":
        "Ngakpiyou; atiyopgi tougee nattene",

    "supply.demand.HIGH": "Chatnabi phibam",
    "supply.demand.MEDIUM": "Mapan thokpa chatnaba",
    "supply.demand.NORMAL": "Waiba chatnaba",
    "supply.demand.LOW": "Kamdouda chatnaba",
}

# Frozen MVP set (FR-C15.1): en canonical + hi + as. SIH26002 P8 adds
# Manipuri/Meitei (mni) as DEMO translations pending native review.
# Extend ONLY with a new catalog plus a parity-test pass; never claim
# coverage that does not exist.
CATALOGS: dict[str, dict[str, str]] = {"en": EN, "hi": HI, "as": AS,
                                       "mni": MNI}
