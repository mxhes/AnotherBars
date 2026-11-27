# AnotherBars development

Status: Plan 1 (core, bar list, padding math, spike) done and checked in the
client; Plan 3 (button skin, pet badge, Look / Text settings, Settings
window) built, waiting for its client check. The design and its
reasons are in `docs/superpowers/specs/2026-11-26-anotherbars-design.md`.

## Setup

- Repo: https://github.com/mxhes/AnotherBars (`main`, changes through pull
  requests).
- Client: WoW Forever, `C:\Program Files (x86)\World of Warcraft\_forever_\`.
  For testing in game, link the addon folder into `Interface\AddOns`:
  `New-Item -ItemType Junction -Path "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\AnotherBars" -Target "D:\GitRepos\AnotherBars\AnotherBars"`.
- `Libs/` is fetched by the packager (`.pkgmeta` externals). For a local copy
  with Edit Mode, copy the `Libs` folder from the zip of the CI
  `package-dry-run` artifact (Actions > CI > Run workflow) into
  `AnotherBars/Libs/` (git-ignored). Or copy
  https://github.com/p3lim-wow/LibEditMode (tag 19, `embed.xml` at its root)
  into `AnotherBars/Libs/LibEditMode/`, plus LibStub and CallbackHandler-1.0
  from their own releases. Never from another addon's copy (it may be
  modified).
- Tools: Lua 5.4 (local), luacheck, gh.

**Spike check (Plan 1).** Run once by the player, in PowerShell; nothing here
is done by the build.

1. Close the game. Link the addon:
   `New-Item -ItemType Junction -Path "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\AnotherBars" -Target "D:\GitRepos\AnotherBars\AnotherBars"`.
2. Libraries: download the latest `AnotherBars-dry-run` artifact (Actions >
   CI, a `workflow_dispatch` run) and copy the `AnotherBars\Libs` folder from
   its zip to `D:\GitRepos\AnotherBars\AnotherBars\Libs\`.
3. Start the game, enable AnotherBars, log in. Check the library first (first
   line of the spike checks in `docs/CHECKLIST.md`), then
   `/console taintLog 1` and `/reload` once so logging starts clean.
4. Run the "Plan 1 spike" checks in `docs/CHECKLIST.md`. The taint log is
   `C:\Program Files (x86)\World of Warcraft\_forever_\Logs\taint.log`
   (written on logout / `/reload`): search it for `AnotherBars`.
5. Write the results under "Results" in `docs/CHECKLIST.md`.
6. `/console taintLog 0` when done.

## Code layout

| Folder / file | What it holds |
| --- | --- |
| `AnotherBars.toc` | load order |
| `embeds.xml` | LibStub, CallbackHandler, LibEditMode |
| `Core/Util.lua`, `Core/Locale.lua`, `Locales/deDE.lua` | helpers, texts (from AnotherHUD) |
| `Core/Theme.lua`, `Media/Skins/` | colors, fonts, sizes, skins (from AnotherHUD, unit frame parts left out) |
| `Core/DB.lua` | saved state: profiles, totem bar positions per Edit Mode layout |
| `Core/Modules.lua`, `Core/Options.lua` | module registry (kinds `bar` / `misc`, optional `system`), settings |
| `Core/Combat.lua` | `Combat.after(key, fn)`: queues work until combat ends |
| `Core/Bars.lua` | the ten Blizzard bars: frame, button prefix, count, Edit Mode system key |
| `Core/Grid.lua` | pure padding math: Blizzard's rows / columns from button offsets, new offsets for our padding, the padding-0 step, divider pairs |
| `Core/Layout.lua` | client glue: hook after Blizzard lays out a bar, move its buttons to our padding by changing only the offset on Blizzard's own anchor (main bar: each button's container), out of combat |
| `EditMode/Panel.lua` | pure: a module's `settings` -> LibEditMode setting rows (from AnotherHUD) |
| `EditMode/System.lua` | adds each bar module's settings to Blizzard's own bar panel (`AddSystemSettings`) |
| `Core/Reactive.lua` | the reactive spell list per class and the glow rule (usable and not on cooldown) |
| `Core/Art.lua` | pure: Blizzard's bar art per bar (dot paths and pools) that Hide Blizzard art hides |
| `Core/Look.lua` | pure look rules: skin of the profile, edge lines, shading, icon tints, text sizes |
| `Skin/Blizzard.lua` | every Blizzard button region and hook name, in one place (missing names do nothing) |
| `Skin/Draw.lua` | drawing helpers for our own frames: tinted tiles, line rects, gradient strips |
| `Skin/Button.lua` | the approved button look on a Blizzard button (our back / front / text frames, states from hooks) |
| `Skin/Glow.lua` | the gold pulse proc glow |
| `Skin/Procs.lua` | which buttons glow: the client's proc events matched to each button's spell (or macro spell) |
| `Skin/Art.lua` | hides / shows the listed art by alpha 0, keeping each region's own alpha in our table |
| `Skin/BarFrame.lua` | padding 0: one skin panel of ours around the bar and 1 px dividers between the icons |
| `Skin/Autocast.lua`, `Media/Shapes/Disc.tga` | the pet autocast badge (disc stack as AnotherHUD's ring) |
| `Bars/Common.lua` | one module per bar: Look / Text settings, create skins its buttons; `Common.layout` runs art, padding and bar frame |
| `Bars/ActionBar.lua`, `Bars/Stance.lua`, `Bars/Pet.lua` | the ten bar modules (Pet adds the autocast badge) |
| `UI/Settings.lua` | the Settings window: Blizzard's Settings panel, skin and bars on / off |
| `Core/Core.lua` | start-up and the `/abars` slash command |
| `Boot.lua` | starts the addon on `ADDON_LOADED` |

## The button skin

Each skinned button gets our frames, parented to the button (state in
the weak table of `Skin/Button.lua`, never on the button):

| Frame | Level | Holds |
| --- | --- | --- |
| back | button - 1 | the panel fill; Classic: the round tooltip edge (backdrop) |
| Blizzard's cooldown | button + 1 | moved inside the edge, our swipe alpha and gold countdown font |
| front | button + 2 | edge lines, shading, active edge and glow, hover / pressed / empty overlays |
| text | button + 3 | Blizzard's hotkey, count and macro name, re-parented (off = alpha 0) |
| glow | button + 4 | the proc glow |

Blizzard's normal, highlight, pushed, checked, flash, border and spell-alert
textures go to alpha 0. Hooks (`Skin/Blizzard.lua`):
`ActionButton_UpdateRangeIndicator`, the button's `Update` / `UpdateUsable` /
`SetChecked` / `SetButtonState`, `OnEnter` / `OnLeave` / `OnMouseDown` /
`OnMouseUp` (HookScript), the spell alert (`ActionButtonSpellAlertManager` or
the older overlay glow globals), and the pet bar's update with
`GetPetActionInfo`. Hook bodies only show, hide and tint our regions and the
icon. The active edge follows `GetChecked`, re-read after `SetChecked`,
`PostClick`, `Update`, a key release and `ACTIONBAR_UPDATE_STATE`: the game
clears the flag after a cast without calling `SetChecked` (seen in the client
with Whirlwind, Execute, Cleave and Bloodrage).

**Proc glow.** On Forever the game never signals a proc (no alert, no proc
event; Plan 3 results in `docs/CHECKLIST.md`). `Skin/Procs.lua` lights a
button when its spell, or the spell its macro casts, has the name of one of
the player's reactive spells (`Core/Reactive.lua`), `IsUsableAction` says
usable, and `C_Spell.GetSpellCooldown(id).isActive` is not true (no math on
cooldown numbers; an unknown cooldown counts as off, and `isOnGCD` true
means only the global cooldown, which does not hide the glow). It re-checks on
usable, cooldown, slot, page, bonus bar, target, target health and stance
events. The game's proc events (`SPELL_ACTIVATION_OVERLAY_GLOW_SHOW` /
`_HIDE`, `IsSpellOverlayed` at login) and the alert hooks stay as a second
source: a button glows when either says so.

**Adding a reactive spell:** one line `{ id = <spell id>, name = "<name>" }`
under the class token in `Reactive.SPELLS` (`Core/Reactive.lua`); a new
class is a new key. Any rank's id works, since buttons match by name. The
tests never name the shipped list, so no test changes; a test checks every
entry is valid (`tests/test_reactive.lua`). Add a CHECKLIST line for the
client check.

**Padding and art (Plan 4).** `Common.layout(id)` runs per bar on create,
on a setting change, after Blizzard's `UpdateGridLayout`, when a button is
shown, on `PLAYER_ENTERING_WORLD` / `EDIT_MODE_LAYOUTS_UPDATED` (the main
bar's buttons only sit right once the Edit Mode layout is in) and on a skin
change (the edge width sets the padding-0 step). It queues, in this order:

1. `Skin/Art.lua`: Hide Blizzard art (the main bar's dividers are made on
   each layout, so they are hidden again each time).
2. `Layout.repack(id, Grid.spacing(padding, edge))` with Own padding on,
   else `Layout.reset(id)` (every moved button back on Blizzard's anchor).
   At padding 0 the spacing is `1 - 2 * edge`: the buttons overlap and
   their icons sit 1 px apart. Only shown buttons are packed (past "# of
   Icons" Blizzard leaves hidden ones on stale anchors); an empty slot that
   shows while a spell is dragged repacks the bar. `reset` restores only
   buttons still on our anchor.
3. `Skin/BarFrame.lua` at own padding 0: our panel, anchored to the
   outermost buttons of the repack, with `Grid.dividers` lines. The buttons
   get `opts.framed`: no fill or edge of their own, hover as a 1 px gold
   inner edge, and the glow placed around the icon (`Glow.place`).

**Adding an art region:** one dot path under the bar's id in
`Art.REGIONS` (`Core/Art.lua`), or a pool key in `Art.POOLS`. Names the
client doesn't have are skipped; add a CHECKLIST line for the client check.

**Secret values.** Every range, usable, mana, checked or autocast value from
the client goes through `Util.plain(v)` (nil for a secret) before a branch;
on nil the hook changes nothing, so Blizzard's own tint stays.

**Relayout.** A skin change (Settings window) calls `Button.relayoutAll` and
`Autocast.relayoutAll` out of combat; a bar setting re-skins that bar's
buttons (`Button.skin` again only relayouts).
