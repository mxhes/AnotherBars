# AnotherBars

WoW **Forever** (retail engine, Interface 16001) addon in Lua 5.1: Blizzard's Action Bars 1-8, Stance Bar and Pet Bar re-skinned in the suite's look (approved button art, gold pulse proc glow), Blizzard's bar artwork hidden, own padding down to 0, settings in each bar's own **Edit Mode** panel; plus an own totem bar. Blizzard keeps all secure logic (clicks, paging, cooldowns, procs, keybinds, placement). Part of the player's own UI suite with **AnotherLedger** (`D:\GitRepos\LootLedger`), **AnotherHUD** (`D:\GitRepos\AnotherHUD`: unit frames, class resource bar, XP / Reputation; it does not touch action bars) and a minimap addon (not built yet). The addon folder is `AnotherBars/` inside the repo.

**Status:** design approved (`docs/superpowers/specs/2026-11-26-anotherbars-design.md`); Plan 1 done and checked in the client (results in `docs/CHECKLIST.md`: Stance Bar re-lays out in combat, so its own padding starts off); Plan 2 mockups approved; Plan 3 (button skin, `docs/superpowers/plans/2026-11-26-button-skin.md`) built and checked in the client, except the proc glow: Forever never signals procs (`docs/CHECKLIST.md`, "Plan 3 skin"). Plan 3b (proc glow from our own reactive spell list, `docs/superpowers/plans/2026-11-26-reactive-procs.md`) built, waiting for the player's client check (`docs/CHECKLIST.md`, "Plan 3b proc glow"). Next: Plan 4 (padding and artwork hiding).

Docs (created in Plan 1, same layout as AnotherHUD):
- `README.md`: player guide (keep it free of texture paths, API names and pixel sizes).
- `docs/DEVELOPMENT.md`: code layout, module registry, Edit Mode glue, secret values, taint rules, saved state, packaging.
- `docs/CHECKLIST.md`: what still has to be confirmed in the client, and release steps.
- `docs/BACKLOG.md`: ideas not built yet.
- `docs/superpowers/`: design specs and plans per feature (history, not kept in sync).

## Working with the player

- **Artwork: mockups first.** Any new or changed art (button skins, borders, colors, icons, glows) is shown as a mockup and built only after the player approves it. Wait for the answer; don't build "in the meantime". Approved so far (`docs/mockups/APPROVED.md`): buttons and proc glow (§4), totem bar (§5), padding 0 as one bar frame with the first button fixed (§6), pet autocast badge (§7).
- **Ask questions.** When a request leaves something open that changes what gets built, ask (one question at a time, with your recommendation) instead of guessing.
- **Other addons are not a source or an inspiration.** Only the player's own addons (AnotherLedger, AnotherHUD) may be copied and adapted: `Theme.lua`, fonts, skins, widgets, test harness, `.luacheckrc`, `.pkgmeta`, CI, Edit Mode glue, docs layout. Other installed addons may be read for basic client facts only (how a hook or API call works, whether an API exists), never for design, features, code or art.
- **Merge only when the player says so.**
- Never put tokens or passwords in files, commits or chat.

## Commands

- Tests: `lua tests/run.lua` from the repo root (plain Lua, no client; exit 1 on failure). Run after every change; all must pass. Local `lua` is 5.4; GitHub Actions also runs 5.1, so write 5.1 code (no `goto`, `//`, `table.unpack`, integer-only APIs).
- Lint: `luacheck AnotherBars` (`.luacheckrc`; CI fails on any warning). A WoW API the code starts to read goes in its `read_globals`.
- No build step: the client loads files in `.toc` order. Without `Libs/` (packager-fetched, git-ignored) everything but the Edit Mode part works. LibEditMode is used unmodified as a packager external.
- Remote: GitHub `origin` (https://github.com/mxhes/AnotherBars, public), branch `main`; changes go in through pull requests (`gh`, at `C:\Program Files\GitHub CLI`). GitHub only: never GitLab or `glab`. Commits are `feat:` / `fix:` / `refactor:` / `docs:` style, one-line summary plus a short body. Local `user.email` is the GitHub noreply address.
- Release: BigWigs packager on `v*` tags in CI, CurseForge upload with the `CF_API_KEY` repository secret once `## X-Curse-Project-ID` is in the `.toc`.

## Architecture (planned; details in the spec and `docs/DEVELOPMENT.md`)

- **Re-skin, not own buttons.** Each Blizzard button gets an overlay frame of ours (border, shading, states, proc glow); Blizzard's own border / highlight / glow textures go to alpha 0. Per-button data lives in our own table keyed by button, never as fields on the button.
- **Modules.** Each bar is one `ns.Modules.define{...}`; its `settings` list feeds both the Edit Mode panel (`LibEditMode:AddSystemSettings` on Blizzard's bar panels, `AddFrame` for the totem bar) and the Settings window.
- **Padding** is re-applied after Blizzard lays out a bar (`hooksecurefunc`), out of combat only; the first button stays put. Fallback if the spike fails: see the spec's Layout section.
- **Pure vs client code** as in AnotherHUD: files in `Core/` are plain Lua and tested with `h.load`; client calls only inside functions, never at file load.
- **Look** lives in `Core/Theme.lua` (copied from AnotherHUD); change it there, not in UI files.

## Conventions and gotchas

- **Secret values**: never do arithmetic, comparisons or `tostring` math on cooldown, charge, count or totem time values from the client; pass them to widgets (`SetCooldown`, `SetText`, curve / duration APIs). Tests use fakes that throw on arithmetic.
- **Combat lockdown**: nothing that touches a secure frame (create, show / hide, anchor, size, attributes) runs in combat; queue it with `ns.Combat.after(fn)` until `PLAYER_REGEN_ENABLED`. Look and layout never change in combat.
- **Taint**: never write to Blizzard tables (no fields on Blizzard frames, no replacing Blizzard functions, never Blizzard's padding value); use `hooksecurefunc` and own frames. Hide Blizzard art by alpha 0 or reparenting to a hidden frame, out of combat.
- **Forever** has no Death Knights, Demon Hunters or Monks: features for them can't be checked in the client.
- **Options**: a default in the module's `defaults`, a short `label` (24 characters at most) and a `tooltip`. Read with `Options.get`.
- **Texts** go through `ns.L` (English text as key); add the German text to `Locales/deDE.lua`.
- An unconfirmed client API gets an `UNVERIFIED (check in client)` comment and a line in `docs/CHECKLIST.md`; say in your report it was not run in the client.
- New `.lua` file: add it to the `.toc` and the layout table in `docs/DEVELOPMENT.md`.
- Update the docs in the same change: player-visible behavior in `README.md`, internals in `docs/DEVELOPMENT.md`, client checks in `docs/CHECKLIST.md`. Changelog entries are short (one bullet per player-visible change).
- **Editing on Windows:** edit Lua with the Write / Edit tools; heredocs and `sed` strip backslashes (`Interface\\AddOns\\...`). For scripted multi-file edits write a Python file and run it.
