# Button Skin Implementation Plan (Plan 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every button on Action Bars 1-8, the Stance Bar and the Pet Bar wears the approved look (mockup 4, plus the pet autocast badge of mockup 7), with the Text settings and a per-bar shading pick on each bar's Edit Mode panel. A small Settings window lets the player pick the skin and turn bars on or off.

**Architecture:** One overlay set of our own frames per Blizzard button (back fill, front edges and states, text holder, proc glow), created once out of combat. Blizzard's own border, highlight, pushed, checked, flash and spell-alert textures go to alpha 0. State changes come from `hooksecurefunc` on Blizzard's update functions, and the hook bodies only call widget methods. Every decision (colors, sizes, tints, which state shows) is a pure function in `Core/Look.lua` and tested in plain Lua. Every Blizzard name sits in one client file (`Skin/Blizzard.lua`), so a wrong name is a one-line fix. The Settings window is Blizzard's own Settings panel (native controls, so no new art).

**Tech Stack:** Lua 5.1, WoW Forever client API (Interface 16001), LibEditMode (unchanged), plain-Lua tests (`lua tests/run.lua`), luacheck.

**Spec:** `docs/superpowers/specs/2026-11-26-anotherbars-design.md`, sections "Button skin", "Modules", "Edit Mode", "Artwork". The art comes from `docs/mockups/APPROVED.md` §4 (buttons, proc glow) and §7 (pet badge). §6 (padding 0) is Plan 4.

## Global Constraints

- WoW Forever, `## Interface: 16001`, Lua 5.1 (no `goto`, `//`, `table.unpack`).
- Nothing touches a secure frame in combat. Creating, anchoring, sizing, showing, hiding and setting Blizzard regions all go through `ns.Combat.after(key, fn)`. Hook bodies that run in combat may only call `SetVertexColor`, `SetDesaturated`, `SetAlpha`, `Show` and `Hide` on **our own** regions, plus `SetVertexColor` / `SetDesaturated` on the button's icon.
- No fields on Blizzard frames, no replaced Blizzard functions. Per-button data lives in our weak table keyed by button.
- Secret values: no arithmetic, comparisons or branches on values from the client (range, usable, mana, checked, autocast). Run a value through `ns.Util.plain(v)` first, which returns nil for a secret (`issecretvalue`, UNVERIFIED). On nil, leave Blizzard's own tint and state untouched.
- Option labels are at most 24 characters, every option has a tooltip, all texts go through `ns.L`, and German goes in `Locales/deDE.lua`.
- Each unconfirmed client API gets an `UNVERIFIED (check in client)` comment and a CHECKLIST line.
- Only the player's own addons are sources: AnotherHUD (`Units/Parts/Panel.lua` line rectangles, `Units/Parts/Ring.lua` disc stack, `Media/Units/Disc.tga`, `Theme.ringRoundShades`).

## Calls made in this plan (the player may overrule)

- **Shading per bar** is a dropdown: "Skin" (default, follows the skin's Buttons pick), "Bronze", "Raised", "Flat". The skin itself is addon-wide and lives in the Settings window.
- **One "Font size" slider per bar** (6-16, default 10) sets the hotkey size. The others scale from it as in the approved ratios at 40 px: count ×1.2, macro name ×0.9, cooldown time ×1.5 (rounded).
- **Text on / off** hides through `SetAlpha(0)`, so Blizzard's own `Show` calls can't bring the text back.
- **Settings window** = Blizzard's Settings panel ("AnotherBars" category). `/abars` opens it, `/abars version` prints the version, and each bar's Edit Mode panel gets a "Settings" button.
- **Turning a bar off** needs a `/reload`, since the skin can't be undone live. Turning one on skins it at once.
- **The spike goes away** (`Spike/Spike.lua`, `tests/test_spike.lua`). Its padding checkbox comes back as the real "Own padding" in Plan 4. `Core/Layout.lua` and `Core/Grid.lua` stay for Plan 4.

## Review Focus

1. **A secret range / usable / checked value in combat**: no Lua error, and Blizzard's own tint stays. Test: `Look.iconTint` with nil inputs returns nil, and the hook skips on nil.
2. **A bar turned on in combat**: nothing is created until combat ends, then the skin appears. Test in `test_buttons.lua`.
3. **Skin change while bars are skinned**: every skinned button relayouts (edge width differs per skin) without creating a second overlay. Test: `Button.skin` twice → one overlay set, new edge count.
4. **A button that does not exist on Forever** (e.g. `MultiBar7Button5` missing): skipped, no error. Test in `test_buttons.lua`.
5. **Empty slot with an action dragged in**: the empty look goes away on Blizzard's next update. Test: the update hook with the icon shown clears the empty state.

---

### Task 1: Pure look rules (`Core/Look.lua`)

**Files:**
- Create: `AnotherBars/Core/Look.lua`, `tests/test_look.lua`
- Modify: `AnotherBars/Core/Util.lua` (add `Util.plain`), `AnotherBars/Core/Theme.lua` (add `Theme.button` values, `textures.disc`, `ringRoundShades`), `AnotherBars/AnotherBars.toc`, `.luacheckrc` (`issecretvalue`)

**Interfaces:**
- Produces:
  - `Util.plain(v) -> v | nil`: nil when `issecretvalue` exists and says v is secret.
  - `Look.skin() -> Theme.skins entry`: from `DB.profile().skin`, Classic when missing or unknown.
  - `Look.edges(border, hover) -> { { inset, color } ... }`: the skin's edge lines (round = `{0.35, 1, 1}` shades as in `buttons.js`, else `Theme.edgeRects` shades) on `panelBorder`, or on `goldLine` when hover is true.
  - `Look.edgeWidth(border) -> number`: round 3, bevel 5, thin 2, gilded 6.
  - `Look.shading(barPick, skin) -> "bronze" | "raised" | "flat"`.
  - `Look.iconTint(inRange, usable, noMana) -> { r, g, b, desaturate } | nil`. Out of range → `{0.8, 0.1, 0.1}`. Else no mana → `{0.5, 0.5, 1}`. Else unusable → `{0.55, 0.55, 0.55, desaturate = true}`. Else `{1, 1, 1}`. Returns nil when any argument it needs is nil.
  - `Look.fontSizes(size) -> { hotkey, count, macro, cooldown }`.
- Theme values (Theme.button): swipe alpha 0.72, pressed overlay black 0.3, hover overlay `{1, 0.9, 0.59, 0.16}`, empty fill alpha 0.75, macro color `{0.93, 0.87, 0.72}`, glow out 5 / line 2 / outer 10 at 0.75 / inner 8 at 0.6 / pulse 0.55-1, 1.0-1.06, 1.1 s, badge 11 px with a 4 px dot breathing 0.7-1 over 1.4 s, stud 7 px.

- [ ] **Step 1: Write the failing tests** in `tests/test_look.lua`:
  - `Look.edgeWidth("round") == 3`, `("bevel") == 5`, `("thin") == 2`, `("gilded") == 6`.
  - `#Look.edges("bevel", false) == 5`; every line's color is `panelBorder` scaled by its shade; with hover the base color is `goldLine`.
  - `Look.shading("Skin", Theme.skins.forge) == "raised"`, `Look.shading("Flat", Theme.skins.forge) == "flat"`.
  - `Look.iconTint(false, true, false)` gives `{0.8, 0.1, 0.1}`, `(true, false, true)` gives `{0.5, 0.5, 1}`, `(true, false, false)` desaturates at 0.55, `(true, true, false)` gives white, `(nil, true, false)` is nil.
  - `Look.fontSizes(10)` gives `{ hotkey = 10, count = 12, macro = 9, cooldown = 15 }`.
  - `Look.skin()` with `profile.skin = "nope"` is Classic.
  - `Util.plain`: with a fake `issecretvalue` that returns true, it returns nil; with no `issecretvalue`, it returns the value.
- [ ] **Step 2: Run** `lua tests/run.lua`. Expected: the new tests FAIL (Look is nil).
- [ ] **Step 3: Implement** `Core/Look.lua` and the Theme / Util additions. Add Look to the `.toc` after `Core/Theme.lua`, and `issecretvalue` to `.luacheckrc` `read_globals` (UNVERIFIED comment at its use).
- [ ] **Step 4: Run** `lua tests/run.lua` and `luacheck AnotherBars`. Expected: all pass, 0 warnings.
- [ ] **Step 5: Commit** `feat: pure look rules for the button skin`.

### Task 2: Blizzard names in one place (`Skin/Blizzard.lua`)

**Files:**
- Create: `AnotherBars/Skin/Blizzard.lua`, `tests/test_blizzard.lua`
- Modify: `.toc`, `.luacheckrc`

**Interfaces:**
- Produces (all client glue; each returns nil / does nothing when the name is missing):
  - `Blizzard.regions(button) -> { icon, cooldown, hotkey, count, name, hide = { textures to alpha 0 }, mask, autocast = { ... } }`. Hidden textures: `GetNormalTexture()`, `GetHighlightTexture()`, `GetPushedTexture()`, `GetCheckedTexture()`, `.Flash`, `.Border`, `.NewActionTexture`, `.SpellHighlightTexture`. Icon `.icon` or `.Icon`, cooldown `.cooldown`, texts `.HotKey`, `.Count`, `.Name`, mask `.IconMask`. Pet: `.AutoCastOverlay`, `.AutoCastable`, `.AutoCastShine`.
  - `Blizzard.onRange(fn)`: hooks the global `ActionButton_UpdateRangeIndicator(button, checksRange, inRange)` and calls `fn(button, inRange)`.
  - `Blizzard.onUpdate(button, fn)`: hooks the button's `Update` and `UpdateUsable` methods (whichever exist) and calls `fn(button)`.
  - `Blizzard.onChecked(button, fn)`: hooks `SetChecked` and calls `fn(button, button:GetChecked())`.
  - `Blizzard.onPressed(button, fn)`: hooks `SetButtonState` plus `HookScript` `OnMouseDown` / `OnMouseUp` and calls `fn(button, pressed)`.
  - `Blizzard.onHover(button, fn)`: `HookScript` `OnEnter` / `OnLeave` → `fn(button, over)`.
  - `Blizzard.onAlert(show, hide)`: hooks `ActionButtonSpellAlertManager:ShowAlert / HideAlert`, or else the globals `ActionButton_ShowOverlayGlow / HideOverlayGlow`.
  - `Blizzard.spellAlert(button) -> region | nil`: `.SpellActivationAlert` (created lazily by Blizzard, so read it after a show).
  - `Blizzard.onPetUpdate(fn)`: hooks `PetActionBar:Update`, or else the global `PetActionBar_Update`; for each `PetActionButton1-10` it calls `fn(button, autoCastAllowed, autoCastEnabled)` from `GetPetActionInfo(i)` (values 5 and 6).
  - `Blizzard.hookOnce(target, name, fn)`: hooksecurefunc, at most once per target and name (our own table).
- Every name gets `-- UNVERIFIED (check in client)`.

- [ ] **Step 1: Write the failing tests** with `tests/fakes.lua` frames:
  - `regions` on a fake button with `icon`, `HotKey` and a normal texture lists them; on a bare frame it returns empty lists, no error.
  - `hookOnce` called twice hooks once (count the fake `hooksecurefunc` calls).
  - `onAlert` uses the manager when `ActionButtonSpellAlertManager` exists and the globals otherwise.
  - `onPetUpdate` passes values 5 and 6 of a fake `GetPetActionInfo`.
  - No field is written on a fake Blizzard button (keys check as in `test_layout.lua`).
- [ ] **Step 2: Run** the tests. Expected: FAIL.
- [ ] **Step 3: Implement** `Skin/Blizzard.lua`. Add it to the `.toc` after `Core/Layout.lua`; add the globals to `read_globals`.
- [ ] **Step 4: Run** the tests and luacheck. Expected: pass.
- [ ] **Step 5: Commit** `feat: Blizzard button names and hooks in one file`.

### Task 3: The button overlay (`Skin/Button.lua`, `Skin/Glow.lua`)

**Files:**
- Create: `AnotherBars/Skin/Button.lua`, `AnotherBars/Skin/Glow.lua`, `tests/test_buttons.lua`
- Modify: `.toc`, `tests/fakes.lua` (only what the tests need: `CreateFont`, `SetFrameLevel` / `GetFrameLevel`, `SetBackdrop*`, `SetTexCoord`, `SetGradient`, `CreateAnimationGroup` recording)

**Interfaces:**
- Consumes: Task 1 `Look.*`, Task 2 `Blizzard.*`.
- Produces:
  - `Button.skin(button, opts)`, where `opts = { shading, hotkey, count, macro, fontSize }`. Out of combat (`Combat.after("skin:" .. name)`), it is idempotent: a second call relayouts and never creates a second set. It creates, parented to the button:
    - **back**: frame level button − 1 (UNVERIFIED that it draws under the button's icon). The panelTint fill; for Round, a `BackdropTemplate` with the tooltip edge at edgeSize 8 (UNVERIFIED that it matches the mockup's 3 px round edge).
    - **front**: level + 2. Line rects from `Look.edges` (AnotherHUD `Panel.lua` `placeRect`), shading lines, the active edge (2 px gold plus inner glow strips), the hover overlay, the pressed overlay, the empty fill with its inner shadow, and Gilded studs (7 px) on the four corners.
    - **text**: level + 3. HotKey, Count and Name are re-parented onto it (`SetParent` on Blizzard's font strings, out of combat), get our font and size with OUTLINE, sit at top right / bottom right / bottom center, and the macro name gets its cream color. Off → `SetAlpha(0)`.
    - The cooldown frame goes to level + 1 and is inset to the icon, with `SetSwipeColor(0, 0, 0, 0.72)`, `SetDrawEdge(false)` and `SetCountdownFont` with a gold font object per size (`CreateFont("AnotherBarsCooldown" .. size)`).
    - The icon gets `SetTexCoord(0.08, 0.92, 0.08, 0.92)`, is inset by the edge width, and has its mask removed.
    - Every `Blizzard.regions(...).hide` texture is set to alpha 0.
  - The hooks are wired once per button and only change our regions: range / usable → `Look.iconTint` on the icon (nil → skip); checked → active edge on / off; pressed → pressed overlay; hover → edges in goldLine plus the hover overlay; update → empty fill when the icon is hidden. The proc glow comes from `Glow`.
  - `Button.relayoutAll()`: re-skins every skinned button with its last opts (on a skin change).
  - `Glow.attach(button, front) -> glow`, with `glow:show()` / `glow:hide()`. A frame 5 px outside the button: a 2 px goldLine rectangle, 10 px outer and 8 px inner gradient strips (`SetGradient`, UNVERIFIED on Forever), and one animation group of alpha 0.55↔1 and scale 1↔1.06, 1.1 s, bounce. `show` also sets Blizzard's spell alert to alpha 0.
- State per button lives in `local state = setmetatable({}, { __mode = "k" })`.

- [ ] **Step 1: Write the failing tests:**
  - "skin creates one overlay set": skin twice → `#state` regions unchanged and the frame count created once.
  - "Blizzard textures go to alpha 0": the fake normal / highlight / pushed / checked textures get `SetAlpha(0)`.
  - "skin in combat waits": with `inCombat`, nothing is created; after `PLAYER_REGEN_ENABLED`, it is.
  - "a missing button is skipped": `Button.skin(nil, opts)` raises no error.
  - "range hook tints the icon": out of range → icon `SetVertexColor(0.8, 0.1, 0.1)`; a secret (fake `issecretvalue` true) → no `SetVertexColor` call.
  - "empty slot follows the icon": icon hidden → empty fill shown; icon shown and update fired → hidden.
  - "texts off use alpha": `hotkey = false` → HotKey `SetAlpha(0)`, never `Hide`.
  - "skin change relayouts": switching profile.skin from classic to gilded and calling `relayoutAll` → 6 edge rects and 4 studs shown on the existing front.
  - "glow show / hide": `show` plays the animation group and sets the spell alert to alpha 0; `hide` stops and hides.
  - "no field written on Blizzard frames".
- [ ] **Step 2: Run** the tests. Expected: FAIL.
- [ ] **Step 3: Implement** `Skin/Glow.lua`, then `Skin/Button.lua`. Add both to the `.toc` after `Skin/Blizzard.lua`.
- [ ] **Step 4: Run** the tests and luacheck. Expected: pass.
- [ ] **Step 5: Commit** `feat: approved button skin on Blizzard buttons`.

### Task 4: Pet autocast badge (`Skin/Autocast.lua`)

**Files:**
- Create: `AnotherBars/Skin/Autocast.lua`, `AnotherBars/Media/Shapes/Disc.tga` (copied from `D:\GitRepos\AnotherHUD\AnotherHUD\Media\Units\Disc.tga`), `tests/test_autocast.lua`
- Modify: `.toc`, `AnotherBars/Core/Theme.lua` (`textures.disc` points at the copy)

**Interfaces:**
- Consumes: `Blizzard.onPetUpdate`, `Blizzard.regions(...).autocast`, `Look.edges`.
- Produces: `Autocast.attach(button, front)`: an 11 px badge at the icon's top-left inside corner. It is a disc stack in the skin's ring shades (AnotherHUD `Ring.lua`: disc i has diameter 11 − 2i), with a `panelTint` disc on top and a 4 px gold dot with a goldLine glow that breathes (alpha 0.7↔1, 1.4 s). `Autocast.set(button, allowed, enabled)`: no badge when `allowed` is false, an empty badge when allowed but off, and the dot when on; plain nil (secret) → leave unchanged. Blizzard's autocast regions are set to alpha 0.

- [ ] **Step 1: Write the failing tests:** `set(b, false, false)` hides the badge; `set(b, true, false)` shows the badge without the dot; `set(b, true, true)` shows the dot and plays the breathe group; with secret values nothing changes; the disc count for Gilded equals `#Theme.edgeRects("gilded")` plus the fill.
- [ ] **Step 2: Run** the tests. Expected: FAIL.
- [ ] **Step 3: Implement** it and copy the texture with `cp` (binary).
- [ ] **Step 4: Run** the tests and luacheck. Expected: pass.
- [ ] **Step 5: Commit** `feat: pet autocast badge`.

### Task 5: Bar modules with Look and Text settings (replaces the spike)

**Files:**
- Create: `AnotherBars/Bars/Common.lua`, `AnotherBars/Bars/ActionBar.lua`, `AnotherBars/Bars/Stance.lua`, `AnotherBars/Bars/Pet.lua`, `tests/test_barmodules.lua`
- Delete: `AnotherBars/Spike/Spike.lua`, `tests/test_spike.lua`
- Modify: `AnotherBars/Core/Core.lua` (create loop; drop the spike), `.toc`, `Locales/deDE.lua`

**Interfaces:**
- Consumes: `Button.skin`, `Autocast.attach`, `ns.Bars.get(id)`.
- Produces:
  - `Common.define(barId)`: one `ns.Modules.define{ id, label, kind = "bar", system = { index }, blizzard = { frame }, defaults, settings, create, apply }`.
  - Settings:
    - **Look**: `shading` dropdown, values `{ "Skin", "Bronze", "Raised", "Flat" }`, default "Skin", label "Button shading", tooltip "Inner shading of the buttons; Skin follows the skin's pick".
    - **Text**: `hotkey` checkbox "Show hotkey" (default true), `macro` checkbox "Show macro name" (default true), `count` checkbox "Show count" (default true), `fontSize` slider "Font size" (6-16, step 1, default 10). Each has a short tooltip.
  - `create(spec)` skins every existing button `1..count` and sets `spec.frame`. `apply(spec, key, value)` re-skins the bar's buttons with the new opts.
  - ActionBar.lua calls `Common.define` for bar1-bar8. Stance.lua does stance. Pet.lua does pet, and its create also calls `Autocast.attach` and wires `Blizzard.onPetUpdate` to `Autocast.set`.
  - `Core.init` creates, for each enabled module with `create`: `ns.Combat.after("create:" .. id, function() spec.create(spec) end)`.
- German, all ≤24 characters: "Button shading" = "Schattierung", "Skin" = "Skin", "Bronze" = "Bronze", "Raised" = "Erhaben", "Flat" = "Flach", "Show hotkey" = "Tastenkürzel zeigen", "Show macro name" = "Makroname zeigen", "Show count" = "Anzahl zeigen", "Font size" = "Schriftgröße", plus the tooltips.

- [ ] **Step 1: Write the failing tests:** ten modules in Bars order, each with the Look and Text sections and the defaults above; no label longer than 24 characters (`Options.longLabels`, English and German); `create` calls `Button.skin` for each existing button with the defaults; `Options.set("bar2", "hotkey", false)` re-skins bar2 only; a disabled module is not created by `Core.init`; the pet create attaches a badge to each pet button.
- [ ] **Step 2: Run** the tests. Expected: FAIL.
- [ ] **Step 3: Implement** the files, delete the spike, update the `.toc` (Bars/* after Skin/*, Spike gone) and the German texts.
- [ ] **Step 4: Run** the tests and luacheck. Expected: pass; `test_toc.lua` agrees with the files.
- [ ] **Step 5: Commit** `feat: bar modules with Look and Text settings`.

### Task 6: Settings window (skin, bars on / off)

**Files:**
- Create: `AnotherBars/UI/Settings.lua`, `tests/test_settings.lua`
- Modify: `AnotherBars/Core/Core.lua` (`/abars` opens it, `/abars version`), `AnotherBars/EditMode/System.lua` (a "Settings" button per bar panel via `AddSystemSettingsButtons`), `AnotherBars/Core/DB.lua` (profile field `skin`, default "classic"), `.toc`, `.luacheckrc` (`Settings`), `Locales/deDE.lua`

**Interfaces:**
- Consumes: `Modules.setEnabled`, `Look.skin`, `Button.relayoutAll`.
- Produces:
  - `UI.Settings.register()`: one `Settings.RegisterVerticalLayoutCategory("AnotherBars")` with a proxy setting "Skin" (dropdown Classic / Forge / Slate / Gilded, via `Settings.RegisterProxySetting` + `Settings.CreateDropdown`). Picking a skin stores `profile.skin` and calls `Combat.after("relayout", Button.relayoutAll)`. Each of the ten bars gets a proxy checkbox labelled with the bar's name: on → `spec.create`; off → `Modules.setEnabled` and, when it returns true, the chat line "Type /reload to apply". All names are UNVERIFIED on Forever.
  - `UI.Settings.open()`: `Settings.OpenToCategory(category:GetID())`.
  - Pure part (tested): `UI.Settings.skinChoices() -> { { value = "classic", label = "Classic" }, ... }` in `Theme.skinOrder`, and `UI.Settings.toggle(id, on) -> needsReload`.
- German: "Skin", "Border and decoration style of all bars" = "Rahmen und Verzierung aller Leisten", "Settings" = "Einstellungen", "Turns this bar's look on or off" = "Schaltet das Aussehen dieser Leiste ein oder aus".

- [ ] **Step 1: Write the failing tests:** `skinChoices` follows `skinOrder`; `toggle("bar3", false)` after create returns true and stores `enabled = false`; `toggle("bar3", true)` on a disabled bar calls create; `/abars version` prints the version and `/abars` calls `open`; the DB default `skin` is "classic"; `System.attachAll` adds one Settings button per enabled bar (fake lib records `AddSystemSettingsButtons`).
- [ ] **Step 2: Run** the tests. Expected: FAIL.
- [ ] **Step 3: Implement** it. Call `register()` from `Core.init` when `Settings` exists.
- [ ] **Step 4: Run** the tests and luacheck. Expected: pass.
- [ ] **Step 5: Commit** `feat: Settings window with skin and bars on / off`.

### Task 7: Docs and client checks

**Files:**
- Modify: `README.md` (player guide: the look, the Edit Mode Look / Text settings, the Settings window, `/abars`; no texture paths, API names or pixel sizes), `docs/DEVELOPMENT.md` (layout table for every new file, the overlay levels, hook list, the `Util.plain` rule, spike removed), `docs/CHECKLIST.md` (a "Plan 3 skin" section, below), `CHANGELOG.md` (one bullet per visible change), `CLAUDE.md` (status: Plan 3 built, waiting for the client check; next Plan 4).

CHECKLIST "Plan 3 skin" lines (each one names what to compare against the mockup page):
- Every UNVERIFIED name from `Skin/Blizzard.lua` exists (`/dump ActionButton1.HotKey ~= nil`, `ActionButtonSpellAlertManager`, `ActionButton_UpdateRangeIndicator`, `PetActionButton1.AutoCastOverlay`, `issecretvalue`, `Settings.RegisterProxySetting`).
- All four skins on Action Bar 1 match `4-buttons.html`: edge, shading, the icon crop, and Classic's round edge at its small size.
- The states match: hover, pressed (mouse and keybind), active (auto attack, a stance), out of range (icon and hotkey red), no mana, unusable, cooldown swipe and time in gold, empty slot while dragging a spell.
- The proc glow pulses as on the mockup, and Blizzard's spell alert is gone.
- Texts: the hotkey, count and macro name toggles and the font size work per bar, and keep their state after `/reload`.
- Pet bar: the badge as on `7-pet.html` (on, off, none), and right-click toggles it.
- Stance Bar: the active stance shows the gold edge, and switching stance in combat changes it.
- The back fill draws under the icon (frame level − 1).
- No Lua errors in combat (secret values), and no `AnotherBars` lines in the taint log after a fight with every bar used.
- The Settings window: skin change applies live; turning a bar off asks for /reload and Blizzard's look is back after it; the Settings button on a bar's Edit Mode panel opens the window.

- [ ] **Step 1:** Write the docs.
- [ ] **Step 2:** Run `lua tests/run.lua` and `luacheck AnotherBars`. Expected: all pass, 0 warnings.
- [ ] **Step 3:** Commit `docs: Plan 3 button skin`, then open a PR (no merge until the player says so).
