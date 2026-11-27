local ADDON, ns = ...

-- Our settings on Blizzard's own action bar panels in Edit Mode: one
-- LibEditMode:AddSystemSettings call per enabled bar module (spec.system),
-- plus a Settings button that opens our Settings window.
-- Settings are per profile, so the layout name LibEditMode passes is ignored
-- (EditMode/Panel.lua). Client calls only inside functions.
ns.EditMode = ns.EditMode or {}
local System = {}

-- LibEditMode or nil. The real LibStub is a callable table: look the library
-- up through GetLibrary (as AnotherHUD's EditMode/Glue.lua does).
function System.lib()
  local stub = LibStub
  if type(stub) ~= "table" or type(stub.GetLibrary) ~= "function" then return nil end
  return (stub:GetLibrary("LibEditMode", true))
end

-- UNVERIFIED (check in client): Enum.EditModeSystem.ActionBar and the keys of
-- Enum.EditModeActionBarSystemIndices on Forever (docs/CHECKLIST.md).
local callbacksSet = false

-- Every bar shows fully while Edit Mode is open (Skin/Fade.lua).
-- UNVERIFIED (check in client): LibEditMode's enter / exit callbacks fire
-- on Forever.
local function watchEditMode(lem)
  if callbacksSet or type(lem.RegisterCallback) ~= "function" then return end
  callbacksSet = true
  local function set(on)
    if ns.Skin and ns.Skin.Fade then ns.Skin.Fade.setEditMode(on) end
  end
  lem:RegisterCallback("enter", function() set(true) end)
  lem:RegisterCallback("exit", function() set(false) end)
end

function System.attachAll()
  local lem = System.lib()
  if not lem then return end
  watchEditMode(lem)
  local enum = Enum
  local system = enum and enum.EditModeSystem and enum.EditModeSystem.ActionBar
  local indices = enum and enum.EditModeActionBarSystemIndices
  if system == nil or type(indices) ~= "table" then return end
  for _, spec in ipairs(ns.Modules.list()) do
    local index = spec.system and indices[spec.system.index]
    if index ~= nil and ns.Modules.isEnabled(spec.id) then
      lem:AddSystemSettings(system, ns.EditMode.Panel.build(spec, lem.SettingType), index)
      if type(lem.AddSystemSettingsButtons) == "function" then
        lem:AddSystemSettingsButtons(system, { { text = ns.L["Settings"], click = function()
          if ns.UI and ns.UI.Settings then ns.UI.Settings.open() end
        end } }, index)
      end
    end
  end
end

ns.EditMode.System = System
