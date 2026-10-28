# Architecture v0.1

Goal: the simplest structure that keeps logic testable and lets roles/teams be edited in one place. No over-engineering: this is a ~5-screen offline app.

## 1. Stack
- Flutter (Android first), Dart null-safe.
- State: `flutter_bloc` using **Cubit** only (no Bloc events).
- DI: `get_it`.
- Equality: `equatable`.
- Persistence: `shared_preferences` (player names only).
- Wake lock: `wakelock_plus`.
- Vibration and finish sound: built-in `HapticFeedback` and `SystemSound` (no extra packages).
- Navigation: plain `Navigator` with `MaterialPageRoute`. No router package.
- Tests: `flutter_test`, `bloc_test`.
- Adding any other dependency requires explicit approval.

**Presentation pattern decision:** plain Cubit with immutable states. No `bloc_presentation` package, because there are no one-shot side effects that cannot be expressed as state: validation is derived state (disabled button plus reason text), and navigation is triggered from the widget after a successful action. If a real one-shot event appears later, add the package then.

## 2. Structure
```
lib/
  main.dart
  app.dart                      # MaterialApp, RTL, dark theme
  core/
    di.dart                     # getIt registrations
    constants.dart              # GameLimits
    strings_ar.dart             # all user-facing text
    theme.dart
  features/
    roles/
      domain/
        team.dart               # enum Team { mafia, civilian, neutral }
        role.dart               # Role model (const instances)
        role_catalog.dart       # the single place roles/teams/descriptions are edited
    game/
      domain/
        player.dart
        assignment.dart         # Player + Role
        setup_config.dart       # mafiaCount, enabledRoleIds
        setup_validator.dart    # pure
        role_distributor.dart   # pure, injectable Random
        game_session.dart       # in-memory holder of current assignments
      data/
        players_store.dart      # shared_preferences wrapper
    setup/                      # screens + cubit: players and game setup
    reveal/                     # handoff + reveal screens + cubit
    timer/                      # timer screen + cubit + host sheet
test/
  domain/                       # validator and distributor tests
  cubits/
```
Rule: `domain/` is pure Dart. No Flutter imports, no `BuildContext`.

## 3. Domain
```dart
enum Team { mafia, civilian, neutral }

class Role extends Equatable {
  final String id;
  final String nameAr;
  final String descriptionAr;
  final Team team;
  final bool isSpecial;   // false for plain mafia and citizen
}
```
`RoleCatalog` exposes `const` role instances and `List<Role> specials`. Changing a name, description, or team is a one-line edit here and touches nothing else. **No code may branch on a role id for game behavior.** Logic reads `team` only.

`SetupValidator.validate(playerNames, config)` returns a sealed result: `Valid` or `Invalid(reason)`, where `reason` is an enum mapped to Arabic text in the UI. Rules are in PRD section 5.

`RoleDistributor.deal(players, config, Random)`:
1. Build the role list: `mafiaCount` mafia slots; if godfather is enabled, replace one mafia slot with godfather; add one of each other enabled special role; fill the rest with citizen.
2. Shuffle with the injected `Random`.
3. Zip with players in order and return `List<Assignment>`.
The list length must equal the player count; the distributor throws `StateError` if config was not validated.

`GameSession` (lazy singleton): holds `List<Assignment>` for the current round. `start(assignments)` and `clear()`. In-memory only.

## 4. State management
| Cubit | State | Responsibility |
|---|---|---|
| `SetupCubit` | players, mafiaCount, enabledRoleIds, `ValidationResult` | edit names, stepper, toggles; recompute validation on every change; persist names; `deal()` calls the distributor and fills `GameSession` |
| `RevealCubit` | `currentIndex`, `isRevealed`, `isFinished` | `reveal()`, `hideAndNext()`; reads assignments from `GameSession` |
| `TimerCubit` | `idle`, `running(endAt)`, `paused(remaining)`, `finished`, plus `duration` | start, pause, reset, set duration |

Cubits are registered as factories in getIt (fresh per screen). `GameSession` and `PlayersStore` are lazy singletons. Randomness (`Random`) is registered so tests can override it.

## 5. Timer correctness
- Store `endAt = now + remaining` on start. Never accumulate ticks.
- A `Stream.periodic` of about 250 ms recomputes `remaining = endAt - now` for display only.
- Pause stores `remaining`; resume sets a new `endAt`.
- When `remaining <= 0`: emit `finished`, call `HapticFeedback.vibrate()` and `SystemSound.play(SystemSoundType.alert)`.
- `wakelock_plus` enabled on entering the timer screen, disabled on leaving.
- Cancel the stream subscription in `close()`.

## 6. Host roles sheet
Button uses `onLongPress` only. Sheet reads `GameSession`. Auto-close after 10 s via a timer owned by the sheet widget. Close on `AppLifecycleState.paused`. The timer cubit is not touched.

## 7. Back handling
`PopScope` on reveal and timer screens shows a confirmation dialog. Confirm on timer: `GameSession.clear()` then pop to the Players screen (names remain in `SetupCubit` and `PlayersStore`).

## 8. Testing (minimum)
- `SetupValidator`: every rule in PRD section 5, with boundary cases (min players, mafia exactly half, specials equal to players).
- `RoleDistributor`: fixed-seed determinism; role counts match config; godfather counted inside mafia count.
- `TimerCubit`: pause/resume math using an injectable clock.
- No widget tests required for MVP.

## 9. Build order
1. Domain (roles, validator, distributor) with tests.
2. Setup screens and `SetupCubit`.
3. Handoff and reveal flow.
4. Timer plus host sheet.
5. Back handling, persistence, polish.
Finish and verify each step before starting the next.
