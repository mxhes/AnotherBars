-- luacheck config (https://github.com/lunarmodules/luacheck), run in GitHub Actions
-- (job `lint`) and locally with `luacheck AnotherBars`. It checks the addon
-- code for leaked or misspelled globals, unused variables and overwritten
-- values. A new WoW API the code reads goes in `read_globals`; a global the
-- addon writes goes in `globals`.

std = "lua51"
max_line_length = false
exclude_files = { "AnotherBars/Libs/" }

ignore = {
  "212",      -- unused argument (handlers keep the full event signature)
  "211/ADDON", -- `local ADDON, ns = ...` at the top of every file
  "211/ns",    -- `local ADDON, ns = ...` at the top of every file
  "421",      -- shadowing a local
  "431",      -- shadowing an upvalue
  "432",      -- shadowing an upvalue argument
}

-- Globals the addon sets: its saved variables.
globals = {
  "AnotherBarsDB", "AnotherBarsCharDB",
  -- the /abars slash command
  "SLASH_ANOTHERBARS1", "SLASH_ANOTHERBARS2", "SlashCmdList",
}

-- WoW API the addon reads.
read_globals = {
  "InCombatLockdown", "CreateFrame", "geterrorhandler", "hooksecurefunc",
  "LibStub", "Enum", "C_AddOns", "CreateColor", "GetTime",
  "CreateFont",
}
