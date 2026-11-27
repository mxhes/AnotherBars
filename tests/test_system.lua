local h = ...
local fakes = dofile("tests/fakes.lua")

local TYPES = { Dropdown = 0, Checkbox = 1, Slider = 2, ColorPicker = 10, Divider = "divider" }

-- A fake LibEditMode that records AddSystemSettings calls.
local function fakeLem()
  local lem = { SettingType = TYPES, calls = {} }
  function lem:AddSystemSettings(system, settings, index)
    self.calls[#self.calls + 1] = { system = system, settings = settings, index = index }
  end
  return lem
end

local ENUM = {
  EditModeSystem = { ActionBar = 0 },
  EditModeActionBarSystemIndices = { MainBar = 1, Bar2 = 2, StanceBar = 11 },
}

local function load(lem)
  local globals = { Enum = ENUM }
  if lem then
    globals.LibStub = { GetLibrary = function(_, name) if name == "LibEditMode" then return lem end end }
  else
    globals.LibStub = fakes.NIL
  end
  local ns
  fakes.withGlobals(globals, function()
    ns = h.load({ "Core/Util.lua", "Core/DB.lua", "Core/Modules.lua", "Core/Combat.lua", "Core/Options.lua",
      "EditMode/Panel.lua", "EditMode/System.lua" })
  end)
  ns.db, ns.chardb = ns.DB.init(nil, nil)
  local function bar(id, index)
    ns.Modules.define{ id = id, label = id, kind = "bar", system = { index = index },
      defaults = { on = false },
      settings = { { section = "Look", controls = { { key = "on", type = "checkbox", label = "On" } } } } }
  end
  bar("bar1", "MainBar")
  bar("bar2", "Bar2")
  ns.Modules.define{ id = "misc", label = "Misc", kind = "misc" }
  return ns, globals
end

local function attach(ns, globals)
  fakes.withGlobals(globals, function() ns.EditMode.System.attachAll() end)
end

h.test("one system settings call per bar module", function()
  local lem = fakeLem()
  local ns, g = load(lem)
  attach(ns, g)
  h.eq(#lem.calls, 2)
  h.eq(lem.calls[1].system, 0)
  h.eq(lem.calls[1].settings[1].kind, "divider")
  h.eq(lem.calls[1].settings[2].name, "On")
end)

h.test("uses the bar's system index", function()
  local lem = fakeLem()
  local ns, g = load(lem)
  attach(ns, g)
  h.eq(lem.calls[1].index, 1)
  h.eq(lem.calls[2].index, 2)
end)

h.test("skips disabled modules", function()
  local lem = fakeLem()
  local ns, g = load(lem)
  ns.Modules.setEnabled("bar2", false)
  attach(ns, g)
  h.eq(#lem.calls, 1)
  h.eq(lem.calls[1].index, 1)
end)

h.test("skips a bar whose system index the client lacks", function()
  local lem = fakeLem()
  local ns, g = load(lem)
  ns.Modules.define{ id = "bar9", label = "bar9", kind = "bar", system = { index = "Nope" } }
  attach(ns, g)
  h.eq(#lem.calls, 2)
end)

h.test("works without LibEditMode", function()
  local ns, g = load(nil)
  attach(ns, g)
  h.eq(ns.EditMode.System.lib(), nil)
end)

h.test("slash runs a registered subcommand", function()
  local ns = h.load({ "Core/Util.lua", "Core/DB.lua", "Core/Modules.lua", "Core/Combat.lua", "Core/Options.lua",
    "EditMode/Panel.lua", "EditMode/System.lua", "Core/Core.lua" })
  local got
  ns.Core.commands.spike = function(rest) got = rest end
  ns.Core.slash("spike log")
  h.eq(got, "log")
end)

h.test("slash without a subcommand prints the version", function()
  local ns = h.load({ "Core/Util.lua", "Core/DB.lua", "Core/Modules.lua", "Core/Combat.lua", "Core/Options.lua",
    "EditMode/Panel.lua", "EditMode/System.lua", "Core/Core.lua" })
  local said
  ns.Util.say = function(msg) said = msg end
  ns.Core.slash("")
  h.eq(type(said), "string")
  h.eq(said:find("version", 1, true) ~= nil, true)
end)

h.test("Edit Mode enter / exit drive the fade's Edit Mode state", function()
  local lem = fakeLem()
  local cbs = {}
  function lem:RegisterCallback(event, fn) cbs[event] = (cbs[event] or 0) + 1; lem[event .. "Fn"] = fn end
  local ns, g = load(lem)
  local got = {}
  ns.Skin = { Fade = { setEditMode = function(on) got[#got + 1] = on end } }
  attach(ns, g)
  attach(ns, g)
  h.eq({ cbs.enter, cbs.exit }, { 1, 1 })
  lem.enterFn()
  lem.exitFn()
  h.eq(got, { true, false })
end)

h.test("no LibEditMode: attach does nothing, no error", function()
  local ns, g = load(nil)
  ns.Skin = { Fade = { setEditMode = function() error("not expected") end } }
  attach(ns, g)
end)
