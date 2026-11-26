# Reactive Proc Glow Implementation Plan (Plan 3b)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The approved gold pulse (APPROVED.md §4) shows on every skinned button holding a reactive spell (Overpower, Revenge, Execute, Riposte, Counterattack, Mongoose Bite, Hammer of Wrath) while that spell is usable and not on cooldown.

**Architecture:** On Forever the game never signals a proc (Plan 3 results in `docs/CHECKLIST.md`). We keep our own short list of reactive spells per class. At start-up the list is turned into spell **names**, so every rank matches. A button glows when its action's spell (or macro spell) has one of those names, `IsUsableAction` says usable, and the spell is not on cooldown. The decision is a pure rule in `Core/Reactive.lua`. `Skin/Procs.lua` gathers the client values on the events that change them. The game's proc events and Blizzard's alert hooks stay as a second source (a button glows when either says so).

**Tech Stack:** Lua 5.1, WoW Forever client API (Interface 16001), plain-Lua tests, luacheck.

**Spec:** `docs/superpowers/specs/2026-11-26-anotherbars-design.md` (Button skin: the "gold pulse proc glow"). The player decided on 2026-11-26 (CHECKLIST, Plan 3 results): our own list of reactive spells per class, glowing while usable and off cooldown. Buff procs are later (BACKLOG).

## Global Constraints

- Lua 5.1, `## Interface: 16001`. The glow art is unchanged (already approved), so no mockup.
- Secret values: action, spell id, name, usable and cooldown values pass `ns.Util.plain` / `Util.plainString` before any branch. No arithmetic or comparison on cooldown numbers: "on cooldown" comes only from a boolean API field (below). When it is unknown, the button glows on usability alone (the cooldown swipe shows anyway).
- Hooks and events only call `Button.setProc` (show / hide our glow), which is allowed in combat.
- Texts through `ns.L`, German in `Locales/deDE.lua`. Each unconfirmed API gets UNVERIFIED and a CHECKLIST line.
- The spell list is our own, from game knowledge. No other addon's lists, code or design.

## Calls made in this plan (the player may overrule)

- **The list** (spell id of rank 1; every rank matches by name): Warrior Overpower 7384, Revenge 6572, Execute 5308; Rogue Riposte 14251; Hunter Counterattack 19306, Mongoose Bite 1495; Paladin Hammer of Wrath 24275. Other classes have no reactive spells.
- **No setting.** The glow is part of the look, like the other states.
- **Cooldown** comes from `C_Spell.GetSpellCooldown(id).isActive` (a boolean, UNVERIFIED on Forever). When the field or API is missing, it is unknown, and the button glows while usable.
- **`/abars glow`** (the Plan 3 diagnostic) is removed.

## Review Focus

1. **A reactive spell in a macro**: the macro button glows like the spell. Test in Task 2.
2. **A secret usable or cooldown value in combat**: no error, and the glow keeps its last state. Test in Task 1 (rule returns nil) and Task 2 (the glow does not change).
3. **Spell moved off / onto a bar during a proc window**: `ACTIONBAR_SLOT_CHANGED` re-checks the slot. Test in Task 2.
4. **A class with no reactive spells** (Mage): no names, no glow, no error. Test in Task 2.
5. **Event proc and reactive state disagree**: the glow shows if either is up, and hides only when both are down. Test in Task 2.

---

### Task 1: The pure rule and the list (`Core/Reactive.lua`)

**Files:**
- Create: `AnotherBars/Core/Reactive.lua`, `tests/test_reactive.lua`
- Modify: `AnotherBars/AnotherBars.toc` (after `Core/Look.lua`)

**Interfaces:**
- Produces:
  - `Reactive.SPELLS = { WARRIOR = { 7384, 6572, 5308 }, ROGUE = { 14251 }, HUNTER = { 19306, 1495 }, PALADIN = { 24275 } }`.
  - `Reactive.idsFor(classToken) -> { ids }`: an empty table for an unknown class or nil.
  - `Reactive.isUp(usable, onCooldown) -> true | false | nil`: usable true and onCooldown not true → true; usable false → false; usable nil → nil (unknown: keep the last state). onCooldown true → false.

- [ ] **Step 1: Write the failing tests.** `idsFor("WARRIOR")` gives the three ids. `idsFor("MAGE")` and `idsFor(nil)` give `{}`. `isUp(true, false)`, `isUp(true, nil)`, `isUp(true, true)`, `isUp(false, false)` and `isUp(nil, false)` give true, true, false, false and nil.
- [ ] **Step 2: Run** `lua tests/run.lua`. Expected: FAIL (Reactive is nil).
- [ ] **Step 3: Implement** `Core/Reactive.lua` and add it to the `.toc`.
- [ ] **Step 4: Run** the tests and `luacheck AnotherBars`. Expected: pass.
- [ ] **Step 5: Commit** `feat: reactive spell list and glow rule`.

### Task 2: Reactive source in `Skin/Procs.lua`

**Files:**
- Modify: `AnotherBars/Skin/Procs.lua`, `tests/test_procs.lua`, `.luacheckrc` (`UnitClass`, `C_Spell`, `IsUsableAction` as needed)

**Interfaces:**
- Consumes: `Reactive.idsFor`, `Reactive.isUp`, `Button.each`, `Button.setProc`, `Procs.spellOf` (exists).
- Produces:
  - `Procs.names`: a set of reactive spell names for the player's class, built in `Procs.start` from `select(2, UnitClass("player"))` and `C_Spell.GetSpellName(id)`, or else `GetSpellInfo(id)` (UNVERIFIED). Names pass `Util.plainString`.
  - `Procs.isReactive(b) -> bool`: the button's spell name (`spellOf` → name) is in `Procs.names`.
  - Per button, `reactiveUp[b]` (our weak table) holds the last known state. `update(b)` sets `Button.setProc(b, eventUp or reactiveUp[b])`, where `eventUp = active[spellOf(b)]` as now. Reactive state = `Reactive.isUp(plain(IsUsableAction(b.action)), cooldown(id))`; nil keeps the last state.
  - `cooldown(id)`: `C_Spell.GetSpellCooldown(id)` → `plain(info.isActive)` when it is a boolean, else nil.
  - Events added to the existing list: `ACTIONBAR_UPDATE_USABLE`, `SPELL_UPDATE_USABLE`, `ACTIONBAR_UPDATE_COOLDOWN`, `SPELL_UPDATE_COOLDOWN`, `PLAYER_TARGET_CHANGED`, plus `UNIT_HEALTH` for `"target"` only (Execute, Hammer of Wrath) and `UPDATE_SHAPESHIFT_FORM` (stances change usability). Each runs `Procs.updateAll()`.

- [ ] **Step 1: Write the failing tests** in `tests/test_procs.lua`, with fakes for `UnitClass` → "WARRIOR", `C_Spell.GetSpellName` (7384 and 7887 → "Overpower", 133 → "Fireball"), `IsUsableAction` and `C_Spell.GetSpellCooldown`:
  - "a reactive spell glows while usable": slot 1 holds spell 7887 (rank 2). Usable → glowing after `ACTIONBAR_UPDATE_USABLE`. Not usable → not glowing.
  - "on cooldown it does not glow": usable with `isActive = true` → not glowing.
  - "unknown cooldown glows on usability": `GetSpellCooldown` returns nil → glowing while usable.
  - "a secret usable keeps the last state": glowing, then usable secret → still glowing, and no error.
  - "a non-reactive spell never glows from usability": slot with 133 usable → not glowing.
  - "a macro casting Overpower glows": `{ "macro", 7384, "spell" }` usable → glowing.
  - "event proc or reactive": a reactive button not usable but its spell id in a `SPELL_ACTIVATION_OVERLAY_GLOW_SHOW` → glowing. After `_HIDE` → not glowing.
  - "a class without reactive spells": `UnitClass` → "MAGE", every button stays dark, no error.
  - The existing Procs tests still pass.
- [ ] **Step 2: Run** the tests. Expected: the new ones FAIL.
- [ ] **Step 3: Implement** it in `Skin/Procs.lua`, and update its header comment (the main path is now the reactive list).
- [ ] **Step 4: Run** the tests and luacheck. Expected: pass.
- [ ] **Step 5: Commit** `feat: proc glow on reactive spells`.

### Task 3: Remove the diagnostic, docs, client checks

**Files:**
- Modify: `AnotherBars/Skin/Button.lua` (remove `Button.alerts`, `glowCheck`), `AnotherBars/Core/Core.lua` (remove the `glow` command), `tests/test_buttons.lua` (remove the glow-check test), `README.md`, `CHANGELOG.md`, `docs/DEVELOPMENT.md`, `docs/CHECKLIST.md`, `CLAUDE.md`

- [ ] **Step 1:** Remove the diagnostic and its test. Run `lua tests/run.lua`. Expected: pass.
- [ ] **Step 2:** Docs:
  - README: "Reactive spells (Overpower, Revenge, Execute, Riposte, Counterattack, Mongoose Bite, Hammer of Wrath) pulse in gold while you can use them." No API names.
  - CHANGELOG: one bullet.
  - DEVELOPMENT: the Proc glow paragraph names the list in `Core/Reactive.lua`, the events and the cooldown rule, plus a layout row for `Core/Reactive.lua`.
  - CHECKLIST, "Plan 3b proc glow":
    - Each listed spell's name resolves (`/dump C_Spell.GetSpellName(7384)` …).
    - `C_Spell.GetSpellCooldown(7384).isActive` exists.
    - Overpower glows after a dodge and stops on use or cooldown.
    - Revenge after a block, dodge or parry.
    - Execute and Hammer of Wrath below 20% target health.
    - A macro with the spell glows.
    - No Lua errors in combat.
  - CLAUDE.md: status says Plan 3b is built, waiting for the client check; next is Plan 4.
- [ ] **Step 3:** Run `lua tests/run.lua` and `luacheck AnotherBars`. Expected: all pass, 0 warnings.
- [ ] **Step 4:** Commit `docs: Plan 3b reactive proc glow`, copy the addon into the game folder, push, and open a PR (no merge until the player says so).
