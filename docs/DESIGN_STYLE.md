# Mafia Host Helper: Design Style & UI Specification

Version: 1.0 · Platform: Android / Flutter · UI language: Arabic · Direction: RTL · Theme: dark only

## 1. Purpose and authority

This document defines the visual system and interaction design for the Mafia host-helper app. Read it alongside `PRD.md`, `ARCHITECTURE.md`, and `AGENTS.md` before implementing screens.

The PRD owns product scope and rules. This document owns presentation only. Do not add features because they look good in a design. Do not copy artwork, icons, or wording from other Mafia apps.

Values marked **(recommended)** are design defaults chosen without a product decision. Isolate them in the theme so they can change without touching screens.

## 2. Design direction

**Dark neo-brutalism: near-black surfaces, one hard red, thick off-white outlines, hard offset shadows.**

The feeling is tense, blunt, and playful, like a table of friends accusing each other. The look is raw, but the interface is still readable in a dim room, in one glance, with one hand.

### Visual emphasis hierarchy

1. The action needed now: pass the phone, reveal the role, start the timer.
2. The information that matters: the player's name, the role name, the remaining time.
3. Supporting text and navigation.
4. Brand decoration.

Use the strongest brutalist treatment (thick outline plus hard shadow) on exactly one element per screen: the primary action, or on the reveal screen the role card. Everything else stays flat with thin outlines. Do not make every surface shout.

## 3. Secrecy rules that affect design (hard requirements)

The phone is passed around a table and glanced at by neighbors. The design must not leak roles.

- The **handoff** and **reveal** screens use identical colors, layout, and typography for every role. Never tint the screen, card, border, or icon by team. A red flash for mafia would be visible across the table.
- The reveal card is the only place a role name appears during the loop. The hide button returns to a neutral state immediately.
- No role names, counts, or team hints on the Players, Setup, or Timer screens. The Setup screen lists which **optional roles are enabled**, which is public knowledge in the room by design.
- Team color appears only inside the host roles sheet (section 8, S6), shown with a text label as well.
- No screenshots restriction is required by the PRD. Do not add `FLAG_SECURE` unless asked.

## 4. Color tokens

Use semantic theme tokens. No raw hex values inside feature widgets.

| Token | Value | Use |
| --- | --- | --- |
| `brandPrimary` | `#D62828` | Primary actions, selected controls, key accents |
| `onBrandPrimary` | `#FFFFFF` | Text and icons on red |
| `canvas` | `#0B0B0B` | Main screen background |
| `surface` | `#161616` | Cards, inputs, sheets |
| `surfaceRaised` | `#202020` | Pressed or selected rows, quiet emphasis |
| `ink` | `#F5F1E8` | Main text and all strong outlines (a warm off-white) |
| `textSecondary` | `#A8A29A` | Supporting copy |
| `divider` | `#2E2E2E` | List separators and quiet boundaries |
| `danger` | `#FF5A52` | Validation errors, destructive confirmation text |
| `dangerSurface` | `#2A1010` | Error message backgrounds |
| `teamMafia` | `#D62828` | Host sheet only |
| `teamCivilian` | `#F5F1E8` | Host sheet only |
| `teamNeutral` | `#E3B23C` | Host sheet only |

Red is an action and emphasis color. Do not use red for ordinary text or for every border. Pair every team color with a visible Arabic label. White text on `brandPrimary` is roughly 5:1 by calculation; verify real contrast in rendered components, including disabled controls. Never put dark text on `brandPrimary`.

Dark mode only. Set the system status and navigation bars to match `canvas` with light icons. Do not ship a light palette.

## 5. Typography

Use **Cairo (recommended)**, bundled locally so first rendering never depends on a download. Include only weights 400, 700, and 900. Keep Arabic text upright, not italic.

| Role | Size / line height | Weight |
| --- | --- | --- |
| Timer digits | 80 / 88 | 900 |
| Role name on reveal card | 44 / 56 | 900 |
| Player name on handoff | 36 / 48 | 900 |
| Screen title | 24 / 34 | 900 |
| Section heading | 18 / 28 | 700 |
| Primary row text and body | 16 / 26 | 700 / 400 |
| Button label | 18 / 26 | 900 |
| Supporting label | 14 / 22 | 400 |
| Small metadata | 12 / 20 | 400 |

Sizes are logical pixels at default scale. Express line height as the appropriate Flutter multiplier. Support system text scaling; do not disable it. Avoid fixed heights that clip long names or Arabic ascenders and dots. Prefer wrapping over shrinking, except the timer digits, which scale down to fit width.

Timer digits are always shown `mm:ss`, isolated in LTR direction, using Western digits. Use tabular figures if the bundled font supports them, so the digits do not jitter. Accept both Arabic-Indic and Western digits as input.

## 6. Spacing, geometry, borders, and shadows

| Token group | Values |
| --- | --- |
| Spacing scale | 4, 8, 12, 16, 24, 32 |
| Screen horizontal inset | 16; 24 where width comfortably permits |
| Main control height | Minimum 56 |
| Touch target | Minimum 48 × 48 |
| Radius | 4 for controls and cards; 0 for the timer panel; sheets 4 at top |
| Strong outline | 3, `ink` |
| Quiet outline | 1.5, `divider` or `textSecondary` |
| Hard shadow | Offset (4, 4), blur 0, spread 0 |

Hard shadow colors: **primary button** uses `ink`; **reveal role card** uses `brandPrimary`. Shadows are painted in the same space as layout; leave room so they are not clipped. Shadow direction does not mirror in RTL.

Do not use blurred elevations, glassmorphism, gradients, textures, noise, tilted cards, stickers, or scattered decoration. Brutalism here means thick lines, hard offsets, and blunt type, not clutter.

## 7. Component system

### Buttons
- Primary: `brandPrimary` fill, `onBrandPrimary` text, 3px `ink` outline, 4px radius, hard shadow `ink` (4,4).
- Secondary: `surface` fill, `ink` text, 3px `ink` outline, no shadow.
- Destructive: `danger` text and outline; confirmation dialog uses a `danger`-outlined button.
- Pressed: translate the button by (4,4) toward its shadow and remove the shadow, so it looks pressed flat. 120ms, no bounce.
- Disabled: `surface` fill, `textSecondary` text, quiet outline, no shadow, still readable.
- One dominant primary action per screen. Prevent double taps immediately.

### Inputs
- Filled `surface`, 3px `ink` outline when focused, 1.5px quiet outline otherwise, 56 height minimum.
- Visible label and visible error text under the field. Do not rely on color alone.
- Duplicate and empty-name errors appear inline under the field.

### Player rows (Players screen)
- Flat rows with a divider, name at start, delete icon button at end (48×48 target, Arabic semantic label).
- No shadows on rows. Add-player input is pinned near the top so it stays reachable with the keyboard open.

### Role toggle cards (Setup screen)
- Flat card: role name, short description, switch.
- Enabled: 3px `ink` outline and `surfaceRaised` fill. Disabled: quiet outline and `surface` fill. No hard shadows on these cards.
- Different treatment for enabled must also be readable without color, via outline weight and the switch position.

### Steppers
- Mafia count stepper: `−` and `+` buttons (48×48) around a large number. Disable at limits and show the validation reason.

### Validation message
- A `dangerSurface` strip with a `danger` leading icon and plain Arabic text stating the exact fix. Sits directly above the Next button. When setup is valid, the strip disappears entirely.

### Dialogs and sheets
- Dialog: `surface`, 3px `ink` outline, 4px radius. Two actions, safe action first. Plain wording about the consequence.
- Bottom sheet: `surface`, 3px `ink` top outline, no blur scrim; use a flat 80% black scrim.

## 8. Screen specifications

### S1 Players
Compact header, add-player field plus a small add button, list of players, a player count label, and a primary `التالي` button. Empty state: `ضيف أسماء اللاعبين عشان تبدأ`.

### S2 Game Setup
Title, mafia count stepper, section heading for optional roles, role toggle cards, validation strip, primary button `وزّع الأدوار`. Keep the primary button visible without covering the last card.

### S3 Handoff
Dark, almost empty screen. A small label, then the player's name very large, then the instruction. Primary button `أنا <name>، اكشف دوري` is not needed; use a single full-width primary button `اكشف الدور`. No role data anywhere. Text example: `سلّم الموبايل لـ`.

### S4 Reveal
One large card centered: 3px `ink` outline, `surface` fill, hard shadow `brandPrimary`. Role name at 44/56 weight 900, below it the role description at 16/26. The card is identical in color for every role (section 3). One primary button below: `إخفاء والتالي`. A single placeholder icon per role is allowed above the name, drawn from a neutral icon set in `ink` color only. It must be a simple glyph, not a team-colored illustration.

### S5 Timer
A panel with 3px `ink` outline, 0 radius, containing the digits at 80/88 weight 900 and the duration controls. Controls: minutes and seconds steppers when idle; a primary start/pause button; a secondary reset button. When time is up, the panel outline turns `brandPrimary`, the digits turn `brandPrimary`, and the label `انتهى الوقت` appears. No flashing animation.

Below: the button `عرض الأدوار`, styled secondary with a small lock icon. It is operated by long press only and shows the helper text `اضغط مطولًا` under it so the host knows how to open it. A normal tap shows a short `SnackBar` hint with the same text and does nothing else.

### S6 Host roles sheet
Bottom sheet. Rows: player name at start, role name, a small team chip at end containing the team label in Arabic and the team color as a left border. A thin countdown bar at the top shows the 10-second auto-close. Chips for `neutral` use `teamNeutral`. Nothing else in the sheet.

### Confirm-exit dialogs
Used on reveal and timer when system back is pressed. Title states what will be lost, for example `الخروج هيمسح توزيع الأدوار`. Actions `رجوع` and `خروج`.

## 9. Feedback, loading, and empty states

| Condition | Presentation |
| --- | --- |
| No players yet | `ضيف أسماء اللاعبين عشان تبدأ` |
| Invalid setup | Validation strip with the specific fix |
| Duplicate or empty name | Inline field error |
| Timer finished | Panel turns red, `انتهى الوقت`, vibration and system sound |
| Host sheet auto-closed | No message; sheet simply closes |
| Failed local save of names | Short non-blocking `SnackBar` and retry on next change |

No spinners are needed. Startup restores names from local storage; show the Players screen with empty list briefly rather than a blocking loader.

## 10. Arabic copy and RTL behavior

- Use short, direct Arabic. Prefer `اكشف الدور`، `إخفاء والتالي`، `وزّع الأدوار`، `رجوع`.
- No jokes or slang in validation and exit-confirmation text.
- Use `EdgeInsetsDirectional`, `AlignmentDirectional`, and logical start/end alignment.
- Mirror directional icons (back and forward). Do not mirror the timer digits or non-directional icons.
- Isolate numbers and `mm:ss` strings with LTR direction so bidi reordering never flips them.
- All strings are in `strings_ar.dart`. Use `intl` for number formatting.

## 11. Accessibility and responsive behavior

- Design for about 360 logical pixels width. Check 320, 390, and 430, large system text, and keyboard-open states.
- Portrait only. Cap content width on tablets instead of scaling everything.
- Icon-only buttons carry Arabic semantic labels. Team labels and enabled states never rely on color alone.
- Keep content above system navigation and account for edge-to-edge insets.
- Motion is limited to the pressed-button translate and sheet transitions, 120–200ms. Respect reduced-motion preferences.
- The handoff and reveal screens are tuned for a dim room: large text, high contrast, no fine detail.

## 12. Flutter implementation expectations

- Define `ThemeData`, color tokens, spacing, radii, border widths, and the hard-shadow decoration centrally in `core/theme.dart`.
- Shared primitives: primary button (with press translate), secondary button, labeled input, role toggle card, validation strip, confirm dialog, sheet shell. Extract a component only when it is reused or has meaningful behavior.
- Do not scale dimensions globally by screen width. Use logical sizes and constraints.
- No business logic in widgets. Follow the structure in `ARCHITECTURE.md`.
- Bundle the font locally. Normal rendering must make no network requests.
- All role names, descriptions, and teams come from `role_catalog.dart`. Widgets never hardcode role content.

## 13. Agent acceptance checklist

- [ ] The look is clearly dark brutalism: thick off-white outlines, one red, hard offset shadows used sparingly.
- [ ] Only one strongly styled element per screen (primary button, or the role card on reveal).
- [ ] Handoff and reveal screens are identical in color and layout for every role; no team tint anywhere outside the host sheet.
- [ ] Team colors appear only in the host sheet and always with a text label.
- [ ] Host sheet opens only by long press; tap shows only the hint.
- [ ] Timer digits are LTR `mm:ss`, large, readable, and do not jitter; finish state is clear without flashing.
- [ ] RTL, large text, keyboard-open states, and long names work at 320 and 360 widths.
- [ ] Contrast of white on red, disabled controls, and secondary text is verified in the rendered app.
- [ ] No gradients, blurred shadows, tilted elements, or copied artwork.
- [ ] No features, screens, or settings invented beyond the PRD.

## 14. Open decisions (non-blocking)
Exact red value; Cairo as the final font; the glyph set for role icons; whether the host sheet should show team chips at all.
