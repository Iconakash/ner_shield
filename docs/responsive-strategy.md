# NER-SHIELD — Responsive Strategy

## Target (Android-first)

- Primary: Android phones (small → large), portrait + landscape.
- Secondary: Android tablets (foldables / tablets), portrait + landscape.
- No dedicated iOS/Web/Desktop work (per master prompt §4).

## Breakpoints (Material-style)

| Class | Width | Layout |
|---|---|---|
| Compact | < 600 | Single pane; bottom nav (Geometry-independent) |
| Medium | 600–839 | Single pane with rail / two-pane list-detail (tablet portrait) |
| Expanded | ≥ 840 | Split panels (list + detail / map + panel) |

Implement via `LayoutBuilder`/`MediaQuery` + a small `ScreenType` helper, not
scattered conditions.

## Per-screen adaptation

- **Map:** always full-bleed; detail panels become floating cards on
  compact, side sheet on expanded.
- **Dashboard:** KPI grid 2-col compact → 3-col tablet → 4+ col expanded.
- **Lists:** list (compact) → list + detail split (expanded).
- **Forms:** single column compact; two-column field groups on expanded.
- **Bottom nav:** NavigationBar (compact) / NavigationRail (expanded).

## Orientation

- Portrait is primary.
- Landscape allowed on map/detail screens; forms remain scrollable.
- Rotation must not lose in-progress form state (persist in controller,
  not local widget state).

## Testing

- Widget-test the ScreenType helper.
- Run app on a small phone, large phone, and tablet emulators; verify no
  overflow errors at default and 1.3 text scale.