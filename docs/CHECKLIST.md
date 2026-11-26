# AnotherBars client checklist

What still has to be confirmed in the client, and the release steps.

## Open checks

### Plan 3b proc glow

- [x] Every listed spell's name resolves: `/dump C_Spell.GetSpellName(7384)`
  (Overpower), 6572 (Revenge), 5308 (Execute), 14251 (Riposte), 19306
  (Counterattack), 1495 (Mongoose Bite), 24275 (Hammer of Wrath).
- [x] `/dump C_Spell.GetSpellCooldown(7384)` has `isActive` and `isOnGCD`
  fields, and they are readable in combat (not secret).
- [x] The glow does not blink off during the global cooldown (spam Execute
  below 20%), but does go off while Revenge is on its own cooldown.
- [x] Warrior: Overpower glows after the target dodges and stops on use / while
  on cooldown; Revenge after a block, dodge or parry; Execute below 20%
  target health. Paladin: Hammer of Wrath below 20%. A macro with the spell
  glows too.
- [x] No Lua errors in combat.

Results:

- 2026-11-26: every item passes in the client (spell names resolve,
  `isActive` / `isOnGCD` readable, glows and stops as listed, no Lua errors).


### Plan 3 skin

Copy the addon into the game folder, `/reload`, and compare with the mockup
pages in `docs/mockups/` (served from that folder). Results under
"Results" at the end of this section.

- [x] The names in `Skin/Blizzard.lua` exist: `/dump ActionButton1.HotKey ~= nil`,
  `/dump ActionButtonSpellAlertManager ~= nil` (or `ActionButton_ShowOverlayGlow`),
  `/dump ActionButton_UpdateRangeIndicator ~= nil`,
  `/dump PetActionButton1.AutoCastOverlay ~= nil` (or `AutoCastable`),
  `/dump issecretvalue ~= nil`, `/dump Settings.RegisterProxySetting ~= nil`.
- [x] All four skins (Settings window) on Action Bar 1 look like `4-buttons.html`:
  edge, shading, icon crop; Classic's round edge at button size; Gilded studs.
- [x] The back fill draws under the icon (our frame one level below the button),
  and Blizzard's slot art (`SlotBackground`, `SlotArt`) is gone.
- [x] Summoning a pet and changing stance update the pet / stance buttons
  (`PetActionBar:Update`, `StanceBar:UpdateState`): no empty look over a filled slot.
- [x] States as on the mockup: hover, pressed (mouse and keybind), active
  (auto attack, a stance), out of range (icon red, hotkey red), no mana,
  unusable, cooldown swipe and gold time, empty slot while dragging a spell.
- [ ] The proc glow: moved to the next plan (see Results).
- [x] Texts: hotkey, macro name and count on / off and the font size work per
  bar and stay after `/reload`.
- [x] Pet bar: the badge as on `7-pet.html` (on, off, none); right-click on
  an ability switches it.
- [x] Stance Bar: the active stance has the gold edge; switching stance in
  combat moves it.
- [x] No Lua errors in combat (secret values) and no `AnotherBars` lines in the
  taint log after a fight using every bar (`/console taintLog 1`).
- [x] Settings window: `/abars` and the Edit Mode Settings button open it; a
  skin change applies at once; turning a bar off asks for `/reload` and
  Blizzard's look is back after it; turning it on skins it at once.

Results:

- 2026-11-26: everything passes except the proc glow. Our glow draws (shown
  by hand with `/abars glow`), but no proc ever reaches it: on Forever the
  game shows no proc alert at all (Blizzard's glow didn't show either), and
  neither the alert functions nor the proc events fire. Procs here are spells
  that turn usable for a while (Overpower, Revenge, Execute, ...) or buffs
  that make a spell free or instant; the game does not signal them.
- Decision (player, 2026-11-26): our own short list of reactive spells per
  class, glowing while usable and off cooldown, as the next plan; buff procs
  later (BACKLOG). The alert hooks and proc events stay as extra sources.


### Plan 1 spike

Setup first: `docs/DEVELOPMENT.md` ("Spike check"). Results go under
"Results" below (date, pass / fail, what was seen). The spike build adds one
"Spike: padding 0" checkbox to each Blizzard bar's Edit Mode panel and a chat
line each time Blizzard lays out a bar.

- [x] Library loaded: `/dump LibStub and LibStub("LibEditMode", true) ~= nil` prints `true`.
- [x] `/dump Enum.EditModeActionBarSystemIndices` has the keys `Core/Bars.lua`
  uses (MainBar, Bar2, Bar3, RightBar1, RightBar2, ExtraBar1-3, StanceBar,
  PetActionBar); each bar frame exists (`/dump MultiBar5 ~= nil`, `StanceBar`,
  `PetActionBar`, ...); `/dump MainMenuBar.UpdateGridLayout ~= nil` prints `true`.
- [x] `/abars` prints the version (`C_AddOns.GetAddOnMetadata`).
- [x] "Spike: padding 0" shows in each of the ten Blizzard bar panels. Turning
  it on closes the gaps on that bar; button 1 does not move; Rows 2 and 3 and
  "# of Icons" 6 keep the bar's shape.
- [x] After leaving Edit Mode, `/reload`, and changing Icon Size and Padding in
  Blizzard's panel, our padding comes back after each change, and the gaps are
  right at Icon Size 50% and 200% (buttons share one scale).
- [x] **Main bar after /reload:** padding 0 on for Action Bar 1, `/reload`
  twice: the bar stays in order (buttons 1-12 left to right, as Blizzard has
  them) and closed up. Blizzard moves the main bar's button containers after
  addon load, so the spike repacks only once the Edit Mode layout is in and
  keeps each button on its own container anchor.
- [x] **Re-layout in combat:** with the chat log on, fight a target dummy as a
  Warrior (stance changes) and a Druid (form changes), as a pet class (summon /
  dismiss the pet) and in a vehicle if one is at hand. Write down every
  "laid out (in combat: yes)" line and its bar.
- [x] **Taint:** `/console taintLog 1`, `/reload`; padding 0 on all bars;
  fight a dummy casting from every bar, change stance / form, open the
  spellbook and talents in combat. No "Interface action failed" / blocked
  message, and `_forever_\Logs\taint.log` has no `AnotherBars` lines.
- [x] **Fading:** `/abars spike alpha` in combat: the chat says "ok", Action
  Bar 2 goes to half opacity and its buttons still work; again sets it back.
  "ok" alone does not prove it: a blocked action is reported, not raised, so
  this also needs no "Interface action failed" / blocked message and no
  `AnotherBars` lines in the taint log for this step.
- [x] **Empty slots:** with "Always Show Buttons" off and padding 0 on, a bar
  with an empty slot in the middle keeps the buttons after it in their
  columns. Then drag a spell (the empty slots show): note whether the empty
  slots appear at Blizzard's spacing and overlap ours (the spike re-anchors
  shown buttons only; Plan 4 decides how hidden ones are placed).

What the results decide (spec, Layout fallback): a bar that re-lays out in
nearly every fight gets "Own padding" off by default in Plan 4; AnotherBars
lines in the taint log from re-anchoring drop padding from release 1.

Results:

- 2026-11-26, all checks pass. Library loads, the ten panels show the
  checkbox, padding 0 closes the gaps with button 1 fixed and survives
  /reload and Blizzard's Icon Size / Padding changes. No taint (no blocked
  actions, no AnotherBars lines in the taint log); SetAlpha in combat works;
  empty slots keep the columns.
- Action Bar 1 came out jumbled after /reload (its buttons sit in containers
  Blizzard moves after addon load); fixed by repacking on each button's own
  anchor after the Edit Mode layout lands (PR #4), then confirmed.
- Re-layout in combat: only the Stance Bar printed "laid out", both in and
  out of combat. Decision for Plan 4: the Stance Bar gets "Own padding" off
  by default; all other bars on. Padding stays in release 1.

## Release steps

1. `main` is green: `lua tests/run.lua` passes locally and the `test` jobs
   (Lua 5.1 and 5.4) and the `lint` job pass in GitHub Actions.
2. The open checks above are done in the client, or knowingly left for a
   later release.
3. `## Interface:` in `AnotherBars/AnotherBars.toc` matches the client
   (`/dump select(4, GetBuildInfo())`, 16001 today).
4. Run the CI workflow by hand on `main` (Actions > CI > Run workflow): the `package-dry-run` job's log lists one
   `AnotherBars/` folder with the `.toc`, the code and `Libs/` (LibStub,
   CallbackHandler-1.0, LibEditMode), and no `docs/`,
   `tests/` or `CLAUDE.md`.
5. Add the version's entry on top of `CHANGELOG.md` (merged into `main`):
   the packager sends it to CurseForge as the release notes. Keep it short
   and precise: one bullet per player-visible change, one or two lines
   each, about ten bullets at most, small fixes together in one "Fixes:"
   bullet; no internals (refactors, tests, caches), no option details or
   reasons (those go in `README.md`).
6. Tag `main` with the version as a maintainer (`git tag -a v0.1.0 -m ...`,
   then `git push origin v0.1.0`). The tag's workflow run gets the repository secret `CF_API_KEY` (the CurseForge API token, set under Settings > Secrets and variables > Actions). The `package` job builds
   the zip (the `.toc` version comes from the tag), uploads it to CurseForge
   (`## X-Curse-Project-ID` in the `.toc`, once the project exists) and keeps it as the run's artifact for 30 days.
7. Check the `package` job log: `CurseForge ID: <project id> [token set]` near the
   top and `Uploading ... Success!` before `Packaging complete.`; then the file
   on CurseForge shows the changelog and the game version (the packager maps
   `## Interface: 16001` to `1.60.1`). Without `[token set]` the upload is
   skipped silently. After adding a missing secret, re-run the tag's workflow run (Actions, the run, Re-run all jobs).
