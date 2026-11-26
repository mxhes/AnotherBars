# Padding and Artwork Hiding Implementation Plan (Plan 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Each Blizzard bar gets three new Look settings on its Edit Mode panel: "Hide Blizzard art", "Own padding" and "Padding" (0-10 px). Padding 1-10 closes the gaps with the approved per-button look. Padding 0 switches to the approved one-bar-frame look (APPROVED.md §6).

**Architecture:**
- **Pure parts** (tested with `h.load`):
  - `Core/Grid.lua` gains the step at padding 0 and the divider pairs.
  - `Core/Look.lua` gains `framed`.
  - `Core/Art.lua` holds the list of Blizzard art per bar. Like the reactive list, adding a region is one line.
- **Client parts:**
  - `Core/Layout.lua` (exists) gains reset, hidden buttons and event timing.
  - `Skin/Art.lua` hides the listed regions by alpha 0.
  - `Skin/BarFrame.lua` draws the padding-0 bar panel and dividers.
  - `Skin/Button.lua` gains a framed mode.
- **Wiring:** `Bars/Common.lua` wires it all through the module's `create` / `apply`.

**Tech Stack:** Lua 5.1, WoW Forever client API (Interface 16001), plain-Lua tests, luacheck.

**Spec:** `docs/superpowers/specs/2026-11-26-anotherbars-design.md`, sections "Layout", "Artwork" and the Look settings. Spike results and decisions are in `docs/CHECKLIST.md`, "Plan 1 spike":
- The Stance Bar re-lays out in combat, so its "Own padding" is off by default.
- No taint from re-anchoring, so padding ships.
- Action Bar 1 repacks only after the Edit Mode layout is in.

The art comes from `docs/mockups/APPROVED.md` §4 (buttons) and §6 (padding 0, variant C; Gilded is withdrawn).

## Global Constraints

- Lua 5.1, `## Interface: 16001`. Each new `.lua` file goes in the `.toc` and the layout table of `docs/DEVELOPMENT.md`.
- **Taint:** never write to Blizzard tables.
  - No fields on Blizzard frames, no replacing Blizzard functions.
  - Never touch Blizzard's padding value or the bar frame's size.
  - Use `hooksecurefunc` / `HookScript`. Per-button and per-region data live in our own weak tables.
- **Combat:** anchoring buttons, alpha on Blizzard art, and creating or showing our bar frame happen out of combat only, through `ns.Combat.after(key, fn)`.
- **Button 1 never moves.** The other buttons close up toward it along Blizzard's growth direction (spec, Layout).
- **New settings:** each needs a default in `Common.defaults`, a label of at most 24 characters and a tooltip. Texts go through `ns.L`, with German in `Locales/deDE.lua`.
- **Client checks:** every client name not yet confirmed gets `UNVERIFIED (check in client)` and a line in `docs/CHECKLIST.md`.
- **Art:** only the approved art above, nothing new. The Lines pick (gold / groove / plain / dotted) colors the padding-0 dividers through `Theme.lineColors`.

## Calls made in this plan (the player may overrule)

- **Defaults:**
  - "Hide Blizzard art": on for every bar.
  - "Own padding": on for every bar except the Stance Bar.
  - "Padding": 2 px. Blizzard's default is wider, so 2 px matches the spec's "tighter spacing" and keeps the per-button look. 0 is one click away.
- **Stance Bar tooltip:** the Stance Bar's "Own padding" tooltip says why it starts off: "The Stance Bar re-lays out in combat; its gaps return to Blizzard's until combat ends".
- **Turning "Own padding" off** puts every button back on Blizzard's own anchor at once (out of combat); no `/reload` is needed.
- **Hidden empty slots** ("Always Show Buttons" off) are packed too, when their position can be read. When one is shown, for example while dragging a spell, the bar repacks once combat allows.
- **Art list:** Blizzard's art is a data list per bar in `Core/Art.lua`. A name the client doesn't have is skipped. If the player sees art left over, its name is added in one line.
- **Our bar frame** (padding 0) is our own frame, parented to the bar frame so it hides with it. It is anchored by its four edges to the outermost buttons, and the bar frame itself is never sized.

## Review Focus

1. **Own padding turned off after a repack:** every button is back on the exact anchor Blizzard gave it, and button 1 never moved. Test in Task 2.
2. **Blizzard re-lays out in combat (Stance Bar with own padding on):** nothing moves until combat ends, then one repack runs. Test in Task 2.
3. **Padding 0 and back to 2:** the bar frame and dividers hide, and each button gets its own edge, back fill and glow placement again. Tests in Task 4 and Task 5.
4. **A bar whose art names don't exist on Forever:** no error, and the other names are still hidden. Test in Task 3.
5. **"Hide Blizzard art" turned off:** each region gets back the alpha it had before we hid it, not just 1. Test in Task 3.

---

### Task 1: Pure parts: settings, padding step, dividers, art list

**Files:**
- Modify: `AnotherBars/Bars/Common.lua` (settings and defaults only), `AnotherBars/Core/Grid.lua`, `AnotherBars/Core/Look.lua`, `Locales/deDE.lua`
- Create: `AnotherBars/Core/Art.lua` (in the `.toc` after `Core/Bars.lua`), `tests/test_art.lua`
- Test: `tests/test_grid.lua`, `tests/test_look.lua`, `tests/test_barmodules.lua`

**Interfaces:**
- Produces:
  - **Defaults:** `Common.defaults` gains `hideArt = true`, `ownPadding = true`, `padding = 2`.
  - **Look controls, after "Button shading":**
    - `{ key = "hideArt", type = "checkbox", label = "Hide Blizzard art" }`
    - `{ key = "ownPadding", type = "checkbox", label = "Own padding" }`
    - `{ key = "padding", type = "slider", label = "Padding", min = 0, max = 10, step = 1 }`
    - Each has a tooltip. The padding tooltip: "Space between buttons; 0 joins the bar into one frame".
  - **`Common.define(id, extra, overrides)`:**
    - `overrides.defaults` replaces default values.
    - `overrides.tooltips[key]` replaces a tooltip.
    - The Stance Bar passes `{ defaults = { ownPadding = false }, tooltips = { ownPadding = "The Stance Bar re-lays out in combat; its gaps return to Blizzard's until combat ends" } }`.
  - **`Look.framed(ownPadding, padding) -> bool`:** true only when `ownPadding == true and padding == 0`.
  - **`Grid.spacing(padding, edge) -> number`:** the gap passed to `Grid.repack`. It is `padding` when padding > 0, else `1 - 2 * edge`, so the icons sit 1 px apart.
  - **`Grid.dividers(cells) -> { { i, j, axis } }`:**
    - One entry per pair of neighbouring cells: same row with columns 1 apart gives `axis = "v"` (a vertical line); same column with rows 1 apart gives `axis = "h"`.
    - `i` is the cell on the left (or top). Use the signs of `Grid.cells`: up is +y.
  - **`Art.REGIONS`:**
    - `bar1 = { "EndCaps", "BorderArt", "Background" }`; other bars `{}`. These are dot paths under the bar frame, all UNVERIFIED.
    - `Art.POOLS = { bar1 = { "dividerPool" } }`.
    - `Art.regionsFor(barId) -> { paths }` and `Art.poolsFor(barId) -> { keys }` return `{}` for unknown ids.
    - Head comment: "TO ADD A REGION: one dot path under the bar's id".

- [ ] **Step 1: Write the failing tests:**
  - `Grid.spacing(2, 3) == 2`, `Grid.spacing(0, 3) == -5`, `Grid.spacing(0, 2) == -3`.
  - `Grid.dividers` on a 3 x 2 grid (`{0,0},{1,0},{2,0},{0,-1},{1,-1},{2,-1}`) gives 4 `v` and 3 `h` pairs, and `{1,2,"v"}` is among them.
  - `Grid.dividers` on a single button gives `{}`.
  - `Look.framed`: (true, 0) → true; (true, 2) → false; (false, 0) → false.
  - Every module's defaults: `hideArt == true`, `padding == 2`. `ownPadding` is true everywhere except `stance`, where it is false.
  - The stance control's tooltip is the override.
  - Every new label is at most 24 characters.
  - `Art.regionsFor("bar1")` has 3 paths; `Art.regionsFor("nope")` is `{}`; every entry is a non-empty string.
- [ ] **Step 2: Run** `lua tests/run.lua </dev/null`. Expected: the new tests FAIL.
- [ ] **Step 3: Implement** the interfaces above. Add the German texts for the new labels and tooltips.
- [ ] **Step 4: Run** the tests and `luacheck AnotherBars`. Expected: all pass, 0 warnings.
- [ ] **Step 5: Commit** `feat: padding and art settings, padding-0 step, art list`.

### Task 2: Layout: reset, hidden buttons, event timing, wiring

**Files:**
- Modify: `AnotherBars/Core/Layout.lua`, `AnotherBars/Bars/Common.lua`, `AnotherBars/Bars/Stance.lua`
- Test: `tests/test_layout.lua`, `tests/test_barmodules.lua`

**Interfaces:**
- Consumes: `Grid.spacing`, `Grid.repack`, `Look.edgeWidth`, `Options.get`, `Combat.after`.
- Produces:
  - **`Layout.repack(barId, padding)`:**
    - Unchanged, except that it also packs hidden buttons whose `GetLeft` / `GetTop` can be read. Others are skipped.
    - It also records the packed layout for Task 4: `Layout.cells(barId) -> cells, buttons` (the last packed cells and their buttons, in order) and `Layout.edges(barId) -> { left = b, right = b, top = b, bottom = b }` (the outermost packed buttons).
  - **`Layout.reset(barId)`:**
    - Queued with key `"repack:" .. barId`, so it replaces a pending repack.
    - Puts each button we moved back on its stored base anchor and clears our state for it.
  - **`Layout.onShowRepack(barId, fn)`:** HookScript `OnShow` on each of the bar's buttons, once. It calls `fn()`.
  - **`Common.layout(id)`** (module code):
    - When `ownPadding` is on: `Layout.repack(id, Grid.spacing(padding, Look.edgeWidth(Look.skin().border)))`.
    - Otherwise: `Layout.reset(id)`.
    - It runs on create, apply, the `Layout.watch` callback, button show, `PLAYER_ENTERING_WORLD` and `EDIT_MODE_LAYOUTS_UPDATED` (UNVERIFIED on Forever; registered with `pcall`, as the spike did).
    - It also runs on a skin change, because the edge width changes the padding-0 step. `UI/Settings.setSkin` calls `Common.layoutAll()`.

- [ ] **Step 1: Write the failing tests** with the fake main bar in `tests/test_layout.lua`:
  - "reset puts back Blizzard's anchors": repack with 0, then reset. Each button's last `SetPoint` equals its original `{ "CENTER", container, "CENTER", 0, 0 }`, and button 1 has no `SetPoint` at all.
  - "a hidden button with a position is packed": button 2 is hidden (`_shown = false`) but has `_left`. After repack, button 3 sits two steps from button 1.
  - "in combat nothing moves until combat ends": `setCombat(true)`, fire the watch hook. There is no `SetPoint` call. Then `setCombat(false)` and fire `PLAYER_REGEN_ENABLED`: exactly one repack's `SetPoint` calls.
  - "edges name the outermost buttons": after repack of a 3-button row, `left` is button 1, `right` is button 3, and `top` and `bottom` are buttons of the row.
  - **In `tests/test_barmodules.lua`:**
    - "padding 0 uses the edge step": with the Slate skin (edge 2), the bar's buttons are 33 px apart (36 - 4 + 1).
    - "own padding off resets": `Options.set("bar1", "ownPadding", false)` leads to `Layout.reset("bar1")`.
    - "the stance bar starts at Blizzard's padding": no repack on create.
- [ ] **Step 2: Run** the tests. Expected: the new ones FAIL.
- [ ] **Step 3: Implement** the interfaces. One event frame, made in `Common` on the first create, runs `Common.layoutAll()` on the two events.
- [ ] **Step 4: Run** the tests and luacheck. Expected: pass.
- [ ] **Step 5: Commit** `feat: own padding on Blizzard's bars`.

### Task 3: Hide Blizzard's bar art (`Skin/Art.lua`)

**Files:**
- Create: `AnotherBars/Skin/Art.lua` (in the `.toc` after `Skin/Autocast.lua`), `tests/test_skin_art.lua`
- Modify: `AnotherBars/Bars/Common.lua`, `.luacheckrc` if needed

**Interfaces:**
- Consumes: `Art.regionsFor`, `Art.poolsFor`, `Bars.get`, `Combat.after`.
- Produces:
  - **`ns.Skin.Art.apply(barId, hide)`** (called `SkinArt` below), queued with key `"art:" .. barId`:
    - It resolves each dot path from `_G[bar.frame]`. It also resolves every active object of each listed pool (`pool:EnumerateActive()`; UNVERIFIED).
    - Hide: store the object's current `GetAlpha()` in our weak table, the first time only, then call `SetAlpha(0)`.
    - Show: restore the stored alpha and forget it.
    - A missing path or pool is skipped without error.
  - **Wiring in `Common`:** `SkinArt.apply(id, Options.get(id, "hideArt"))` runs on create, on apply, and after every Blizzard layout (dividers come from layout), through the same `Common.layout` path.

- [ ] **Step 1: Write the failing tests** with a fake `MainMenuBar`. It has `EndCaps` at alpha 1, `BorderArt` at alpha 0.6, no `Background`, and a `dividerPool` with two active fake textures.
  - Hide: EndCaps, BorderArt and both dividers are at alpha 0, and the missing Background raises no error.
  - Show: EndCaps is at 1 and BorderArt back at 0.6.
  - Hide twice, then show: BorderArt is at 0.6, not 0.
  - In combat nothing changes until `PLAYER_REGEN_ENABLED`.
  - `bar2`, with an empty list, makes no calls.
- [ ] **Step 2: Run** the tests. Expected: FAIL (no `SkinArt`).
- [ ] **Step 3: Implement** it, with an `UNVERIFIED (check in client)` comment on the region names and on `EnumerateActive`.
- [ ] **Step 4: Run** the tests and luacheck. Expected: pass.
- [ ] **Step 5: Commit** `feat: hide Blizzard's bar art`.

### Task 4: Padding 0: the bar frame (`Skin/BarFrame.lua`)

**Files:**
- Create: `AnotherBars/Skin/BarFrame.lua` (in the `.toc` after `Skin/Art.lua`), `tests/test_barframe.lua`
- Modify: `AnotherBars/Bars/Common.lua`

**Interfaces:**
- Consumes:
  - `Layout.cells(barId)` and `Layout.edges(barId)` (Task 2), `Grid.dividers` (Task 1).
  - `Theme.edgeRects`, `Theme.lineColors`, `Theme.colors.panelTint` / `panelBorder` / `goldLine`, `Theme.textures.skinDotted`.
  - `Look.skin()`, `Look.edgeWidth`, `Draw.*`.
- Produces:
  - **`BarFrame.apply(barId, on)`**, queued with key `"barframe:" .. barId`:
    - Creates our frame once, parented to the bar frame, at frame level `buttonLevel - 2`.
    - Anchors its LEFT / RIGHT / TOP / BOTTOM to the edge buttons from `Layout.edges`.
    - Draws the panel (`panelTint`, full opacity) and the skin border:
      - Classic: the round backdrop with the 5 px corner radius of §6.
      - Other skins: `Theme.edgeRects` lines in `panelBorder` shades.
    - Draws one 1 px divider per `Grid.dividers` pair, in the main color of `Theme.lineColors(skin.lines, goldLine, panelTint)`. Dotted uses `skinDotted`.
      - A `v` line runs from button i's `TOPRIGHT` (-e, -e) to its `BOTTOMRIGHT` (-e + 1, e).
      - An `h` line runs from button i's `BOTTOMLEFT` (e, e - 1) to its `BOTTOMRIGHT` (-e, e).
    - Lines left over from a larger layout are hidden. `on == false` hides the frame.
  - **Wiring in `Common.layout`:** after the repack, `BarFrame.apply(id, Look.framed(ownPadding, padding))` runs, in the same `Combat.after` job order (repack first).

- [ ] **Step 1: Write the failing tests** with a fake 3 x 2 bar (6 buttons, 36 px, Slate edge 2), repacked at padding 0:
  - The frame exists, is shown and is anchored to the four edge buttons.
  - 7 dividers are shown (4 v, 3 h), 1 px wide or high.
  - Slate draws 2 edge rects; Classic sets a backdrop and draws no rects.
  - `apply(id, false)` hides the frame.
  - A 1-row bar shows 2 dividers after a 6-button bar showed 7 (extra lines hidden).
  - Applying twice creates one frame.
- [ ] **Step 2: Run** the tests. Expected: FAIL.
- [ ] **Step 3: Implement** it.
- [ ] **Step 4: Run** the tests and luacheck. Expected: pass.
- [ ] **Step 5: Commit** `feat: padding 0 joins a bar into one frame`.

### Task 5: Padding 0: buttons in framed mode

**Files:**
- Modify: `AnotherBars/Skin/Button.lua`, `AnotherBars/Skin/Glow.lua`, `AnotherBars/Bars/Common.lua` (`Common.opts` adds `framed`)
- Test: `tests/test_buttons.lua` (the glow tests live there too)

**Interfaces:**
- Consumes: `Look.framed`, `Look.edgeWidth`.
- Produces:
  - **`Button.skin(b, opts)`** with `opts.framed == true`:
    - No back fill or backdrop, and no edge rects. The bar frame draws those.
    - The icon, cooldown and shading stay inset by `e` (the same icon size as §4).
    - Hover shows a new 1 px `goldLine` inner edge (`st.hoverEdge`, `Draw.rect` at inset `e`) plus the existing 16% warm overlay.
    - The active edge, `hoverFill`, `pressedFill`, `empty` and `emptyShadow` are placed at inset `e`, inside the icon, so nothing draws over a neighbouring icon.
  - With `framed` false, everything is as today: `hoverEdge` hidden and the overlays at their current insets.
  - **`Glow.place(glow, inset)`:** the glow frame sits around the button inset by `inset`. Framed mode passes `e`, so the glow is 5 px out from the icon; otherwise 0, as today.
  - **`Common.opts(id)`** adds `framed = Look.framed(ownPadding, padding)`.

- [ ] **Step 1: Write the failing tests:**
  - "framed hides fill, backdrop and edges": with Slate, `framed = true`: the fill is hidden, backdrop is nil, 0 rects are shown.
  - "framed hover draws the inner gold edge": `hoverEdge` is shown on enter and hidden on leave. It is never shown when not framed.
  - "framed overlays stay inside the icon": the first `SetPoint` of `hoverFill`, `pressedFill` and `empty` has offsets `(e, -e)`.
  - "framed glow sits around the icon": the glow frame's TOPLEFT offset is `(e, -e)` before Glow's own outset.
  - "back to padding 2 restores the per-button look": skin framed, then unframed. The fill is shown, rects are shown, and `hoverEdge` is hidden.
  - **`Common.opts`:** `framed` is true at (ownPadding on, padding 0) and false at padding 2.
- [ ] **Step 2: Run** the tests. Expected: FAIL.
- [ ] **Step 3: Implement** it.
- [ ] **Step 4: Run** the tests and luacheck. Expected: pass.
- [ ] **Step 5: Commit** `feat: framed buttons at padding 0`.

### Task 6: Docs and client checks

**Files:**
- Modify: `README.md`, `CHANGELOG.md`, `docs/DEVELOPMENT.md`, `docs/CHECKLIST.md`, `docs/BACKLOG.md` (if anything is deferred), `CLAUDE.md`

- [ ] **Step 1: Docs:**
  - **README:** the three Look settings in player words: what padding 0 does, and that the Stance Bar starts with Blizzard's spacing and why. No API names or pixel sizes beyond the setting's own 0-10.
  - **CHANGELOG:** one bullet each for padding and for art hiding.
  - **DEVELOPMENT:**
    - Layout rows for `Core/Art.lua`, `Skin/Art.lua` and `Skin/BarFrame.lua`.
    - A Padding paragraph: spacing at 0, reset, hidden buttons, the two events, and the job order repack → art → bar frame.
    - How to add an art region (one line in `Core/Art.lua`).
  - **CHECKLIST, "Plan 4 padding and art":**
    - The art names resolve: `/dump MainMenuBar.EndCaps ~= nil`, `MainMenuBar.BorderArt`, `MainMenuBar.Background`, `MainMenuBar.dividerPool`.
    - The end caps, background and dividers are gone with "Hide Blizzard art" on, and back when it's off.
    - Padding 2: gaps close and button 1 stays put; this survives `/reload` and Blizzard's Icon Size / Padding.
    - Padding 0 looks like `6-padding.html` in all three skins. **Clicking at the seam between two icons casts the button under the icon** (frames overlap; the approved open point).
    - "Own padding" off brings back Blizzard's spacing without `/reload`.
    - Stance Bar: off by default; turned on, its gaps come back after combat.
    - A hidden empty slot shown by dragging a spell lands in our grid.
    - The Edit Mode selection box may be larger than the bar (acceptable, per the spec).
    - No Lua errors and no `AnotherBars` lines in the taint log.
  - **CLAUDE.md status:** Plan 4 is built and waiting for the client check. Next: Plan 5 (fading).
- [ ] **Step 2: Run** `lua tests/run.lua </dev/null` and `luacheck AnotherBars`. Expected: all pass, 0 warnings.
- [ ] **Step 3: Commit** `docs: Plan 4 padding and art`, copy the addon into the game folder, push, and open a PR (no merge until the player says so).
