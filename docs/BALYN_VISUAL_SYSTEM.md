# Balyn visual system — Home is the source of truth

The redesigned Home defines the baseline for **every** route (including legacy
settings, activity, advances, planning, account and category editors, modals,
and the old advanced dashboard).

## Canonical tokens

Source: `lib/theme/balyn_palette.dart`. Material defaults are derived in
`lib/theme/app_theme.dart`.

| Element | Dark | Light |
| --- | --- | --- |
| Background / page canvas | `#101018` | `#F7F8FA` |
| Surface / card / sheets | `#252532` | `#FFFFFF` |
| Nested controls / raised state | `#30303D` | `#F0F0F6` |
| Main action brand purple | `#7955EB` | `#7955EB` |
| Readable accent text | `#AE94FF` | `#6B43D4` |
| Primary text | `#F5F4F9` | `#191721` |
| Secondary text | `#A3A5B6` | `#676779` |
| Financial income | `#38E0A8` | `#12B880` |
| Financial expense | `#FF7373` | `#F53D3D` |

- **One brand accent**, not per-screen blue/teal/orange toolbar or tab chrome.
  Financial states (income, expense, alerts), custom account colors, and
  category colors retain their own meaning.
- Card radius: **22 dp**; input radius: **16 dp**.
- Use one surface per information module, not bordered cards nested three
  levels deep. Prefer `BalynEditorialSurface` and the inherited `CardTheme`.
- For dialogs, forms, menus, tabs, switches and selection controls use
  `Theme.of(context).colorScheme` and the global component themes instead of
  creating local palettes.
- Keep the Scaffold transparent so the shared `BalynShaderBackdrop` does not
  disappear across route transitions. Its static fallback is the same canvas.
- The O'Mesh Home Hero and the velvet onboarding are intentionally distinct
  branded materials, **not** reusable as backgrounds on every data editor.
- For a specific account, use its stored color; for a category, use its stored
  color. Do not overwrite custom user choices with the generic brand purple.
- Maintain contrast, reduced-motion support, and dark/light themes.

## Migration checklist

1. Screen paints its own blue or green app chrome? Replace with scheme primary.
2. Screen uses a bespoke gray page background? Replace with palette canvas.
3. Screen has a manually colored panel? Use palette surface / EditorialSurface.
4. Old text input with borders or inconsistent fill? Use global InputDecoration.
5. Modal or date picker differs from the Home? Use global component theme.
6. New widget added? Add a regression test for tokens and semantics.

All visual changes must pass `dart format`, `flutter test`, `flutter analyze`,
and the Android workflow before merging into `main`.
