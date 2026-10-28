# TASKS.md

> The build order. One phase at a time.
> Read `AGENTS.md` first for the working rules. Scope limits are in `PRD.md` section 7. Structure and state rules are in `ARCHITECTURE.md`. Visuals are in `DESIGN_STYLE.md`.

## How to work through this

1. **One phase per session.** Do not start the next phase until I approve the current one.
2. **Plan first.** At the start of each phase, write a short plan (files you will create or change, and anything you are unsure about) and wait for my approval before editing.
3. **Commit at the end of each phase**, with a clear message, so we can roll back.
4. **Report honestly.** At the end of each phase, report: what was done, what you **verified by running it**, what you **assumed or inferred without testing**, and anything that deviated from the docs.
5. A phase is done only when **every acceptance criterion** is met and the quality gates pass. Quality gates: `flutter analyze` clean, `flutter test` passes, `dart format .` leaves no changes.
6. **Every Cubit and state file is created through `.agents/skills/flutter-cubit/SKILL.md`.** Read it before writing one.
7. If something blocks you, stop and tell me. Do not work around it by adding dependencies, changing the architecture, or widening scope.

---

## P0: Foundation (no features yet)

**Goal:** a clean Flutter base that matches the docs, with the theme, RTL, and DI in place.

Do:
- The Flutter project **already exists**, Android only. The other platform folders were removed on purpose. Never run `flutter create` (including `flutter create .`) and never recreate a removed folder.
- Inspect and report what is actually in place: the docs in `docs/`, the logo in `assets/images/`, the Lottie files in `assets/lotties/` (including the clock animation), `AGENTS.md` at the root, and the skill in `.agents/skills/flutter-cubit/`. If something is missing or in a different place, tell me instead of guessing. The Lottie folder may still be empty when you start; say so.
- Declare `assets/images/` and `assets/lotties/` in `pubspec.yaml`. Create `core/assets.dart` with a constant for every asset path.
- Create `core/widgets/app_lottie.dart` per `ARCHITECTURE.md` section 10: bounded size, a silent `errorBuilder`, and a static frame under reduced motion.
- Configure `flutter_launcher_icons` for Android only from the logo, per `ARCHITECTURE.md` section 10, and generate the icon.
- Install only the dependencies listed in `ARCHITECTURE.md` section 1. Pin exact versions and write them into `AGENTS.md`.
- Create the folder structure from `ARCHITECTURE.md` section 2 (empty folders may hold a placeholder).
- Define the theme centrally in `core/theme.dart`: color tokens, spacing scale, radii, border widths, typography, and the hard-shadow decoration, all from `DESIGN_STYLE.md` sections 4 to 6. Dark only.
- Create `core/strings_ar.dart`, `core/constants.dart` (`GameLimits`: min 4, max 25), and `core/di.dart` (empty registrations).
- Set up Arabic RTL and bundle the Cairo font (weights 400, 700, 900). Set system bars to match `canvas`.
- Portrait only.
- `main.dart` shows one placeholder screen with the title text, using the theme.

Blockers to raise in your plan, not to solve silently:
- Cairo font files must come from me. If they are not in the repo, stop and ask. Do not add `google_fonts`.
- If Arabic RTL needs `flutter_localizations` or `intl`, list it in the plan and wait for approval. The dependency list in `ARCHITECTURE.md` does not include them.
- If the logo does not suit an adaptive icon as is (no transparent background, no safe-zone padding), say so and propose options. Do not redraw, recolor, crop, or stretch it.

Acceptance:
- `flutter analyze`, `flutter test`, and `dart format .` pass. Include at least one trivial passing test so the test command is meaningful.
- The app launches on an Android device or emulator to the placeholder screen: dark background, Cairo text, RTL direction.
- The launcher icon shows the logo on the device home screen (say whether you checked on a real device or an emulator), and the generated Android files are committed.
- Every asset path is a constant in `core/assets.dart`, and `Lottie.asset` is called only inside `AppLottie`.
- If at least one Lottie file exists, the placeholder screen shows it through `AppLottie` as a smoke test, and a deliberately wrong path shows nothing instead of crashing. If no file exists yet, say so and skip this check.
- No removed platform folder was recreated.
- No colors, sizes, or text appear as raw literals outside `core/`.
- No unlisted dependency was added.

## P1: Domain and tests

**Goal:** all game rules exist as pure, tested Dart, before any UI.

Do:
- `features/roles/domain`: `Team`, `Role`, and `RoleCatalog` with the 10 roles, teams, and descriptions from `PRD.md` section 3 (keep the `TODO: confirm` markers for spy, hunter, gambler).
- `features/game/domain`: `Player`, `Assignment`, `SetupConfig`, `SetupValidator` (returns `Valid` or `Invalid(reason)` with a reason enum), `RoleDistributor`, `GameSession`.
- Validation rules exactly as in `PRD.md` section 5, reading limits from `GameLimits`.
- Tests under `test/domain/` for the validator and the distributor.

Acceptance:
- Validator tests cover each rule with boundaries, for example: 4 players with 1 mafia is valid; 4 players with 2 mafia is invalid; 5 players with 2 mafia is valid; mafia plus enabled non-mafia specials equal to the player count is valid; one more is invalid; duplicate and empty names are rejected; 3 and 26 players are rejected.
- Distributor tests: a fixed seed gives a reproducible result; role counts match the config; the godfather is counted **inside** the mafia count; the result length equals the player count; every enabled special appears exactly once; calling with an invalid config throws `StateError`.
- `features/*/domain` has no Flutter imports (show the check you ran).
- No code branches on a role `id` for behavior (show the check you ran). Logic reads `Role.team` only.
- No UI code exists yet.

## P2: Players and Game Setup screens

**Goal:** the owner can enter names, configure the round, and deal roles.

Do:
- `SetupCubit` and `SetupState` (through the skill), registered in `core/di.dart`. `PlayersStore` is introduced here with in-memory behavior behind its final API. Persistence is P5.
- Shared UI primitives from `DESIGN_STYLE.md` section 7 that these screens need: primary and secondary button, labeled input, role toggle card, stepper, validation strip.
- S1 Players and S2 Game Setup, per `PRD.md` section 4 and `DESIGN_STYLE.md` section 8.
- `وزّع الأدوار` calls `deal()`; on success it fills `GameSession` and navigates to a temporary placeholder screen. The real handoff screen is P3.
- Cubit tests with `bloc_test`.
- In your plan, propose which Lottie goes where across all screens, following `DESIGN_STYLE.md` section 7.1, based on the files that actually exist, plus whether the logo appears in-app at all. Wait for my approval. Implement only the placements for S1 and S2 in this phase.

Acceptance:
- The Players empty state shows an animation through `AppLottie` and hides it once a player exists. Any S2 animation does not push the Next button below the fold at 320 width.
- Add, edit, and remove players. Empty or duplicate names show an inline error.
- `التالي` is disabled outside 4 to 25 players, with a visible reason.
- Mafia stepper respects its limits; enabling or disabling roles updates the validation strip immediately. An invalid setup disables `وزّع الأدوار` and states the exact fix.
- Enabled and disabled role cards are distinguishable without color.
- After a valid deal, `GameSession` holds one assignment per player with role counts matching the setup (show how you verified).
- No role names or team hints appear on S1 or S2 beyond the public list of enabled optional roles.
- Layout works at 320 and 360 logical widths, with large system text, and with the keyboard open.
- No Cubit imports a plugin, `BuildContext`, or contains user-facing text.

## P3: Handoff and Reveal

**Goal:** the phone can be passed around the table without leaking roles.

Do:
- `RevealCubit` and its state (through the skill), following the state shape in `ARCHITECTURE.md` section 4 as the doc currently stands.
- S3 Handoff and S4 Reveal, per `DESIGN_STYLE.md` sections 3 and 8.
- After the last player, navigate to a temporary Timer placeholder.
- Add the approved handoff and reveal animations through `AppLottie`. They are identical for every role.
- Cubit tests.

Acceptance:
- The handoff and reveal animations are the same file, size, position, and colors for every role (show the check you ran), and they do not delay or block the hide button.
- Each player sees exactly their own role and description. Handoff never shows any role information.
- `إخفاء والتالي` hides the role immediately and moves to the next handoff. Nothing from the previous role remains in the visible tree.
- Handoff and reveal screens use the **same** colors, layout, and styling for every role. No `team` or role-dependent styling exists in these files (show the check you ran).
- A player cannot go back to a previous player's reveal.
- Android back on these screens does nothing destructive yet (the confirm dialog is P5); report what it currently does.
- Tests: index advances correctly; finishes after the last player; reads from `GameSession`.

## P4: Timer and host roles sheet

**Goal:** a reliable discussion timer, and the host can see all roles safely.

Do:
- `TimerCubit` and sealed `TimerState` (through the skill), with an injectable clock. Remaining time derives from an end timestamp, never from counting ticks.
- S5 Timer: duration steppers, start, pause, resume, reset, finish alert (haptic plus system sound), wake lock while the screen is open.
- S6 Host roles sheet: opens by long press only, shows every player with role and team label, auto-closes after 10 seconds and when the app goes to background. A normal tap only shows the hint `SnackBar`.
- Ask me in your plan for the default timer duration. Do not pick one silently.
- Add the clock Lottie to the timer screen through `AppLottie`, with the controller owned by the screen widget and driven by `TimerState`, per `ARCHITECTURE.md` section 10. If the clock file is not in `assets/lotties/` yet, stop and ask me for it.
- Tests for the timer math using the injected clock.

Acceptance:
- The clock animation is at its first frame when idle, loops while running, stops at the current frame when paused, stops on a clear end frame when finished, and returns to the first frame on reset. Its length is not tied to the timer duration, and the digits stay the source of truth.
- The `TimerCubit` and `TimerState` contain no animation code, and the animation controller is disposed with the screen.
- With reduced motion on, the clock shows a static frame.
- Start, pause, resume, and reset behave correctly. Reset returns to the configured duration.
- The finish alert fires exactly once per run.
- With the clock mocked, pausing and resuming keeps the remaining time correct across a simulated gap.
- The sheet lists every player with the correct role, and team color appears only inside the sheet and always with a text label.
- The timer keeps running while the sheet is open.
- Digits are LTR `mm:ss`, large, and do not jitter.
- Say explicitly whether screen-lock behavior was tested on a real device or only reasoned about.

## P5: Back handling, persistence, and polish

**Goal:** the app survives real use. Persistence and back handling are required. Polish items are cut first if short on time.

Do (required):
- `PlayersStore` backed by `shared_preferences`, same API as before. Player names load on launch.
- `PopScope` with confirm dialogs on Reveal and Timer, per `PRD.md` FR6 and `DESIGN_STYLE.md` section 8.
- Leaving the timer through confirm clears `GameSession` and returns to Players with names kept. A new round can be dealt with a different setup.
- A failed names save sets a state flag and shows a non-blocking `SnackBar` through `BlocListener`.

Do (polish, cut first):
- Pressed-button translate animation, status and navigation bar colors, Arabic semantic labels on all icon buttons, empty states.

Acceptance:
- Kill and relaunch shows the previously entered names. Role assignments are never persisted (show how you verified).
- Back during Reveal or Timer always shows the confirm dialog and never silently loses the round.
- A second full round works end to end after returning to Players.
- Cubits still contain no plugin imports; persistence stays behind `PlayersStore`.

## P6: Review and hand-off

**Goal:** confirm the whole app against the PRD and make it easy to continue.

Do:
- Run this demo script and report each step as passed or failed: add 7 players; enable godfather, detective, doctor, and jester with 2 mafia; confirm validation passes; deal; run the full reveal loop; open the host sheet by long press and check it shows 1 godfather, 1 mafia, 1 detective, 1 doctor, 1 jester, and 2 citizens; start a 1-minute timer, pause, resume, let it finish; leave through the confirm dialog; confirm names are kept; deal a second round with a different setup.
- Check each of `PRD.md` FR1 to FR6 and mark it passed or failed with a reason.
- Check every screen that has an animation: at most one Lottie, bounded size, static under reduced motion, no crash when a file is missing or its path is wrong, and the handoff and reveal animations identical for every role.
- Confirm the launcher icon on a device and that no removed platform folder reappeared.
- Go through the `DESIGN_STYLE.md` section 13 checklist and mark each item.
- Update `AGENTS.md` with final versions, commands, and any decisions made along the way.
- List known issues and everything you assumed but never tested.
- List what would need to change to add role abilities or resolve the `TODO: confirm` teams.

Acceptance:
- The demo script passes, or each failure is listed with a reason.
- `flutter analyze`, `flutter test`, and `dart format .` pass.
