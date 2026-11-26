local ADDON, ns = ...

-- Start-up, called by Boot.lua on ADDON_LOADED: saved state first, then our
-- settings on Blizzard's bar panels, then every enabled bar module's create
-- (out of combat). Also the /abars slash command.
local Core = {}

-- Subcommands of /abars: Core.commands[name] = function(rest).
Core.commands = {}

-- UNVERIFIED (check in client): C_AddOns.GetAddOnMetadata on Forever.
local function version()
  local addons = C_AddOns
  local v = addons and addons.GetAddOnMetadata and addons.GetAddOnMetadata(ADDON, "Version")
  return type(v) == "string" and v or "dev"
end

function Core.slash(msg)
  local name, rest = tostring(msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
  local fn = Core.commands[name:lower()]
  if fn then return fn(rest) end
  if name == "" and ns.UI and ns.UI.Settings then return ns.UI.Settings.open() end
  ns.Util.say("version " .. version())
end

Core.commands.version = function() ns.Util.say("version " .. version()) end

function Core.init()
  AnotherBarsDB, AnotherBarsCharDB = ns.DB.init(AnotherBarsDB, AnotherBarsCharDB)
  ns.db, ns.chardb = AnotherBarsDB, AnotherBarsCharDB
  SLASH_ANOTHERBARS1, SLASH_ANOTHERBARS2 = "/abars", "/anotherbars"
  SlashCmdList.ANOTHERBARS = Core.slash
  ns.EditMode.System.attachAll()
  if ns.UI and ns.UI.Settings then ns.UI.Settings.register() end
  for _, spec in ipairs(ns.Modules.list()) do
    if spec.create and ns.Modules.isEnabled(spec.id) then
      ns.Combat.after("create:" .. spec.id, function() spec.create(spec) end)
    end
  end
  if ns.Skin and ns.Skin.Procs then ns.Combat.after("procs", function() ns.Skin.Procs.start() end) end
end

ns.Core = Core
