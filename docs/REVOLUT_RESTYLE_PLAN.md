# Balyn — redesign Revolut-inspired

## Source
Figma community UI kit: https://www.figma.com/design/YmHg8sF5F0oZ8n24bZUDmL/Revolut-FREE-UI-Kit---By-Marvilo--Community-?node-id=4001-559

The supplied node 4001:559 represents "Revolut Cards", an image-backed frame, **not** the entire app flow. Use the whole kit as a visual reference rather than pasting a raster image into Flutter. Do not copy Revolut trademarks/logos; retain Balyn branding.

## Constraints
- All changes isolated to `design/revolut-ui-restyle`; never merge to main without explicit request and passing CI.
- Preserve models, SQLite schema, services, finance calculations, accounts, transactions, presets, backup/export, localization, accessibility and security.
- Maintain dark/light/system themes, and respect per-element shader toggles without visual artefacts.
- Build reusable Flutter UI components, not a screen-size-dependent static mockup.
- Avoid fake banking functionality; Balyn is a local-first finance tracker.

## Design foundation (begun)
- Blue accent #0666EB / light text on blue
- Light: white canvas, #F2F4F7 raised surfaces, #141A23 primary ink
- Dark: #0D1018 canvas, #1B2330 raised surfaces, #F8FAFD ink
- Simple typography hierarchy, edge-to-edge content where useful, whitespace, minimum 48dp tappable targets
- Source of truth: `lib/theme/app_theme.dart`

## Screens to rework
1. `lib/screens/app_shell.dart`: consistent navigation, account context, prominent but non-obstructive primary action.
2. `lib/screens/account_context_home_screen.dart`: hierarchy of net worth/available balance, quick actions, spending/income, charts, accounts, recent movements.
3. `lib/screens/account_context_transactions_screen.dart`, `quick_add_page.dart`: discoverable transaction list, clean edit/create forms, categories, transfers.
4. `lib/screens/account_context_analytics_screen.dart`: clear pie/bar/line visualizations, legible scales, ranges and legends.
5. `lib/screens/advances_screen.dart`, `planning_screens.dart`: consistent cards, status, actions.
6. `lib/screens/account_management_screen.dart`, `category_management_screen.dart`: account / category CRUD, accessible menus and destructive-action confirmations.
7. `lib/screens/personal_settings_screen.dart` and settings-related pages: regrouped settings, language/theme/toggles intact.
8. Reuse shared components in `lib/widgets`; avoid replacing business logic with placeholder values.

## Verification before merge
- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug` on an appropriate runner
- Screen-by-screen checks at 360dp and 412dp, large text scale, light/dark/system themes.
- Confirm back navigation, accessibility labels, balance privacy, quick add/transfer, persistence, account filtering and export.
- Apply `checkbeforepushing.md` and review visual differences against the reference.
