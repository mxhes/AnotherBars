# AnotherBars client checklist

What still has to be confirmed in the client, and the release steps.

## Open checks

### Plan 1 spike

Setup first: `docs/DEVELOPMENT.md` ("Spike check"). Results go under
"Results" below (date, pass / fail, what was seen). The spike build adds one
"Spike: padding 0" checkbox to each Blizzard bar's Edit Mode panel and a chat
line each time Blizzard lays out a bar.

- [ ] Library loaded: `/dump LibStub and LibStub("LibEditMode", true) ~= nil` prints `true`.
- [ ] `/dump Enum.EditModeActionBarSystemIndices` has the keys `Core/Bars.lua`
  uses (MainBar, Bar2, Bar3, RightBar1, RightBar2, ExtraBar1-3, StanceBar,
  PetActionBar); each bar frame exists (`/dump MultiBar5 ~= nil`, `StanceBar`,
  `PetActionBar`, ...); `/dump MainMenuBar.UpdateGridLayout ~= nil` prints `true`.
- [ ] `/abars` prints the version (`C_AddOns.GetAddOnMetadata`).
- [ ] "Spike: padding 0" shows in each of the ten Blizzard bar panels. Turning
  it on closes the gaps on that bar; button 1 does not move; Rows 2 and 3 and
  "# of Icons" 6 keep the bar's shape.
- [ ] After leaving Edit Mode, `/reload`, and changing Icon Size and Padding in
  Blizzard's panel, our padding comes back after each change, and the gaps are
  right at Icon Size 50% and 200% (buttons share one scale).
- [ ] **Re-layout in combat:** with the chat log on, fight a target dummy as a
  Warrior (stance changes) and a Druid (form changes), as a pet class (summon /
  dismiss the pet) and in a vehicle if one is at hand. Write down every
  "laid out (in combat: yes)" line and its bar.
- [ ] **Taint:** `/console taintLog 1`, `/reload`; padding 0 on all bars;
  fight a dummy casting from every bar, change stance / form, open the
  spellbook and talents in combat. No "Interface action failed" / blocked
  message, and `_forever_\Logs\taint.log` has no `AnotherBars` lines.
- [ ] **Fading:** `/abars spike alpha` in combat: the chat says "ok", Action
  Bar 2 goes to half opacity and its buttons still work; again sets it back.
  "ok" alone does not prove it: a blocked action is reported, not raised, so
  this also needs no "Interface action failed" / blocked message and no
  `AnotherBars` lines in the taint log for this step.
- [ ] **Empty slots:** with "Always Show Buttons" off and padding 0 on, a bar
  with an empty slot in the middle keeps the buttons after it in their
  columns. Then drag a spell (the empty slots show): note whether the empty
  slots appear at Blizzard's spacing and overlap ours (the spike re-anchors
  shown buttons only; Plan 4 decides how hidden ones are placed).

What the results decide (spec, Layout fallback): a bar that re-lays out in
nearly every fight gets "Own padding" off by default in Plan 4; AnotherBars
lines in the taint log from re-anchoring drop padding from release 1.

Results:

- (not run yet)

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
