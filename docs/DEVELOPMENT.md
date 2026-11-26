# AnotherBars development

Status: Plan 1 (foundation and client spike) in progress. The design and its
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
| `Core/Grid.lua` | pure padding math: Blizzard's rows / columns from button offsets, new offsets for our padding |
| `Core/Layout.lua` | client glue: hook after Blizzard lays out a bar, re-anchor its buttons with our padding (out of combat) |
| `EditMode/Panel.lua` | pure: a module's `settings` -> LibEditMode setting rows (from AnotherHUD) |
| `EditMode/System.lua` | adds each bar module's settings to Blizzard's own bar panel (`AddSystemSettings`) |
| `Core/Core.lua` | start-up and the `/abars` slash command |
| `Boot.lua` | starts the addon on `ADDON_LOADED` |
