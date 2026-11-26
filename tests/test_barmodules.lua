local h = ...
local fakes = dofile("tests/fakes.lua")

local FILES = { "Core/Util.lua", "Core/Theme.lua", "Core/DB.lua", "Core/Modules.lua", "Core/Combat.lua",
  "Core/Options.lua", "Core/Bars.lua", "Core/Look.lua", "Skin/Blizzard.lua", "Skin/Draw.lua",
  "Skin/Glow.lua", "Skin/Button.lua", "Skin/Autocast.lua",
  "Bars/Common.lua", "Bars/ActionBar.lua", "Bars/Stance.lua", "Bars/Pet.lua" }

-- Loads the bar modules with Button.skin / Autocast faked; returns ns and
-- what they recorded.
local function load()
  local ns = h.load(FILES)
  ns.db, ns.chardb = ns.DB.init(nil, nil)
  local rec = { skinned = {}, badges = {} }
  ns.Skin.Button.skin = function(b, opts) rec.skinned[#rec.skinned + 1] = { b, opts } end
  ns.Skin.Button.state = function() return { front = fakes.frame() } end
  ns.Skin.Autocast.attach = function(b) rec.badges[#rec.badges + 1] = b end
  return ns, rec
end

h.test("ten bar modules in Bars order", function()
  local ns = load()
  local ids = {}
  for i, spec in ipairs(ns.Modules.list()) do
    ids[i] = spec.id
    h.eq(spec.kind, "bar")
    h.eq(spec.system.index, ns.Bars.get(spec.id).system)
    h.eq(spec.blizzard, { ns.Bars.get(spec.id).frame })
  end
  h.eq(ids, { "bar1", "bar2", "bar3", "bar4", "bar5", "bar6", "bar7", "bar8", "stance", "pet" })
end)

h.test("Look and Text sections with their defaults", function()
  local ns = load()
  local spec = ns.Modules.get("bar2")
  h.eq(spec.settings[1].section, "Look")
  h.eq(spec.settings[2].section, "Text")
  local keys = {}
  for _, s in ipairs(spec.settings) do
    for _, c in ipairs(s.controls) do
      keys[#keys + 1] = c.key
      h.eq(type(c.tooltip), "string", c.key)
    end
  end
  h.eq(keys, { "shading", "hotkey", "macro", "count", "fontSize" })
  h.eq(spec.settings[1].controls[1].values, { "Skin", "Bronze", "Raised", "Flat" })
  h.eq(spec.defaults, { shading = "Skin", hotkey = true, macro = true, count = true, fontSize = 10 })
  local size = spec.settings[2].controls[4]
  h.eq({ size.min, size.max, size.step }, { 6, 16, 1 })
end)

h.test("create skins each existing button with the bar's opts", function()
  local ns, rec = load()
  local b1, b3 = fakes.frame("MultiBarBottomLeftButton1"), fakes.frame("MultiBarBottomLeftButton3")
  fakes.withGlobals({ MultiBarBottomLeftButton1 = b1, MultiBarBottomLeftButton3 = b3,
    MultiBarBottomLeft = fakes.frame("MultiBarBottomLeft") }, function()
    local spec = ns.Modules.get("bar2")
    spec.create(spec)
    h.eq(spec.frame ~= nil, true)
  end)
  h.eq(#rec.skinned, 2)
  h.eq(rec.skinned[1][1], b1)
  h.eq(rec.skinned[2][1], b3)
  h.eq(rec.skinned[1][2], { shading = "Skin", hotkey = true, macro = true, count = true, fontSize = 10 })
end)

h.test("a setting re-skins only its bar", function()
  local ns, rec = load()
  local b = fakes.frame("MultiBarBottomLeftButton1")
  local other = fakes.frame("ActionButton1")
  fakes.withGlobals({ MultiBarBottomLeftButton1 = b, ActionButton1 = other }, function()
    ns.Options.set("bar2", "hotkey", false)
  end)
  h.eq(#rec.skinned, 1)
  h.eq(rec.skinned[1][1], b)
  h.eq(rec.skinned[1][2].hotkey, false)
end)

h.test("pet create adds a badge to each pet button", function()
  local ns, rec = load()
  local p1, p2 = fakes.frame("PetActionButton1"), fakes.frame("PetActionButton2")
  fakes.withGlobals({ PetActionButton1 = p1, PetActionButton2 = p2 }, function()
    local spec = ns.Modules.get("pet")
    spec.create(spec)
  end)
  h.eq(rec.badges, { p1, p2 })
end)

h.test("Core.init creates enabled bars only", function()
  local client = fakes.client()
  local ns = h.load(FILES)
  local created = {}
  for _, spec in ipairs(ns.Modules.list()) do
    spec.create = function(s) created[#created + 1] = s.id end
  end
  local loadCore = loadfile("AnotherBars/EditMode/Panel.lua")
  loadCore("AnotherBars", ns)
  loadfile("AnotherBars/EditMode/System.lua")("AnotherBars", ns)
  loadfile("AnotherBars/Core/Core.lua")("AnotherBars", ns)
  fakes.withGlobals({ AnotherBarsDB = { profiles = { Default = { modules = { bar3 = { enabled = false } } } } },
    AnotherBarsCharDB = fakes.NIL, SlashCmdList = {},
    SLASH_ANOTHERBARS1 = fakes.NIL, SLASH_ANOTHERBARS2 = fakes.NIL }, function()
    ns.Core.init()
  end)
  h.eq(#created, 9)
  for _, id in ipairs(created) do h.eq(id ~= "bar3", true) end
  client.restore()
end)
