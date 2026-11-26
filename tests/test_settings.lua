local h = ...
local fakes = dofile("tests/fakes.lua")

local FILES = { "Core/Util.lua", "Core/Theme.lua", "Core/DB.lua", "Core/Modules.lua", "Core/Combat.lua",
  "Core/Options.lua", "Core/Bars.lua", "Core/Look.lua", "Skin/Blizzard.lua", "Skin/Draw.lua",
  "Skin/Glow.lua", "Skin/Button.lua", "Skin/Autocast.lua",
  "Bars/Common.lua", "Bars/ActionBar.lua", "Bars/Stance.lua", "Bars/Pet.lua",
  "EditMode/Panel.lua", "EditMode/System.lua", "UI/Settings.lua", "Core/Core.lua" }

local function load()
  local ns = h.load(FILES)
  ns.db, ns.chardb = ns.DB.init(nil, nil)
  return ns
end

h.test("skin choices follow the skin order", function()
  local ns = load()
  h.eq(ns.UI.Settings.skinChoices(), {
    { value = "classic", label = "Classic" }, { value = "forge", label = "Forge" },
    { value = "slate", label = "Slate" } })
end)

h.test("a new profile uses Classic", function()
  local ns = load()
  h.eq(ns.DB.profile().skin, "classic")
end)

h.test("picking a skin stores it and relayouts", function()
  local ns = load()
  local n = 0
  ns.Skin.Button.relayoutAll = function() n = n + 1 end
  ns.Skin.Autocast.relayoutAll = function() n = n + 10 end
  ns.UI.Settings.setSkin("slate")
  h.eq(ns.DB.profile().skin, "slate")
  h.eq(n, 11)
  h.eq(ns.UI.Settings.setSkin("nope"), false)
  h.eq(ns.DB.profile().skin, "slate")
end)

h.test("turning a skinned bar off needs a reload", function()
  local ns = load()
  local spec = ns.Modules.get("bar3")
  spec.frame = true
  h.eq(ns.UI.Settings.toggle("bar3", false), true)
  h.eq(ns.DB.profile().modules.bar3.enabled, false)
end)

h.test("turning a bar on creates it now", function()
  local ns = load()
  ns.Modules.setEnabled("bar3", false)
  local created = 0
  ns.Modules.get("bar3").create = function() created = created + 1 end
  h.eq(ns.UI.Settings.toggle("bar3", true), false)
  h.eq(created, 1)
  h.eq(ns.Modules.isEnabled("bar3"), true)
end)

h.test("/abars opens the window, /abars version prints", function()
  local ns = load()
  local opened, said = 0, {}
  ns.UI.Settings.open = function() opened = opened + 1 end
  ns.Util.say = function(m) said[#said + 1] = m end
  ns.Core.slash("")
  h.eq(opened, 1)
  ns.Core.slash("version")
  h.eq(said, { "version dev" })
end)

h.test("each bar panel gets a Settings button", function()
  local ns = load()
  local calls = {}
  local lem = { SettingType = { Dropdown = 0, Checkbox = 1, Slider = 2, Divider = "d" } }
  function lem:AddSystemSettings() end
  function lem:AddSystemSettingsButtons(system, buttons, index)
    calls[#calls + 1] = { system, buttons[1].text, index, type(buttons[1].click) }
  end
  fakes.withGlobals({
    LibStub = { GetLibrary = function(_, name) if name == "LibEditMode" then return lem end end },
    Enum = { EditModeSystem = { ActionBar = 0 }, EditModeActionBarSystemIndices = { MainBar = 1, Bar2 = 2 } },
  }, function() ns.EditMode.System.attachAll() end)
  h.eq(calls, { { 0, "Settings", 1, "function" }, { 0, "Settings", 2, "function" } })
end)
