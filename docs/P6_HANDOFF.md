# P6 review and handoff

Audit date: 2026-10-28. Baseline: clean `main` at `d73da191073bed62bb5beb7f47a0cab455644b48` (P5).

P6 adds acceptance evidence, animation-failure regression coverage, and final working instructions. Production Dart/Kotlin code, dependencies, assets, platform folders and game rules are unchanged.

All required demo steps, FR1–FR6 checks and Design Style section 13 checks passed within the test/emulator scope described below. No physical Android device was tested.

## Run and verify

Use Flutter 3.47.1 / Dart 3.13.1 and Android SDK platform 36, build-tools 36.0.0. Exact package versions remain in [AGENTS.md](../AGENTS.md) and `pubspec.yaml`; the app version is `1.0.0+1` and package is `com.example.mafia`.

```powershell
flutter run -d emulator-5556
flutter analyze
flutter test --timeout 45s
dart format .
dart format --output=none --set-exit-if-changed .
flutter build apk --debug
& 'E:\Programs\Android\platform-tools\adb.exe' devices
& 'E:\Programs\Android\platform-tools\adb.exe' -s emulator-5556 install -r build/app/outputs/flutter-apk/app-debug.apk
```

Check connected devices before selecting one; the ID above is the tested emulator, not a requirement for another machine. Never run `flutter create`. Keep `kotlin.incremental=false` for the cross-drive pub cache/project layout.

| Gate run for P6 | Result |
| --- | --- |
| `flutter analyze` | Passed, no issues. An initial unnecessary import in the new test was removed. |
| `flutter test --timeout 45s` | Passed, all **152 tests**; P5 had 145. |
| `dart format .` | Passed, 73 Dart files, zero changes on final run. |
| Format check without edits | Passed. |
| `flutter build apk --debug` | Passed; APK at `build/app/outputs/flutter-apk/app-debug.apk`. Installed and built APK SHA-256 both `d264e58d495764e6c35c7f9495fbf3490027597d76690ce748f8a855171780bb`. |
| `git diff --check` | Passed. |

`flutter doctor -v` confirms the versions above but reports some Android licenses unaccepted. Debug compilation succeeds; licenses were not accepted or changed by the audit. Release signing still uses the template's debug key. No production-signed build, release install or store submission was tested.

## Required seven-player demo

Run against the real installed app on `emulator-5556`, Android 16 / API 36, at native 1080×2400 / density 420. Automated input used seven Latin test names, including a long name; long Arabic names are covered by widget tests. Only known prior verification names were removed, using the UI.

| Step from TASKS.md | Result and observed evidence |
| --- | --- |
| Add 7 players | Passed. Added all seven through the name field; decoded stored names matched exactly. |
| Enable godfather, detective, doctor and jester; set 2 mafia | Passed. Enabled godfather/jester alongside the default detective/doctor and increased mafia to 2. |
| Validation passes | Passed. Deal was enabled for this exact configuration. |
| Deal and complete every reveal | Passed. All seven handoffs showed the current name without role descriptions. Each reveal showed exactly one catalog role and its matching description; hiding advanced in order. |
| Long-press host sheet and verify counts | Passed. All seven host rows matched the reveals: **1 godfather, 1 mafia, 1 detective, 1 doctor, 1 jester, 2 citizens**. All three teams had text labels. Tap showed only the hint; a 1.2-second hold opened the sheet; it auto-closed after 10 seconds. |
| Set 1 minute, start, pause, resume, finish | Passed. Configured `01:00`, paused at 58 seconds, verified the paused value remained stable, resumed, and waited for real-time expiry at `00:00` with the finished label. |
| Leave through confirmation; names kept | Passed. Hardware Back showed confirmation; confirmed exit returned to Players. Decoded storage retained the exact seven names. |
| Deal another round with different setup | Passed. Changed to 1 mafia and no specials, completed all seven reveals, and checked the host sheet: 1 mafia and 6 citizens. Exited through confirmation with names retained. |

Additional P6 timer observations: after resuming, opened the sheet and backgrounded the app. Return showed 49 seconds left with no sheet; manual emulator sleep/wake returned with 43 seconds left. WindowManager showed a hold-screen window for the app. Android diagnostics recorded notification playback starting at 06:34:32.227 and stopping at 06:34:34.752, and a completed app haptic event at 06:34:31.538. Captured finish logs contained no Flutter unhandled exception or native fatal exception. Physical sound/vibration were not heard or felt by the agent.

## PRD functional requirements

| Requirement | Verdict | Reason and verification |
| --- | --- | --- |
| FR1: injectable random dealing | Passed | Fixed-seed determinism, changing seeds, counts, invalid input, exactly-once specials and godfather inside mafia slots are tested. The documented seven-player configuration passed both domain tests and the Android demo. Source uses `List.shuffle` with the injected `Random`; uniformity follows that algorithm, not an exhaustive statistical experiment. |
| FR2: round assignments in memory only | Passed | `GameSession` is the only holder. Confirmed-exit tests verify clearing and disposal. P6 decoded Android DataStore contains only `player_names`; P5 additionally killed the app during an active reveal and verified names-only restoration. |
| FR3: timestamp timer across lock/background | Passed on emulator | Timer uses injected `now`, `endAt - now`, and a periodic display refresh. Tests cover long gaps, pause/resume and finish once; the P6 one-minute run continued through background and manual lock. No physical-device screen-lock/idle-timeout test. |
| FR4: names survive restarts | Passed | Store recreation and cold-app tests pass. P6 force-stopped/relaunched after the second round and restored the exact seven names; decoded DataStore matched. |
| FR5: protected host view | Passed | Tap and a short hold reveal nothing; the one-second threshold, matching rows, ten-second close, and background/hidden/inactive closure are tested. P6 exercised tap, full hold, auto-close and background close on Android. |
| FR6: Android Back confirms | Passed | Handoff, Reveal and Timer use shared confirmation. Cancel preserves the round; confirm clears it and returns to Players. Tested in widgets and Android smoke checks. Back on the sheet dismisses only the sheet; Back on a confirmation cancels it. |

## Animation audit

| Screen | Asset, bounds and motion | Result |
| --- | --- | --- |
| Players, empty only | `mafia_loading.json`, 120 logical pixels square; removed once a name exists. Reduced-motion test loads the actual file and confirms `animate=false`, no controller. | Passed. |
| Game Setup | No Lottie. | Passed. |
| Handoff and Reveal | Same `mafia_loading.json`, 160 square, same position, colors and layout for every catalog role. No team/role branch or artwork. | Passed. All ten roles and immediate hide/next are exercised in widget tests, including an active animation. |
| Timer | `mafia_clock.json`, 120 square; idle first frame, running loop, paused current frame, finished final frame, reset first frame. Reduced motion stays static in every phase. | Passed. Controller lifetime/disposal and independence from countdown duration are tested. |
| Host sheet | No Lottie; countdown bar is a widget-owned animation that stops animating under reduced motion. Auto-close timer remains active. | Passed. |

Every animated screen has at most one bounded `AppLottie`. `Lottie.asset` appears only inside that wrapper. `test/widgets/animation_failure_test.dart` injects missing assets and malformed JSON into each consuming screen, verifies the bounded empty fallback, and operates add-player, reveal/hide/next, and timer start/pause/resume/finish. Existing foundation tests use a deliberately wrong asset path. Existing reveal/timer tests cover static motion and controller behavior. Missing or corrupt decorative files do not block actions or expose a prior role.

## Design Style section 13 checklist

| Item | Verdict and evidence |
| --- | --- |
| Dark brutalism: thick off-white lines, red, sparse hard shadows | Passed. Rendered Players, Setup, host sheet and Timer inspected; central theme matches tokens. |
| One dominant strongly styled element per screen | Passed. Hard shadow is confined to the primary action or Reveal card; Reveal hide action is secondary. Timer's outlined panel and flat secondary controls follow S5. |
| Same Handoff/Reveal presentation across roles | Passed. All-role widget comparison checks asset, size, position, typography and card decoration; no team branches in the flow. |
| Team colors only in host sheet, paired with text | Passed. Source scan finds team color use only in `host_role_row.dart`; rendered sheet includes all three labels. |
| Long press opens sheet; tap shows hint | Passed. Android demo and gesture tests. |
| Large stable LTR `mm:ss`; clear finish without flashing | Passed. Widget tests check direction, phases and styling; `FontFeature.tabularFigures()` is set. Actual one-minute run reaches the clear finished panel. Prior P4 digit-width measurements verified the bundled font's stable digits. |
| RTL, large text, keyboard and long names at 320/360 | Passed in widget suite. Players/Setup, Handoff/Reveal, Timer, sheet and dialogs are exercised; Timer also covers 390/430. P6 Android checks exercised Players, Setup, Handoff, Reveal and confirmation at 320 width with 2× text; P5 also checked the keyboard, and P4 the large Timer/sheet. |
| Rendered contrast: white/red, disabled and secondary text | Passed by exact screenshot-color samples: white/red **5.008:1**, disabled Next/surface **7.152:1**, secondary hint/canvas **7.779:1**, team label/surface **7.152:1**. Samples are from actual component regions, not status-bar pixels. |
| No gradients, blur shadows, tilt or copied artwork added | Passed. Source scan and rendered inspection; hard offsets have zero blur. P6 adds no assets; original user-supplied assets remain unchanged. |
| Scope remains the PRD helper | Passed. No night actions, voting, elimination, win detection, abilities, account, network feature, settings or package added. |

Launcher icon: passed on the emulator home screen. Visually inspected the original logo on its dark adaptive canvas with the Arabic label `مافيا`; tapping it opened Players. At 320 logical width and 2× text, exercised Players, scrolled Setup, dealt, revealed, cancelled the exit dialog, then confirmed exit. The role and dialog text wrapped, actions stayed usable, the seven names remained saved, and `mInputShown=false` confirmed no reopened keyboard. After exit, WindowManager reported `mHoldScreenWindow=null`. Display overrides were reset and verified at physical 1080×2400 / density 420 / font scale 1.0. Repository inspection confirms `android/` is the only platform folder; no platform was recreated.

## Architecture and review

Reviewed with the local `flutter-code-review` and `flutter-ui-cleanup` skills against the project's explicit simple Cubit architecture. Their generic repository-layer examples do not override the documented direct `SetupCubit -> PlayersStore` design; no new repository layer was introduced.

- Domain imports are pure Dart plus Equatable. Cubits/state contain no plugin, animation, context or Arabic interface text. Role IDs perform catalog selection only; mafia-slot calculations use `Team`.
- Assignments are immutable, in memory; persistence is isolated to `PlayersStore`. Queued snapshots and error propagation/recovery have tests. Arabic role content remains in `role_catalog.dart`; interface text remains in `strings_ar.dart`.
- Widgets own navigation and platform effects. Clock, host countdown/close timer, focus/text controllers, lifecycle observers and ticker subscriptions have disposal paths. Existing tests verify wake-lock release and no late alert after round exit.
- Feature widgets are modular and data/callback-driven. Builders are scoped to changing fields; the animation subtree stays separate from timer tick rebuilds. No production refactor was needed for P6.
- Tests cover empty/finished sessions, invalid configurations, duplicate and empty names, stale completions, failed reads/writes, repeated dialog callbacks, inaccessible prior reveals and complete second rounds.

## Known issues, deviations and untested assumptions

- No blocking product defect found in completed checks. Physical Android hardware, speaker audibility, vibration strength, automatic physical screen timeout and OEM-specific lifecycle behavior remain unverified. An emulator hold-screen flag is evidence of wake-lock use, not proof across physical devices.
- No release/profile performance benchmark, production signing, Play installation, TalkBack session or disabled-network run was performed. Semantic labels and responsive behavior were checked in widgets; offline behavior is inferred from bundled assets and lack of network code.
- Device clock/date changes during a running timer were not tested; the intended clock is wall time. A process kill discards the round and timer by design and returns to names on restart.
- PRD player limits remain the approved 4–25 assumption. Spy, hunter and gambler remain civilian with `TODO: confirm`; no team decision was invented. Names are trimmed and duplicates compared exactly, without case folding or Unicode normalization.
- The approved native Android notification-sound bridge replaces Architecture's ineffective Flutter alert sound call. P0 approved Cairo weights 400/600/700 replace unavailable 900. No direct `intl` dependency was added: duration is stepper-controlled and digits are formatted centrally as Western LTR text.
- The known missing Architecture section 10 and Design Style section 7.1 remain unresolved as approved; the explicit approved animation map governs placement.
- A test-harness selector initially matched a role label instead of its switch. It was corrected before the successful demo. This did not require a production fix. Verification fixtures are test names only.

## Future changes require a new approved scope

To resolve the three team TODOs, obtain the intended team for each role, change its `team` field in `lib/features/roles/domain/role_catalog.dart`, remove that TODO, and rerun validator/distributor/setup/host-sheet checks. Slot consumption and team labels already read the team; do not add role-ID behavior. If future choices create multiple mafia specials, verify their combined minimum mafia bound as well.

Role abilities are outside this MVP. Adding them would first require revised PRD/architecture and explicit rules for targets, timing, conflict resolution, host authority and secrecy. It would then require new pure-domain models/services for actions and phases, state/UI for host interactions, and rules/privacy tests. Night, voting, eliminations, win detection or round persistence would each need separate scope decisions. Do not attach behavior to the current descriptive role catalog or start this work from the handoff.

## Evidence and continuation

Local, ignored `build/p6-verification/` contains the demo script/results, assignment lists, screenshots, decoded names-only DataStore snapshots, contrast samples, SDK diagnostics and gate logs. Earlier `build/p3-verification/`, `build/p4-verification/` and `build/p5-verification/` may contain supporting phase evidence. These directories are not committed and may be removed by a clean build; this document records their durable conclusions.

P6 changes are limited to this document, the `AGENTS.md` update and `test/widgets/animation_failure_test.dart`. No push or history rewrite is part of this handoff. The commit message is `P6: review and handoff`; use `git log -1` to obtain its hash.
