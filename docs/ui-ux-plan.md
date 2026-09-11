# NER-SHIELD — UI/UX Plan

## Design language

- **Tone:** Government-grade, operational, modern, trustworthy, intelligent,
  geospatial, emergency-ready.
- **Base:** Material 3 theming with a constrained palette (deep indigo /
  navy + safety colors). Light/dark themes.
- **Typography:** large readable numerals for KPIs; clear hierarchy; tabular
  figure alignment for scores.
- **Status colors** used with **non-color-only** encoding: each status has
  icon + label + color (accessibility requirement).
  - Open ✅ · Partial ⚠ · Blocked ⛔ · Unknown ⚪
  - Risk: LOW/HIGH/CRITICAL use label chips + color.
  - Alert severity: INFO/WARNING/HIGH/CRITICAL labels + colors.

## Screens / surfaces priority

1. **Splash** (session restore + branding)
2. **Landing** (brand, value props, login/register CTA)
3. **Login + MFA**
4. **Role shell** with bottom navigation:
   - Field → Dashboard / Map / Quick Report / Tasks / Alerts / Profile
   - Logistics → Dashboard / Shipments / Map / Tasks / Alerts / Profile
   - District/Regional/Admin → Command → Analytics / Incidents / Users /
     Data Health / Audit / Alerts / Profile
5. **Dashboard** — KPI tiles + mini trend charts + data-freshness badge.
6. **Map** — layer toggles, search, detail bottom sheet.
7. **Incident form** — wizard: type → severity → location → media →
   description → review → submit; offline banner.
8. **Sync center** — pending ops, status per op, manual sync.
9. **Alert inbox** — severity chips, unread badges, ack/resolve.
10. **Shipment detail** — status stepper, vehicle, route, ETA, GPS trail.
11. **Routing** — route alternatives comparison.
12. **Analytics** — charts with loading/empty/error handled.
13. **Command Center** — decision cards, emergency mode.

## Interaction notes

- Bottom sheets for map details (fast tap-through).
- FAB for quick incident capture on field shell.
- Pull-to-refresh on list screens (respects sync policy).
- Purposeful animations only: page transitions, alert arrival,
  dashboard updates, emergency transition. Reduced-motion respected.
- Touch targets ≥ 48dp; large forms runnable with one hand.

## Empty / loading / error / offline

Every screen must render:
- **Loading** skeleton or progress.
- **Empty** explanation + action.
- **Error** readable message + retry.
- **Offline** explicit offline banner + last-synced timestamp.
- **Unauthorized** permission explanation + contact path.
- **Stale** last-updated badge.

## Accessibility

- Semantic labels on all meaningful widgets.
- Semantics live region for realtime alerts.
- Scalable text (textScaleFactor respected).
- High-contrast-friendly presentation.
- Non-color-only status communication.
- Voice-note input option is a PRD non-functional (staged).

## No mock data in production

- `DATA_MODE=demo` results carry a visible DEMO badge (server labels
  SIMULATED/DEMO). Client must not strip those labels.
- No fabricated risk/route/shipment/incident values in production UI.