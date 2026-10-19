# Balyn — Figma Revolut home visual audit

Source: https://www.figma.com/design/YmHg8sF5F0oZ8n24bZUDmL/Revolut-FREE-UI-Kit---By-Marvilo--Community-?node-id=1-4

## Reference coverage
- Screen node `1:4`, section `8:3104` (editable Home study) and six Home variants:
  `3:14`, `8:1221`, `8:1571`, `8:1921`, `8:2223`, `8:2429`.
- `3:14` includes a 425 px wide mobile canvas, approximately 16–18 px side gutters, 390 px content cards, a strong top gradient with centered balance, 4 circular actions, and a compact bottom navigation.
- Transactions (`2:28989`) use aligned “Transaction / Amount” headings, approximately 94 px rows, 40–44 px icons with a secondary badge, two-level metadata, and a centered “See all” action.
- Other Home variations reuse modular “Widgets” blocks: spend this month, wealth, payment reminders, account grouping, and recent payees. These are content layouts, not just decorative rectangles.

## Adaptation to Balyn
- Do not copy Revolut marks, static promo imagery, investment claims or fictional data.
- Hero uses the selected real account color, with an accessible lightness/saturation transform, and a purple Balyn fallback for total wealth.
- Absolute optical centering of the hero’s balance: the hide/show button occupies an overlay and does not shift the amount; left/right switchers have symmetric widths.
- Tap the small diamond beside the title for account picker; left/right animated diamonds and horizontal swipes cycle over Totale + active accounts, preserving global account context.
- Hero motion honors reduced-motion settings and animations are disposed when widgets unmount.
- Transaction list is a native, accessible Flutter view using category icons and actual movements; never fake merchant names, dates, status or balances.
- Preserve hidden amount setting both globally and on an individually hidden account.
- Compact editorial cards: plain surfaces, smaller corner radius, very light dividers (or none), blue interactive labels, generous typography contrast, 16 px horizontal gutters.
- Home retains existing configurable widgets under the primary summary, never duplicates core widgets in personalization.
- Attività remains one top-level destination with Movimenti / Analisi segmented views. Anticipi and Pianifica reuse clean finance cards and same information hierarchy.

## Validation
- `dart format --output=none --set-exit-if-changed lib test`, `flutter test`, `flutter analyze`.
- Check 320/360/390/425 dp widths, selected accounts with unusually light colors, global + per-account privacy, dark/light theme, account swipe/select, live transactions, and navigation.
- Keep this change on `fix/balyn-visible-liquid-background` until Android device screenshots are reviewed.
