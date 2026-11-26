# AnotherBars: Blizzard's action bars in the suite's look

Date: 2026-11-26. Status: approved by the player on 2026-11-26.

## Intent

The player runs their own UI suite on WoW Forever: **AnotherLedger**
(`D:\GitRepos\LootLedger`), **AnotherHUD** (`D:\GitRepos\AnotherHUD`: unit
frames, class resource bar, XP / Reputation; it does not touch action bars),
**AnotherBars** (this addon) and a minimap addon later. AnotherBars is the
action bar part. The goal of the first release: the player's old UI addon
can be switched off for bars, as it already can for unit frames.

AnotherBars takes Blizzard's own bars and goes beyond a re-skin: the suite's
look on every button, Blizzard's bar artwork hidden, and tighter spacing than
Blizzard allows (down to buttons touching). Blizzard keeps everything secure:
clicks, paging, cooldowns, procs, keybinds, drag and drop, and bar placement
in Edit Mode.

## Goals (first release)

Bars covered:

| Bar | Blizzard frame (UNVERIFIED names on Forever) | Edit Mode system |
| --- | --- | --- |
| Action Bar 1 | `MainMenuBar` (`ActionButton1-12`) | ActionBar, MainBar |
| Action Bar 2-8 | `MultiBarBottomLeft`, `MultiBarBottomRight`, `MultiBarRight`, `MultiBarLeft`, `MultiBar5-7` | ActionBar, Bar2-Bar8 |
| Stance Bar | `StanceBar` | ActionBar, StanceBar |
| Pet Bar | `PetActionBar` | ActionBar, PetActionBar |
| Totem bar | our own frame (Blizzard's `TotemFrame` hidden) | own frame (LibEditMode `AddFrame`) |

For each Blizzard bar, our settings are appended to **that bar's own Edit Mode
panel** (`LibEditMode:AddSystemSettings`, which passed AnotherHUD's spike on
Action Bar 1). Sections:

- **Look**: button shading (Bronze / Raised / Flat), hide Blizzard artwork
  (on / off), own padding (on / off) and padding (0-10 px).
- **Text**: hotkey on / off, macro name on / off, count / charges on / off,
  font size.
- **Fading**: opacity out of combat, full opacity on mouse-over.

The totem bar's Edit Mode panel has the same three sections (Text = time left
on / off and font size; Look = shading only).

What "our look" means per button: the approved mockup 4 (see Artwork) — the
skin border around the icon, shading, hover / pressed / active / empty
states, range / mana / unusable tints, cooldown swipe and time, text
placement, and the gold pulse proc glow in place of Blizzard's spell alert.

"Hide Blizzard artwork" hides the decorations around the buttons: the main
bar's end caps and background, the dividers and slot backgrounds behind
buttons, and the bar's own border art. Blizzard's button border, highlight,
pushed and flash textures are always replaced by ours (not a setting).

The player confirmed (2026-11-26) that Look, Text and Fading cover what they
need from the bars for now; anything else from the old addon is a later
release.

Addon-wide, in a small Settings window (slash command and the panels'
Settings button): skin (Classic, Forge, Slate, Gilded), which bars are on,
profiles. English and German texts.

## Non-goals (first release)

- Own secure action buttons, own paging, radial menus, extra bars.
- Bag bar, micro menu, extra action button, zone ability, vehicle / override
  bar art, possess bar, cooldown manager.
- Changing a button's look or layout in combat. Look and layout are applied
  out of combat; in combat Blizzard runs the buttons and we only react through
  hooks (tints, glow, cooldown text, fading).
- Importing another addon's settings; languages other than English and German.
- Death Knight, Demon Hunter and Monk specifics (not on Forever).

## Anti-goals (a failure even if it works)

- **Taint**: "Interface action failed because of an AddOn", blocked actions,
  or bars that stop working in combat because we touched them.
- **Lua errors from secret values**: arithmetic or comparisons on cooldown,
  charge or count values from the client.
- Writing to Blizzard tables (fields on Blizzard buttons or bars, Blizzard's
  padding value, Blizzard mixin functions).
- Copying or imitating other addons' code, art or design. Only the player's
  own addons (AnotherLedger, AnotherHUD) may be copied.
- New art shipped without an approved mockup.

## Constraints

- WoW Forever, retail engine, `## Interface: 16001`, Lua 5.1.
- **Combat lockdown**: creating our overlay frames, re-anchoring buttons,
  hiding artwork that is protected, showing / hiding secure frames: out of
  combat only, queued until `PLAYER_REGEN_ENABLED`.
- **Secret values**: cooldown start / duration, charges and counts go to
  widgets (`Cooldown:SetCooldown`, `FontString:SetText`, curve / color APIs)
  only, never into our math. Exact API surface: UNVERIFIED.
- **Taint**: `hooksecurefunc` and our own frames only; our per-button data
  lives in our own table keyed by button, never as fields on the button.
- Same tooling as AnotherLedger / AnotherHUD: plain-Lua tests
  (`lua tests/run.lua`, Lua 5.1 and 5.4 in CI), luacheck, GitHub Actions,
  BigWigs packager on `v*` tags with the `CF_API_KEY` secret, LibEditMode
  unmodified as a packager external.
- GitHub only (`https://github.com/mxhes/AnotherBars`, public, `main`, pull
  requests). Merging only when the player says so.

## Approaches (picked by the player: A)

- **A. Our overlay on each Blizzard button (picked).** Once, out of combat,
  every button gets a child frame of ours that holds the skin border, shading,
  state edges and proc glow; Blizzard's own border / highlight / glow textures
  are set to alpha 0. Tints and states follow Blizzard's updates via
  `hooksecurefunc`. Our padding is applied by re-anchoring the bar's buttons
  right after Blizzard lays the bar out (hook), out of combat. Lowest taint
  risk, Blizzard keeps all secure logic.
- B. Re-texture Blizzard's own regions: fewer frames, but Blizzard resets
  those textures on many updates and we would touch its regions far more
  often (more taint risk, constant fighting).
- C. Hide Blizzard's buttons and draw lookalikes: a lookalike can't take the
  clicks, so it turns into own secure buttons, which the player ruled out
  (AnotherHUD spec, 2026-11-21).

## Design

### Code base

AnotherBars copies AnotherHUD's core and renames it into its own namespace
(no shared library yet; a shared "Another" core stays a backlog idea):
`Core/Util`, `Locale`, `Theme` (colors, fonts, skins, `edgeRects`,
`skinScales`), `DB`, `Options`, `Profiles`, `Modules`, `Combat` (the
`after(fn)` queue), `EditMode/Glue`, `Panel`, the Settings window, the test
harness (`tests/run.lua`, fakes), `.luacheckrc`, `.pkgmeta`, CI. Docs layout
and `CLAUDE.md` as in AnotherHUD.

Saved state: `AnotherBarsDB` (account: profiles, totem bar positions per Edit
Mode layout), `AnotherBarsCharDB` (character: chosen profile). Look, text,
fading and padding settings are per profile, per bar. Blizzard bars keep
their positions in Blizzard's Edit Mode layouts.

### Modules

Each bar is one `ns.Modules.define{...}` (`Bars/ActionBar.lua` defines the
eight action bars from one table; `Bars/Stance.lua`, `Bars/Pet.lua`,
`Bars/Totem.lua`). The module's `settings` list feeds the Edit Mode panel and
the Settings window. Turning a bar off in the Settings window gives it back
Blizzard's look (needs a `/reload` if it can't be undone live).

### Button skin (`Skin/Button.lua`)

- `skin(button)`: once per button, out of combat. Creates our overlay frame
  (parented to the button, same size, frame level above the icon and below
  the cooldown text) with the border lines, shading, state edges and the proc
  glow; sets Blizzard's border / highlight / pushed / checked / flash /
  spell-alert textures to alpha 0; crops the icon.
- State updates come from hooks on Blizzard's button update functions (range,
  usable, checked, cooldown, spell alert show / hide; exact function names
  UNVERIFIED, found in the client). Hook bodies only call widget methods on
  our own regions and the icon's vertex color.
- Texts: Blizzard's hotkey, count and macro name font strings get our font,
  size and position, and are hidden / shown per setting (out of combat).

### Layout (`Skin/Layout.lua`)

- When "own padding" is on, after Blizzard lays out a bar (`hooksecurefunc`
  on the bar's layout function, UNVERIFIED name) we re-anchor its buttons in
  the same rows / columns and order Blizzard used, with our padding. Out of
  combat only; in combat the job waits in the `Combat.after` queue.
- **Fallback (player's decision, 2026-11-26), from the Plan 1 spike:**
  if a bar re-lays out in nearly every fight (e.g. on stance / form
  changes), "Own padding" defaults to off for that bar and its tooltip says
  why; other bars keep it. If re-anchoring Blizzard's buttons leaves
  AnotherBars lines in the taint log even out of combat, padding is dropped
  from the first release (backlog) and the release ships skin and artwork
  hiding; own secure buttons stay ruled out unless the player reopens that.
  The player sees the spike results before Plan 4 starts.
- The bar frame's size is not written (taint); if Blizzard's bar ends up
  larger than the buttons, the empty space is invisible (artwork hidden) and
  its Edit Mode selection box may be a bit larger (acceptable; noted in
  CHECKLIST).
- Where the buttons sit: the first button stays where Blizzard put it and
  the others close up toward it along Blizzard's growth direction, so a bar's
  first button does not move in existing Edit Mode layouts (Claude's call;
  shown in the padding-0 mockup, the player may pick centred instead).
- Pure part: `Core/Grid.lua` computes button offsets from count, rows,
  direction, button size and padding; tested in plain Lua.

### Artwork (`Skin/Art.lua`)

Hidden by alpha 0 or by reparenting to our hidden frame (out of combat), per
bar, when "Hide Blizzard artwork" is on. Exact region names: UNVERIFIED.

### Fading

Bar alpha from settings: out-of-combat opacity, full on mouse-over, full in
combat. `SetAlpha` on a protected bar in combat: UNVERIFIED; if it is
blocked, fading changes wait for combat to end.

### Totem bar (`Bars/Totem.lua`)

Own frame with four slots in the approved look (mockup 5), fed by
`PLAYER_TOTEM_UPDATE` / `GetTotemInfo`; time left as text from the client's
duration API and a drain bar (no math on secret values). Right-click on a
slot destroys the totem via a secure button with the `destroytotem` action
(UNVERIFIED). Blizzard's `TotemFrame` is hidden out of combat. Shown only
when a totem is up, and always in Edit Mode with sample totems.

### Edit Mode

- Blizzard bars: `AddSystemSettings(Enum.EditModeSystem.ActionBar, settings,
  index)` per bar, built from the module's settings list.
- Totem bar: `AddFrame` plus settings and our buttons, positions per Edit
  Mode layout, as in AnotherHUD.

## Artwork (approved, in AnotherHUD)

The button art, proc glow and totem bar were approved on 2026-11-21:
`D:\GitRepos\AnotherHUD\docs\mockups\4-buttons.html` (edge variant A, skin
border; proc glow 1, gold pulse) and `5-resources.html` (totem bar "as
shown"), written down in `docs/mockups/APPROVED.md` §4 and §5. AnotherBars
copies those pages and `APPROVED.md` §4-5 into its own `docs/mockups/`.

Not covered by those mockups, so mockup first before building: the look at
padding 0 (where two skin borders meet), and anything new on the Stance and
Pet bars (autocast marker on pet buttons).

## Plans

1. **Foundation**: repo scaffolding (`.toc` for Interface 16001,
   `embeds.xml`, core copied from AnotherHUD, tests, luacheck, CI,
   packaging, docs) plus a **client spike**: one setting on each bar's Edit
   Mode panel, a padding-0 re-anchor on Action Bar 1, and a dummy fight with
   `taintLog` on. The spike answers: does any bar re-lay out in combat
   (vehicle, override, possess, stance change), and does the taint log stay
   free of AnotherBars lines.
2. Mockup for padding 0 and the pet autocast marker.
3. Button skin and texts on all bars.
4. Layout (padding) and artwork hiding.
5. Fading.
6. Totem bar.

## Left to the builder

- File split inside the folders above, test layout, order inside a plan.
- Exact Blizzard function and region names (found in the client; each gets
  an `UNVERIFIED (check in client)` comment and a CHECKLIST line).
- Control ranges beyond those stated (font size range, opacity steps).

## Calls made by Claude (the player may overrule)

- Padding is our own setting ("Own padding" on / off plus 0-10 px) rather
  than a replacement for Blizzard's slider; off = Blizzard's spacing.
- If Blizzard re-lays out a bar in combat, that bar shows Blizzard's spacing
  until combat ends, then ours again.
- Skin is addon-wide (Settings window), not per bar; shading is per bar.
- Totem bar shows only while a totem is up (always in Edit Mode).
- Right-click destroys a totem (if the secure action works on Forever).
- Bars turned off need a `/reload` when they can't be restored live.
- Plans 2-6 order as above.
- Placement at tight padding: first button fixed, the rest close up toward it.
- No CurseForge project ID yet: Plan 1 leaves `## X-Curse-Project-ID` out
  (the packager then only builds the zip); it is added at the first release
  once the player has created the project, as in AnotherHUD.
