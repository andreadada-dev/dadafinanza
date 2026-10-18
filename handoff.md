# BALYN / DadaFinanza — HANDOFF (2026-10-18)

## Read this first in the next chat

Repository: `andreadada-dev/dadafinanza`.
Current UI work branch: `fix/balyn-visible-liquid-background`.
**Do not merge into `main` unless the user explicitly asks.**
Local checkout mentioned previously: `E:\dev\dadafinanza`.

**The redesigned Home is the canonical design reference, including its
placement, spacing, controls, motion, and palette.** Do not restart from old
screens (or blindly replicate the old Home). Keep old features and finance
data, but move old visuals to the redesigned design system.

## Design source of truth — real code, not screenshots

| What to implement / replicate | Dart reference |
| --- | --- |
| App-wide theme, colors, dark/light, forms, dialogs, buttons and selected states | `lib/theme/balyn_palette.dart` and `lib/theme/app_theme.dart` |
| Layout of the **new Home** and widget spacing/order | `lib/screens/account_context_home_screen.dart` |
| Home Hero, account selector, swipe gesture, buttons and title dropdown | `lib/widgets/balyn_revolut_home_hero.dart` |
| O'Mesh gradient geometry, subtle shared-clock movement, per-account adjacent-color hues | `lib/widgets/balyn_omesh_hero_background.dart` |
| Section strip: Panoramica / Movimenti / Analisi | `lib/widgets/balyn_cue_section_bar.dart` |
| One canonical **Cue expanding action menu**, shared by Hero “Altro” and corner “+” | `lib/widgets/balyn_cue_anchored_menu.dart` |
| “Altro” trigger in the Hero, managing accounts / advances / dashboard / customizer | `lib/widgets/balyn_cue_three_dots_action.dart` |
| Bottom-right action trigger, spring/stretch dynamics, actions | `lib/widgets/balyn_quick_action_launcher.dart` |
| Shell, navigation, scroll-delta signal for the morphing FAB | `lib/screens/app_shell.dart` |
| Unified rounded content card / headings / icons | `lib/widgets/balyn_editorial_components.dart` |
| Configurable Home sections: real data, consistent cards | `lib/widgets/home_dashboard_widget.dart` |
| Financial summary / accounts / monthly card | `lib/widgets/balyn_revolut_home_content.dart` |
| Recent activity card and action navigation | `lib/widgets/balyn_recent_transactions_card.dart` |
| Movement history, filters and category pages | `lib/screens/account_context_transactions_screen.dart` |
| Trends, cash-flow bars, global period selector and same category donut as Home | `lib/screens/account_context_analytics_screen.dart` |
| Transaction editor/detail page | `lib/widgets/balyn_transaction_detail_content.dart` |
| “Personalizza Home”: drag-reorder, add/hide, expandable real preview | `lib/screens/settings_screen.dart` (DashboardCustomizerScreen) |
| Persisted Home widget catalog, migration and deduplication | `lib/widgets/balyn_home_widget_catalog.dart` |
| Skeleton loading when real data is pending | `lib/widgets/balyn_data_skeleton.dart` |
| Onboarding velvet shader (distinct from the Home mesh) | `lib/widgets/balyn_onboarding_velvet.dart`, `shaders/balyn_onboarding_velvet.frag` |
| Shared global shader clock and non-restarting screen background | `lib/widgets/balyn_shader_system.dart` |

Also read `docs/BALYN_VISUAL_SYSTEM.md` before touching another screen.

## Canonical palette

Use the actual tokens from `lib/theme/balyn_palette.dart` rather than
hardcoded colors:

- Primary brand purple: `#7955EB`; primary text violet in dark mode:
  `#AE94FF`.
- Dark page background: `#101018`; card surface: `#252532`;
  raised surface: `#30303D`.
- Main dark text `#F5F4F9`, secondary text `#A3A5B6`.
- Light mode: page `#F7F8FA`, card white.
- Finance income green `#38E0A8` dark / `#12B880` light;
  expense red `#FF7373` dark / `#F53D3D` light.
- Radius for cards 22dp and form fields 16dp.
- Account/category-specific colors are intentionally dynamic; do not
  replace them with one universal purple.

Style: **flat, clear Revolut-style cards**. Avoid random cyan/teal as a
complementary Hero color, redundant outlines, deep nested containers, or
gray legacy rectangles. Keep text clear and accessible at larger system
font scales.

## Motion and interactions

1. **Hero**: 3×3 O'Mesh “Basic Usage” inspired arrangement. Only interior
   points move slightly, driven by the global shared clock. For total
   portfolio purple, blend toward **pink/lilac**, not teal. For green
   accounts, blend dark green into **lime**, not purple/red. For blue
   accounts use nearby cool-blue shades. The Hero draws from account
   `colorValue`. No animated left/right diamond arrow widgets. Account
   switching remains possible by horizontal swipe and the account
   selector (title + plain down chevron).
2. **Cue menus**: both Hero “Altro” and corner “+” use
   `BalynCueAnchoredMenu`, which owns the dark barrier, shared motion,
   pill shape, action order and dismiss/close control. Never create a
   different action overlay for the + menu.
3. **FAB morph**: `BalynMorphingFab` reacts to the horizontal/vertical
   scroll delta delivered as `ValueListenable<Offset>` from
   `BalynAppShell`; the trigger briefly stretches/squashes and
   returns to a circle. Avoid morphing the modal action pills or
   relocating actual hit targets. Respect reduce-motion settings.
4. **Home settings**: allow the user to add/hide each section without
   duplicates, drag its handle to reorder, expand the downward chevron
   to preview the real widget and change its size. Never reset the
   chosen order every time the app launches.
5. **Analytics**: one global date-range selector above all charts;
   account-color-aware bars, clipped line chart and the SAME category
   donut component from Home.
6. **Onboarding** has a separate velvet-like shader and soft beams,
   not the O'Mesh Hero everywhere.

## Behavior that must not regress

- All existing accounts, balances, currencies, categories, tags, receipts,
  transaction history, advances, planning, import/export, settings and
  localization still work.
- Privacy toggle hides amounts, including inside graph/preview content.
- App boot uses Skeletonizer only while real async data is loading.
- The account selector and Hero horizontal swipe still change the
  selected account even though visible side diamonds were removed.
- Hero "Altro": manage accounts, advances, advanced dashboard, customize
  Home. Corner "+": movement, advances, plan, optional Home. Long press
  continues to open the legacy presets/voice menu.
- The corner FAB dimming and closure should behave just like "Altro".
- No overly saturated/gratuitous gradients or background reinitialization
  when navigating.

## Cue + Flutter 3.47 compatibility

The `cue` package uses the new standalone `package:material_ui` material
localizations, while most of Balyn still imports
`package:flutter/material.dart`. These are **different runtime types**.
`lib/main.dart` explicitly installs both
`mui.GlobalMaterialLocalizations.delegate` and Flutter's
`GlobalMaterialLocalizations.delegate`. Do not remove either while the two
libraries coexist; without the material_ui delegate Cue will assert
"No MaterialLocalizations found" when a menu opens in debug builds.
Use both delegates in widget integration tests of the action menu too.

## Verification and future workflow

- Use branch `fix/balyn-visible-liquid-background`.
- Run `flutter pub get`, `dart format lib test`,
  `flutter analyze`, `flutter test`, and an Android build.
- Project CI has used Flutter **3.47.2**. Check actual pinned SDK in
  `.github/workflows` and `pubspec.yaml` before changing it.
- Tests to review first:
  `test/home_glass_navigation_test.dart`,
  `test/home_summary_layout_test.dart`,
  `test/balyn_omesh_hero_background_test.dart`,
  `test/balyn_canonical_design_system_test.dart` and tests in
  `test/balyn_*`.
- Check narrow Android screen widths, long Italian labels, reduced-motion,
  system text scaling, modal overlay alignment, light/dark themes,
  account color changes, and swipe direction by hand.
- Do not claim a CI build or screenshot review succeeded before reading
  the actual run status.
- Any temporary workflow used only to format Dart should be removed once
  it has finished. Preserve existing release/publish workflows.

## Current task implemented on this branch

- Removed Hero side navigation diamonds; account swiping stays.
- Changed balance title diamond into a simple down chevron.
- Adjusted mesh from opposing purple/cyan toward analogous account hues.
- Refactored the header and bottom FAB action menus to the same Cue menu.
- Added a bounded elastic scroll-direction response on the FAB circle.
- Verify these edits with CI and an actual Android device before merging.
