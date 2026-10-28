# Mafia Host Helper: PRD v0.1

## 1. Purpose
A single-phone helper for the physical party game "Mafia". Friends sit together, one human **host** narrates the night phase. The app does only three things:
1. Collect player names and game setup.
2. Randomly assign roles and let each player privately see their own role by passing the phone around.
3. Provide a timer for the discussion phase, plus a protected view that lets the host see all roles.

The app does **not** run the game. Night phase, voting, eliminations, win detection, and role abilities all happen outside the app (voting is by raising a finger).

## 2. Platform and language
- Flutter, Android first. Portrait only. Offline only. No accounts, no backend, no analytics.
- UI language: Arabic, RTL. All user-facing strings live in one file so adding languages later is cheap.
- Visual style: dark theme, deep red accent, card-style role presentation. Original icons or illustrations only (no assets copied from other apps). All roles are free: no premium or locked roles.

## 3. Roles
Role = data only (`id`, `nameAr`, `descriptionAr`, `team`, `isSpecial`). Role abilities are NOT implemented in code. Descriptions are shown to the player on reveal and edited later in one place.

| id | Arabic name | Description (editable) | team | Default enabled |
|---|---|---|---|---|
| mafia | مافيا | عضو في المافيا | mafia | always (count set manually) |
| citizen | مواطن | مواطن عادي | civilian | always (fills remaining slots) |
| godfather | العراب | قائد المافيا، يخدع المحقق | mafia | off |
| detective | المحقق | يكشف هوية لاعب كل ليلة | civilian | on |
| doctor | الدكتور | يحمي لاعب من القتل كل ليلة | civilian | on |
| guard | الحارس | يحمي لاعب ويموت بدلًا عنه | civilian | off |
| spy | الجاسوس | يقتل أو يتجسس كل ليلة | civilian (TODO: confirm) | off |
| hunter | الصياد | ينتقم عند إقصائه بالتصويت | civilian (TODO: confirm) | off |
| gambler | المراهن | يراهن على إقصاء لاعب بالتصويت | civilian (TODO: confirm) | off |
| jester | المهرج | يفوز إذا تم إقصاؤه بالتصويت | neutral | off |

Each enabled special role is dealt **exactly once**. Team values marked TODO are placeholders; changing one is a one-line edit and must not touch any logic.

## 4. Screens and flow
`Players` -> `Game Setup` -> `Handoff/Reveal loop` -> `Timer` -> back to `Players` (names kept) -> new round.

**S1 Players.** Add, remove, and edit player names. Names persist between rounds and app restarts. Next button enabled only when the player count is valid.

**S2 Game Setup.** Mafia count stepper. Toggle list of special roles (card per role, with a short description). Live validation message explaining why Next is disabled. Next deals the roles.

**S3 Handoff.** Full screen: "سلّم الموبايل لـ <name>". Tap to continue. Shows no role information.

**S4 Reveal.** Shows that player's role card (name, description). One button: "إخفاء والتالي". Role is never visible on S3. After the last player, go to S5. System back is blocked here (confirm-exit dialog only).

**S5 Timer.** Set duration (minutes and seconds), start, pause, reset. Shows remaining time large. On finish: vibration plus system sound. Screen stays awake while the timer screen is open. Contains:
- "عرض الأدوار" button (host view, see S6).
- Back button: confirmation dialog, then returns to S1 with names preserved and assignments discarded.

**S6 Host roles view.** Bottom sheet listing every player and their role. Opens only on **long press (about 1s)** of the button, never on a single tap. Auto-closes after 10 seconds or when the app goes to background. The timer keeps running underneath.

## 5. Validation rules
Constants live in one place (`GameLimits`). Values below are assumptions; confirm or change.
- Players: min 4, max 25 (ASSUMPTION).
- Mafia count >= 1 and `2 * mafiaCount < playerCount` (mafia must start strictly fewer than everyone else).
- Godfather, if enabled, is **one of** the mafia count, not an extra.
- `mafiaCount + (enabled special roles whose team != mafia) <= playerCount`. Equality is allowed (zero plain citizens is fine).
- Duplicate or empty names are rejected.
- Any violation disables Next and shows the reason.

## 6. Functional requirements and acceptance
- FR1 Dealing is uniformly random and uses an injectable `Random` (so tests are deterministic). Acceptance: given a fixed seed, output is reproducible; counts of each role match the setup.
- FR2 Assignments live in memory for the round only. Acceptance: leaving the round discards them; roles are never written to disk.
- FR3 Timer is correct across screen lock and app backgrounding. Acceptance: remaining time derives from an end timestamp, not from counting ticks.
- FR4 Player names persist across restarts. Acceptance: kill and relaunch shows the previous names.
- FR5 Host view never opens by accident. Acceptance: single tap does nothing; long press opens; auto-closes.
- FR6 Android back during reveal or timer never silently loses the round. Acceptance: confirm dialog appears.

## 7. Out of scope (do not build)
Night phase automation, voting, eliminations, win detection, role abilities, accounts, online play, premium or ads, statistics, multiple devices, sound assets, localization beyond Arabic, role artwork from third parties.

## 8. Open items (non-blocking)
Teams of spy, hunter, gambler; exact role descriptions; player limits; timer finish sound beyond the system sound.
