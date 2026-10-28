# AGENTS.md

## Project
Single-phone helper for the physical party game Mafia: collect player names, deal roles by passing the phone, then show a timer. Everything else in the game happens in real life. Read `docs/PRD.md` and `docs/ARCHITECTURE.md` before writing any code; they are the source of truth.

## Stack
Flutter (Android first), `flutter_bloc` (Cubit only), `get_it`, `equatable`, `shared_preferences`, `wakelock_plus`. No other dependencies without asking.

### P0 pinned versions and approved decisions
- Toolchain: Flutter 3.47.1, Dart 3.13.1, Android SDK 36.
- Runtime: `flutter_bloc` 9.1.1, `get_it` 9.3.0, `equatable` 3.0.0, `shared_preferences` 2.5.6, `wakelock_plus` 1.8.2, `lottie` 3.7.0.
- Development: `flutter_lints` 6.0.0, `bloc_test` 10.0.0, `flutter_launcher_icons` 0.14.4.
- Flutter SDK packages: `flutter`, `flutter_localizations`, `flutter_test`. `flutter_localizations`, `lottie`, and `flutter_launcher_icons` are approved additions. No direct `intl` dependency until P4; `cupertino_icons` is removed.
- Arabic app title and Android label: مافيا. Android only; never run `flutter create`.
- Cairo is bundled at 400, 600, and 700. Display styles use 700 instead of the design's unavailable 900; section headings use 600, bodyStrong uses 700.
- Adaptive icon: canvas `#0B0B0B`, original `logo.png` foreground, 25% inset. Never redraw, recolor, crop, or stretch the logo.
- Keep the P0 placeholder until P2.
- Keep `kotlin.incremental=false`: Kotlin's incremental cache fails across the C: pub cache and E: project drives.
- Include project `.agents/` skills and the Gradle wrapper scripts/JAR in the repository (user approved).
- Documentation gaps remain unresolved: `docs/TASKS.md` references missing `docs/ARCHITECTURE.md` section 10 and `docs/DESIGN_STYLE.md` section 7.1. Ask before defining those sections.

## P4 approved decisions
- Discussion timer defaults to 3 minutes and is adjustable from 00:01 to 99:59.
- Timer expiry uses Flutter haptic feedback plus a small Android method channel (`mafia/timer_feedback`) to play the system notification sound through `RingtoneManager`. The native bridge is user-approved because Flutter's `SystemSoundType.alert` is ignored on Android. No audio assets or packages are added.

## Commands
- Run: `flutter run`
- Analyze: `flutter analyze` (must be clean)
- Test: `flutter test`
- Format: `dart format .`

## Hard rules
1. `features/*/domain` is pure Dart: no Flutter imports, no `BuildContext`.
2. Widgets contain no game logic. Logic lives in domain classes or Cubits.
3. Never branch on a role `id` to change behavior. Game logic reads `Role.team` only. Roles are data: all names, descriptions, and teams are edited in `role_catalog.dart` only.
4. Role abilities are not implemented. Night phase, voting, eliminations, and win detection are out of scope.
5. All user-facing text goes through `strings_ar.dart`. UI is Arabic, RTL.
6. Role assignments live in memory only (`GameSession`). Never persist them. Only player names are persisted.
7. Timer uses an end timestamp, never tick counting.
8. The host roles view opens by long press only and auto-closes.
9. Do not copy artwork, icons, or text from other apps. Use original placeholders.
10. Do not add features, screens, settings, or packages that are not in the PRD. If something seems missing or ambiguous, stop and ask. Do not guess.

## Workflow
- Follow the build order in `ARCHITECTURE.md` section 9, one step at a time.
- Before each step, give a short plan (files to create or change) and wait for approval.
- Write tests for the validator, distributor, and timer math as part of their step, not later.
- After each step: run `flutter analyze` and `flutter test`, then report what you verified and what you did not verify. Do not claim something works unless you ran it.
- Keep diffs small and focused. No unrelated refactors or renames.

## Code conventions
- Immutable states (`Equatable`), `const` constructors where possible.
- Cubits are registered as factories in `core/di.dart`; `GameSession` and `PlayersStore` are lazy singletons; `Random` is registered so tests can override it.
- File names `snake_case.dart`; one public class per file where reasonable.
- No `print`. No commented-out code. Prefer small widgets over large `build` methods.

## Definition of done (MVP)
Full flow works on an Android device: names -> setup -> reveal loop -> timer -> back to names with names kept -> new round. Validation blocks invalid setups with a visible reason. All tests pass and `flutter analyze` is clean.
