# DadaFinanza

Private-first personal finance app built with Flutter.

## Goals

- Fast expense/income capture with a strong one-handed mobile flow.
- Multiple accounts, transfers, categories, tags, notes and optional receipt photos.
- Local SQLite storage: financial data stays on-device by default.
- Recurring payments/reminders, budgets, adaptive goals and useful analytics.
- Deterministic on-device Smart Suggestions learned from the user's own history.
- Android home-screen widget for balance visibility and one-tap quick expense entry.

## UX direction

DadaFinanza is dashboard-first: balance, cash flow, budget status, planning signals and recent transactions are visible without opening secondary menus. Quick Add is always one tap away. The UI uses a flat Material 3 hierarchy with neutral surfaces, restrained semantic colors and accessible touch targets.

## Smart planning

Smart Suggestions, recurring-pattern detection, forecasts and goal planning run locally and deterministically. Suggestions require sufficient confidence and remain reversible. Explicit user rules take precedence over learned patterns.

Goal progress uses an explicit local ledger. A transfer prepared from a linked goal records a ledger entry; editing or deleting that transfer updates the goal automatically. Budgets are treated as spending ceilings rather than guaranteed future expenses, so the adaptive goal planner only reserves a conservative margin above normal historical spending.

## Android widget

The Android widget displays the current total balance and shortcuts for common expense categories. Tapping a category launches the Quick Add screen with that category already selected. Widget data is synchronized through `home_widget`.

## Privacy

DadaFinanza is local-first and does not require an account. The public privacy policy is available in [docs/PRIVACY_POLICY.md](docs/PRIVACY_POLICY.md).

## Release

Validation runs on self-hosted runners without consuming GitHub artifact storage. Internal APK builds and signed Google Play AAB builds are exported to the local `/builds/dadafinanza` mount. Production AAB generation requires release-signing secrets and cannot silently fall back to debug signing.

## Status

Active Flutter/Android implementation covered by formatting, analyzer, widget/unit tests and Android build validation in GitHub Actions.
