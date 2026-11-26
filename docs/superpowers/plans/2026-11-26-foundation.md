# AnotherBars Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A loadable, tested, packaged AnotherBars skeleton (core copied from AnotherHUD, the bar list, the padding math, settings on each Blizzard bar's Edit Mode panel) plus a client spike that answers the padding and taint questions before any skin work.

**Architecture:** Same layout and tooling as AnotherHUD: plain-Lua tests with fake frames and secret values, luacheck, GitHub Actions, BigWigs packager, LibEditMode as an unmodified packager external. Pure code in `Core/` and `EditMode/Panel.lua`; client code only inside functions. The spike lives in `Spike/` and is deleted when Plan 3 defines the real bar modules.

**Tech Stack:** Lua 5.1 (WoW Forever, Interface 16001), LibStub, CallbackHandler-1.0, LibEditMode (tag 19), luacheck, GitHub Actions, BigWigs packager.

**Spec:** `docs/superpowers/specs/2026-11-26-anotherbars-design.md`

## Roadmap (release 1)

Each plan is written when the one before has landed; the spike decides details of Plan 4.

| Plan | Delivers | Gate |
| --- | --- | --- |
| **1. Foundation** (this file) | repo tooling, core, bar list, padding math, Edit Mode system settings, client spike | player runs the spike in the client |
| 2. Mockups | padding 0 (meeting borders, first button fixed), pet autocast marker; copies of AnotherHUD's approved mockups 4-5 | **player approves** |
| 3. Button skin | overlay, states, tints, cooldown, proc glow, texts (Look shading + Text sections), Settings window with skin choice and bars on / off | client check |
| 4. Layout and artwork | own padding (or the spec's fallback), hide Blizzard artwork | client check |
| 5. Fading | Fading section | client check |
| 6. Totem bar | own frame, `AddFrame` glue, sample totems in Edit Mode | client check |

## Global Constraints

- `## Interface: 16001`; Lua 5.1 code (no `goto`, `//`, `table.unpack`); tests also run on 5.4.
- Addon folder `AnotherBars/`; saved variables `AnotherBarsDB` (account) and `AnotherBarsCharDB` (character).
- Every file starts `local ADDON, ns = ...`; WoW globals only inside functions.
- Option labels at most 24 characters in English and German; texts through `ns.L`, German in `Locales/deDE.lua`.
- LibEditMode unmodified (packager external, tag `"19"`), no hooks into its internals.
- Never write to Blizzard tables: no fields on Blizzard frames, no replaced Blizzard functions, never Blizzard's padding value. Hooks via `hooksecurefunc`; our per-button / per-bar data in our own tables keyed by frame.
- Nothing touches secure frames in combat (`ns.Combat.after`).
- No arithmetic or comparison on client cooldown, charge, count or totem time values.
- Only AnotherLedger / AnotherHUD code may be copied; no other addon's code, art or design.
- Commits `feat:` / `fix:` / `docs:` / `refactor:` / `test:`; remote `https://github.com/mxhes/AnotherBars`, branch `main`, pull requests with `gh`; merge only when the player says so.

## Review Focus

1. **A bar laid out again by Blizzard while in combat** (stance change, vehicle): our re-anchor must queue, never run in combat. Test in Task 4 (`"relayout in combat queues the repack"`).
2. **A bar with fewer visible buttons than slots, or with several rows** (Edit Mode "Rows" 2-4, "# of Icons" 6): the repack keeps Blizzard's rows / columns and order, only the gaps change. Test in Task 3 (`"keeps rows and columns"`, `"partial last row"`).
3. **Growth to the left or downward** (bars whose buttons run right-to-left or bottom-to-top): offsets keep their sign; the first button stays put. Test in Task 3 (`"negative directions keep sign"`).
4. **LibEditMode missing** (dev copy without `Libs/`): the addon loads, no system settings, no Lua error. Test in Task 5 (`"works without LibEditMode"`).
5. **German labels longer than 24 characters**. Test in Task 2 (`"labels fit 24 glyphs in en and de"`).

---

### Task 1: Repo scaffold and tooling

**Files:**
- Create: `.pkgmeta`, `.github/workflows/ci.yml`, `.luacheckrc`, `CHANGELOG.md`, `docs/CHECKLIST.md`, `docs/BACKLOG.md`, `docs/DEVELOPMENT.md`
- Create: `AnotherBars/AnotherBars.toc`, `AnotherBars/embeds.xml`, `AnotherBars/Boot.lua`
- Create: `tests/harness.lua`, `tests/run.lua`, `tests/test_toc.lua`
- Modify: `README.md` ("in development")

**Interfaces:**
- Produces: `h.load(files)` (paths under `AnotherBars/`), `h.toc()` (`.toc` file list in order, `.xml` skipped), `h.test(name, fn)`, `h.eq`, `h.near` — AnotherHUD's harness with the folder renamed.

- [ ] **Step 1:** Copy `tests/harness.lua` and `tests/run.lua` from `D:\GitRepos\AnotherHUD`, replacing `AnotherHUD` with `AnotherBars`.
- [ ] **Step 2: Write the failing test** `tests/test_toc.lua`: `"every .toc file exists"`, `"Boot.lua is last"`, `"interface is 16001"` (the `.toc` has the line `## Interface: 16001`).
- [ ] **Step 3:** Run `lua tests/run.lua` — expected FAIL (no `.toc`).
- [ ] **Step 4:** Create the `.toc` (`## Interface: 16001`, `## Title: AnotherBars`, `## Notes: Blizzard's action bars in the Another suite's look, with Edit Mode settings.`, `## Version: @project-version@`, `## Author: Maximilian Henjes`, `## X-Website: https://github.com/mxhes/AnotherBars`, `## SavedVariables: AnotherBarsDB`, `## SavedVariablesPerCharacter: AnotherBarsCharDB`, `## OptionalDeps: LibStub, CallbackHandler-1.0, LibEditMode`; no `X-Curse-Project-ID` yet; then `embeds.xml`, `Boot.lua`), `embeds.xml` (copy of AnotherHUD's), `Boot.lua` (`local ADDON, ns = ...` only).
- [ ] **Step 5:** Copy and rename `.pkgmeta` (`package-as: AnotherBars`, move-folders `AnotherBars/AnotherBars: AnotherBars`, the three externals into `AnotherBars/Libs/`, LibEditMode tag `"19"`, same `ignore` list), `.github/workflows/ci.yml` (artifact names `AnotherBars-release` / `AnotherBars-dry-run`, `luacheck AnotherBars`), `.luacheckrc` (exclude `AnotherBars/Libs/`, globals `AnotherBarsDB`, `AnotherBarsCharDB`; `read_globals` start with only what Tasks 1-5 read). `CHANGELOG.md` with an "Unreleased" heading. `docs/CHECKLIST.md`: an "Open checks" heading and AnotherHUD's "Release steps" renamed (step for `X-Curse-Project-ID` kept as "once the project exists"). `docs/BACKLOG.md`: "Shared 'Another' suite core (code shared with AnotherLedger and AnotherHUD)". `docs/DEVELOPMENT.md`: Setup (junction into `_forever_\Interface\AddOns\AnotherBars`, libs from the `package-dry-run` artifact, never from another addon's copy) and a "Code layout" table, both adapted from AnotherHUD.
- [ ] **Step 6:** Run `lua tests/run.lua` — PASS; `luacheck AnotherBars` — 0 warnings (if luacheck is missing locally, CI runs it).
- [ ] **Step 7: Commit** `feat: repo scaffold, tests, CI and packaging`; push the branch, open a PR; CI `test` (5.1, 5.4) and `lint` green. Run the `package-dry-run` workflow once by hand and check the zip holds one `AnotherBars/` folder with the `.toc` and `Libs/LibEditMode/embed.xml`.

### Task 2: Core copied from AnotherHUD

**Files:**
- Create (copied from `D:\GitRepos\AnotherHUD\AnotherHUD\`, renamed): `Core/Util.lua`, `Core/Locale.lua`, `Locales/deDE.lua`, `Core/Theme.lua`, `Core/DB.lua`, `Core/Modules.lua`, `Core/Options.lua`, `Core/Combat.lua`, `Media/Skins/Stud.tga`, `Media/Skins/Dotted.tga`
- Create: `tests/fakes.lua` (copied), `tests/test_fakes.lua`, `tests/test_db.lua`, `tests/test_theme.lua`, `tests/test_modules.lua`, `tests/test_options.lua`, `tests/test_combat.lua` (copied from AnotherHUD, cut to what these files hold)
- Modify: `AnotherBars.toc` (in this order before `Boot.lua`: Util, Locale, deDE, Theme, DB, Modules, Combat, Options)

**Interfaces:**
- Produces (same names and behavior as AnotherHUD): `ns.Util.copy/merge/clamp/isSecret/say` (chat prefix `AnotherBars`); `ns.L`, `ns.Locale.register`; `ns.Theme` (colors, fonts, skins Classic / Forge / Slate / Gilded, `edgeRects`, `skinScales`); `ns.DB.init(saved, charSaved) -> db, chardb`, `ns.DB.profile()`; `ns.Modules.define(spec)` with `kind = "bar"|"misc"` only, `list`, `get`, `isEnabled`, `setEnabled`; `ns.Options.get(id, key)`, `ns.Options.set(id, key, value)` (through `Combat.after`), `ns.Options.longLabels(specs, L, max)`; `ns.Combat.after(key, fn)`, `ns.Combat.pending()`; `fakes.frame`, `fakes.client{ inCombat }`, `fakes.secret(n)`.
- New in `Modules.define`: an optional `system = { index = "<Enum.EditModeActionBarSystemIndices key>" }` field (Task 5 reads it).

- [ ] **Step 1:** Copy the files; replace `AnotherHUD` with `AnotherBars` everywhere (Theme's texture paths become `Interface\\AddOns\\AnotherBars\\Media\\...`). Drop what is unit-only: Theme's unit textures (disc, spark, shield, roles, crown, bar textures under `Media\Units`) unless a kept entry needs them; the `"unit"` module kind; DB defaults that only units use. Keep `glow` only if `Media/Units/Glow.tga` is copied (Plan 3 decides; not now).
- [ ] **Step 2: Write the failing tests** (the copied ones, plus): `"every Theme texture file exists"` (each `Interface\\AddOns\\AnotherBars\\...` path in `Theme` maps to a file under `AnotherBars/` with `.tga`); `"modules reject kind unit"`; `"labels fit 24 glyphs in en and de"` (for every defined module, `Options.longLabels` returns empty; run in Task 5 too once modules exist).
- [ ] **Step 3:** Run — the new tests FAIL until the cuts are made; make them pass.
- [ ] **Step 4:** Run `lua tests/run.lua` and `luacheck AnotherBars` — PASS, 0 warnings.
- [ ] **Step 5: Commit** `feat: core copied from AnotherHUD (util, locale, theme, saved state, modules, options, combat queue)`.

### Task 3: Bar list and padding math (pure)

**Files:**
- Create: `AnotherBars/Core/Bars.lua`, `AnotherBars/Core/Grid.lua`
- Modify: `AnotherBars.toc` (after `Options.lua`)
- Test: `tests/test_bars.lua`, `tests/test_grid.lua`

**Interfaces:**
- Produces:
  - `ns.Bars.list` — ten entries in this order, each `{ id, label, frame, button, count, system }` (frame / button names UNVERIFIED on Forever):

    | id | label | frame | button | count | system |
    | --- | --- | --- | --- | --- | --- |
    | `bar1` | Action Bar 1 | `MainMenuBar` | `ActionButton` | 12 | `MainBar` |
    | `bar2` | Action Bar 2 | `MultiBarBottomLeft` | `MultiBarBottomLeftButton` | 12 | `Bar2` |
    | `bar3` | Action Bar 3 | `MultiBarBottomRight` | `MultiBarBottomRightButton` | 12 | `Bar3` |
    | `bar4` | Action Bar 4 | `MultiBarRight` | `MultiBarRightButton` | 12 | `RightBar1` |
    | `bar5` | Action Bar 5 | `MultiBarLeft` | `MultiBarLeftButton` | 12 | `RightBar2` |
    | `bar6` | Action Bar 6 | `MultiBar5` | `MultiBar5Button` | 12 | `ExtraBar1` |
    | `bar7` | Action Bar 7 | `MultiBar6` | `MultiBar6Button` | 12 | `ExtraBar2` |
    | `bar8` | Action Bar 8 | `MultiBar7` | `MultiBar7Button` | 12 | `ExtraBar3` |
    | `stance` | Stance Bar | `StanceBar` | `StanceButton` | 10 | `StanceBar` |
    | `pet` | Pet Bar | `PetActionBar` | `PetActionButton` | 10 | `PetActionBar` |

    `system` is the key in `Enum.EditModeActionBarSystemIndices` (UNVERIFIED; check `/dump Enum.EditModeActionBarSystemIndices` in the client and fix the table).
  - `ns.Bars.get(id)`.
  - `ns.Grid.cells(offsets) -> cells`: `offsets = { { x, y }, ... }` each button's top-left relative to button 1's top-left (button 1 is `{ 0, 0 }`); returns `{ { col, row }, ... }` (integers, signs kept: a button left of button 1 has a negative `col`). The column step is the smallest `|x|` above 0.5 among the offsets, the row step likewise for `|y|`; `col = round(x / step)`, `row = round(y / step)`, 0 when no step exists.
  - `ns.Grid.offsets(cells, w, h, padding) -> offsets`: `{ col * (w + padding), row * (h + padding) }` per cell.
  - `ns.Grid.repack(offsets, w, h, padding) -> offsets` = `offsets(cells(o), w, h, padding)`.
  These take plain layout numbers from frame geometry (`GetLeft` / `GetTop`), never client secret values.

- [ ] **Step 1: Write the failing tests:** Bars — `"ten bars in order"` (ids as above), `"ids unique and labels set"`. Grid — `"one row at padding 0"` (offsets `{0,0},{38,0},{76,0}` with w = h = 36 → repack padding 0 gives `{0,0},{36,0},{72,0}`); `"keeps rows and columns"` (2 rows of 3, row step −38 → padding 0 gives rows at y = 0 and −36); `"partial last row"` (5 buttons in rows of 3: the 4th and 5th keep columns 0 and 1 of row 1); `"negative directions keep sign"` (offsets `{0,0},{-40,0}` → `{0,0},{-36,0}`); `"single button"` (`{0,0}` stays); `"rounds small drift"` (`{38.3, 0.2}` → cell `{1, 0}`).
- [ ] **Step 2:** Run — FAIL. **Step 3:** Implement. **Step 4:** Run tests and luacheck — PASS.
- [ ] **Step 5: Commit** `feat: bar list and padding math`.

### Task 4: Re-layout hook and repack (client glue, tested with fakes)

**Files:**
- Create: `AnotherBars/Core/Layout.lua`
- Modify: `AnotherBars.toc` (after `Grid.lua`), `.luacheckrc` (`hooksecurefunc`, `_G`, `InCombatLockdown`)
- Test: `tests/test_layout.lua`

**Interfaces:**
- Consumes: `ns.Bars`, `ns.Grid.repack`, `ns.Combat.after`.
- Produces:
  - `ns.Layout.watch(barId, onLayout)`: once per bar, `hooksecurefunc(barFrame, "UpdateGridLayout", fn)` (method name UNVERIFIED; CHECKLIST line `/dump MainMenuBar.UpdateGridLayout ~= nil`); `fn` calls `onLayout(barId, InCombatLockdown())`. Missing frame or method: does nothing (no error).
  - `ns.Layout.repack(barId, padding)`: through `Combat.after("repack:" .. barId, ...)`: reads button 1..count (shown buttons only) via `_G[button .. i]`, offsets from `GetLeft()` / `GetTop()` relative to button 1 (scaled into the bar's space, UNVERIFIED with Icon Size scaling), `w, h` from button 1's `GetWidth()` / `GetHeight()`, then for buttons 2..n `ClearAllPoints()` and `SetPoint("TOPLEFT", button1, "TOPLEFT", x, y)`. Button 1 is never moved. Writes nothing on the bar or button tables.

- [ ] **Step 1: Write the failing tests** (fake bar with fake buttons positioned in a row): `"repack moves buttons 2..n, never button 1"`; `"relayout in combat queues the repack"` (`fakes.client{ inCombat = true }`, call repack, no `SetPoint` recorded, `Combat.pending() == 1`; after `setCombat(false)` + `PLAYER_REGEN_ENABLED` the points are set); `"watch calls back with combat flag"`; `"missing bar is ignored"`; `"no fields written on Blizzard frames"` (snapshot `pairs()` keys of the fake bar and buttons before and after; equal).
- [ ] **Step 2:** Run — FAIL. **Step 3:** Implement. **Step 4:** Run — PASS, luacheck clean.
- [ ] **Step 5: Commit** `feat: re-layout hook and padding repack`.

### Task 5: Settings on Blizzard's bar panels, boot and slash command

**Files:**
- Create: `AnotherBars/EditMode/Panel.lua` (copy of AnotherHUD's `Panel.build`), `AnotherBars/EditMode/System.lua`, `AnotherBars/Core/Core.lua`
- Modify: `AnotherBars/Boot.lua` (calls `ns.Core.init()` on `ADDON_LOADED` for this addon), `.toc`, `.luacheckrc` (`LibStub`, `Enum`, `SlashCmdList`, `SLASH_ANOTHERBARS1`)
- Test: `tests/test_panel.lua` (copied), `tests/test_system.lua`

**Interfaces:**
- Consumes: `ns.Modules.list`, `ns.EditMode.Panel.build(spec, types)`, `ns.DB.init`.
- Produces:
  - `ns.EditMode.System.attachAll()`: if `LibStub("LibEditMode", true)` is nil, returns. Else for each enabled module with `spec.system`, `lem:AddSystemSettings(Enum.EditModeSystem.ActionBar, Panel.build(spec, lem.SettingType), Enum.EditModeActionBarSystemIndices[spec.system.index])`. Settings are per profile (the `layoutName` argument is ignored).
  - `ns.Core.init()`: `AnotherBarsDB, AnotherBarsCharDB = ns.DB.init(...)`, `ns.db, ns.chardb` set, then `ns.EditMode.System.attachAll()`, then the spike's `ns.Spike.start()` if it exists.
  - Slash `/abars` (`/anotherbars`): `spike` subcommands come from Task 6; no subcommand prints the version.

- [ ] **Step 1: Write the failing tests** (fake LEM recording calls): `"one system settings call per bar module"`; `"uses the bar's system index"`; `"skips disabled modules"`; `"works without LibEditMode"`; `"labels fit 24 glyphs in en and de"` over all defined modules.
- [ ] **Step 2:** Run — FAIL. **Step 3:** Implement. **Step 4:** Run — PASS, luacheck clean.
- [ ] **Step 5: Commit** `feat: settings on Blizzard's bar Edit Mode panels`.

### Task 6: Client spike (padding, re-layout in combat, taint, fading)

**Files:**
- Create: `AnotherBars/Spike/Spike.lua` (defines one `kind = "bar"` module per `ns.Bars.list` entry with `system` set, each with one section "Spike" holding one checkbox `padding0`, label "Spike: padding 0", default off)
- Modify: `.toc` (before `Core/Core.lua`), `docs/CHECKLIST.md`, `docs/DEVELOPMENT.md` ("Spike check" steps as in AnotherHUD, with `AnotherBars` paths and taint-log search for `AnotherBars`)
- Test: `tests/test_spike.lua`

**Interfaces:**
- Consumes: `ns.Layout.watch/repack`, `ns.Bars.list`, `ns.Modules.define`, `ns.Options.get`.
- Produces: `ns.Spike.start()`: `Layout.watch` on every bar; each callback prints `"<label> laid out (in combat: yes/no)"` to chat while logging is on, and when that bar's `padding0` is on calls `Layout.repack(id, 0)`. The modules' `apply` calls `Layout.repack(id, 0)` when turned on (turning off asks for `/reload`). `/abars spike log` toggles logging (default on in this build); `/abars spike alpha` sets `MultiBarBottomLeft:SetAlpha(0.5)` now (even in combat) and `1` on the next call, printing whether `SetAlpha` raised an error (`pcall`).

- [ ] **Step 1: Write the failing tests:** `"one spike module per bar"`; `"layout callback repacks only bars with padding0 on"`; `"log prints combat flag"`.
- [ ] **Step 2:** Run — FAIL. **Step 3:** Implement; every client call gets `UNVERIFIED (check in client)`. **Step 4:** Run — PASS, luacheck clean.
- [ ] **Step 5:** Add the "Plan 1 spike" section to `docs/CHECKLIST.md`:
  - Library loaded: `/dump LibStub and LibStub("LibEditMode", true) ~= nil` prints `true`.
  - `/dump Enum.EditModeActionBarSystemIndices` matches `Core/Bars.lua`; each of the ten bar names exists (`/dump MultiBar5 ~= nil`, ...); `/dump MainMenuBar.UpdateGridLayout ~= nil`.
  - "Spike: padding 0" shows in each of the ten Blizzard bar panels; turning it on closes the gaps on that bar, button 1 does not move; Rows 2 and 3 and "# of Icons" 6 keep the shape.
  - Leaving Edit Mode, `/reload`, changing Icon Size and Padding in Blizzard's panel: our padding comes back after each change.
  - **Re-layout in combat:** with logging on, fight a target dummy as a Warrior (stance changes) and a Druid (form changes), with a pet class (pet summon / dismiss), and in a vehicle if one is at hand: write down every "laid out (in combat: yes)" line and which bar.
  - **Taint:** `/console taintLog 1`, `/reload`; padding 0 on all bars; fight a dummy casting from every bar, change stance / form, open the spellbook and talents in combat: no "Interface action failed" / blocked message; `_forever_\Logs\taint.log` has no `AnotherBars` lines.
  - **Fading:** `/abars spike alpha` in combat: no error, Action Bar 2 goes to half opacity, buttons still work.
- [ ] **Step 6:** Link the addon into the client, install the libs, and **ask the player to run the checks**. Record results in `CHECKLIST.md` (date, pass / fail, what was seen). Apply the spec's fallback in Plan 4's notes: bars that re-lay out in nearly every fight get "Own padding" off by default; AnotherBars lines in the taint log from re-anchoring drop padding from release 1.
- [ ] **Step 7: Commit** `feat: client spike for padding, re-layout in combat and fading`; update the PR; the player merges when they say so.

## After this plan

Plan 2 (mockups) may start once Task 5 lands; Plan 4 waits for the spike results. `Spike/` is deleted in Plan 3, where the real modules (`Bars/ActionBar.lua`, `Bars/Stance.lua`, `Bars/Pet.lua`) replace its spike modules (one module per Edit Mode system); `Core/Layout.lua` and `Core/Grid.lua` stay and Plan 4 builds "Own padding" on them.
