---
name: flutter-cubit
description: Scaffold a Cubit and its state file for the Mafia host-helper app using Dart 3+ native features (no Freezed, no build_runner). ALWAYS use this skill before writing any Cubit or state file, including when building a full feature or screen. Triggers on "create cubit", "add cubit", "new cubit", or any task that will produce a *_cubit.dart or *_state.dart file.
allowed-tools: Read Write Edit Glob Grep
---

# Scaffold a Cubit + State (Dart 3+)

Generate a Cubit and its state file for the given feature. **No Freezed. No build_runner.** Read `ARCHITECTURE.md` section 4 first; it is the source of truth for which Cubits exist and what they own.

This skill covers file scaffolding only. The build order and the plan-then-approve workflow in `AGENTS.md` still apply.

## Project differences from a typical Clean Architecture setup

- There are **no use cases, no repositories, and no `Either`/`Failure` types** in this app. Do not create them.
- A Cubit depends only on the objects listed for it in `ARCHITECTURE.md` section 4: pure domain classes (`SetupValidator`, `RoleDistributor`), `GameSession`, `PlayersStore`, and injected `Random` or clock. Never depend on `shared_preferences` or any plugin directly.
- Cubits hold **no user-facing text**. Emit enums or data; the UI maps them to Arabic through `strings_ar.dart`.

## Where files go

Flat per feature, matching `ARCHITECTURE.md` section 2:

```
lib/features/{feature}/{name}_cubit.dart
lib/features/{feature}/{name}_state.dart
test/cubits/{name}_cubit_test.dart
```

Do not create `presentation/cubit/` subfolders.

## Choosing the state shape

| Situation | Shape |
| --- | --- |
| Form-like data edited in place (many fields, any combination valid) | One `Equatable` class with `copyWith`. Example: `SetupState` |
| Mutually exclusive phases (impossible combinations must not compile) | `sealed class` base with `const` subclasses. Example: `TimerState` (idle, running, paused, finished) |

There is no generic `Initial/Loading/Loaded/Error` set. Local, synchronous or near-instant work does not need loading states. Add `Loading` only if a step truly awaits I/O the user can see.

## State file (`{name}_state.dart`)

Pure Dart. Imports `equatable` only. No Flutter imports. All state classes immutable with `const` constructors.

Form-like:

```dart
import 'package:equatable/equatable.dart';

class SetupState extends Equatable {
  final List<String> players;
  final int mafiaCount;
  final Set<String> enabledRoleIds;
  final SetupValidation validation; // enum or sealed result from the domain

  const SetupState({
    required this.players,
    required this.mafiaCount,
    required this.enabledRoleIds,
    required this.validation,
  });

  SetupState copyWith({
    List<String>? players,
    int? mafiaCount,
    Set<String>? enabledRoleIds,
    SetupValidation? validation,
  }) => SetupState(
        players: players ?? this.players,
        mafiaCount: mafiaCount ?? this.mafiaCount,
        enabledRoleIds: enabledRoleIds ?? this.enabledRoleIds,
        validation: validation ?? this.validation,
      );

  @override
  List<Object?> get props => [players, mafiaCount, enabledRoleIds, validation];
}
```

Sealed phases:

```dart
import 'package:equatable/equatable.dart';

sealed class TimerState extends Equatable {
  final Duration duration; // configured length
  const TimerState(this.duration);
}

class TimerIdle extends TimerState {
  const TimerIdle(super.duration);
  @override
  List<Object?> get props => [duration];
}

class TimerRunning extends TimerState {
  final DateTime endAt;
  final Duration remaining; // recomputed from endAt for display only
  const TimerRunning(super.duration, {required this.endAt, required this.remaining});
  @override
  List<Object?> get props => [duration, endAt, remaining];
}

class TimerPaused extends TimerState {
  final Duration remaining;
  const TimerPaused(super.duration, {required this.remaining});
  @override
  List<Object?> get props => [duration, remaining];
}

class TimerFinished extends TimerState {
  const TimerFinished(super.duration);
  @override
  List<Object?> get props => [duration];
}
```

## Cubit file (`{name}_cubit.dart`)

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

class SetupCubit extends Cubit<SetupState> {
  final PlayersStore _store;
  final GameSession _session;
  final Random _random;

  SetupCubit(this._store, this._session, this._random)
      : super(SetupState.initial()); // or load persisted names in an init method

  void addPlayer(String name) { /* update state, recompute validation */ }

  /// Returns true when roles were dealt. The widget navigates on true.
  bool deal() {
    if (state.validation != SetupValidation.valid) return false;
    _session.start(RoleDistributor.deal(/* players, config, _random */));
    return true;
  }
}
```

### Cubit rules

- Name methods by user intent (`addPlayer`, `reveal`, `start`, `pause`), not by events.
- Recompute derived state (validation) on every change, inside the Cubit, by calling the pure domain classes. Never recompute in widgets.
- No `BuildContext`, no navigation, no `SnackBar` inside a Cubit. A method that leads to navigation returns a `bool` or a small result, and the widget navigates.
- No `Either`, no `Failure` mapping. Expected problems are modeled as state (for example a validation enum). Persistence failures are non-critical: catch them and set a state flag such as `namesSaveFailed`; the widget shows the `SnackBar` with `BlocListener` and `listenWhen` on the false-to-true transition.
- Inject anything non-deterministic: `Random`, and for the timer a clock (`DateTime Function() now`). Never call `DateTime.now()` or create `Random()` inside a Cubit body.
- Anything with a stream or timer must be cancelled in `close()`, and async callbacks must check `isClosed` before calling `emit`.
- Keep Cubits small. If a Cubit needs more than about three dependencies, stop and ask: the design probably needs a domain class.

## Using the Cubit in widgets

- Provide with `BlocProvider(create: (_) => getIt<{Name}Cubit>())`.
- Use `BlocBuilder` with `buildWhen` when only part of the state matters.
- For sealed states, render with a `switch` expression so the compiler enforces every case.

```dart
BlocBuilder<TimerCubit, TimerState>(
  builder: (context, state) => switch (state) {
    TimerIdle()     => IdleView(state),
    TimerRunning()  => RunningView(state),
    TimerPaused()   => PausedView(state),
    TimerFinished() => FinishedView(state),
  },
);
```

## DI registration

All registration is in the single file `core/di.dart`:

```dart
getIt.registerFactory(() => SetupCubit(getIt(), getIt(), getIt()));
```

- Cubits are factories. `GameSession` and `PlayersStore` are lazy singletons. `Random` is registered so tests can override it.

## Tests

Add a `bloc_test` for every Cubit that contains logic, in the same step that creates it, not later:

- `SetupCubit`: validation recomputed on each change; `deal()` returns false when invalid and does not touch `GameSession`.
- `TimerCubit`: start, pause, resume, reset, and finish using the injected clock; subscription cancelled on `close()`.
- `RevealCubit`: index advances, finishes after the last player, reads from `GameSession`.

## After scaffolding, verify

- The state file imports only `equatable` and domain types, no Flutter.
- The Cubit does not import a plugin, `shared_preferences`, `BuildContext`, or any widget.
- All state classes are immutable with `const` constructors and implement `props`.
- No user-facing strings, no use cases, no `Either`/`Failure` were introduced.
- Sealed states are consumed with exhaustive `switch` in the widget.
- The Cubit is registered in `core/di.dart` as a factory.
- `flutter analyze` and `flutter test` are clean, and the report says exactly what was run and what was not.