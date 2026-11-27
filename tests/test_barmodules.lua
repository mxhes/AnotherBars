local h = ...
local fakes = dofile("tests/fakes.lua")

local FILES = { "Core/Util.lua", "Core/Theme.lua", "Core/DB.lua", "Core/Modules.lua", "Core/Combat.lua",
  "Core/Options.lua", "Core/Bars.lua", "Core/Grid.lua", "Core/Layout.lua", "Core/Look.lua",
  "Skin/Blizzard.lua", "Skin/Draw.lua",
  "Skin/Glow.lua", "Skin/Button.lua", "Skin/Autocast.lua", "Core/Art.lua", "Skin/Art.lua", "Skin/BarFrame.lua",
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
  h.eq(keys, { "shading", "hideArt", "ownPadding", "padding", "hotkey", "macro", "count", "fontSize" })
  h.eq(spec.settings[1].controls[1].values, { "Skin", "Bronze", "Raised", "Flat" })
  h.eq(spec.defaults, { shading = "Skin", hotkey = true, macro = true, count = true, fontSize = 10,
    hideArt = true, ownPadding = true, padding = 2 })
  local pad = spec.settings[1].controls[4]
  h.eq({ pad.min, pad.max, pad.step }, { 0, 10, 1 })
  local size = spec.settings[2].controls[4]
  h.eq(size.key, "fontSize")
  h.eq({ size.min, size.max, size.step }, { 6, 16, 1 })
end)

h.test("create skins each existing button with the bar's opts", function()
  local ns, rec = load()
  local client = fakes.client()
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
  client.restore()
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
  local client = fakes.client()
  local p1, p2 = fakes.frame("PetActionButton1"), fakes.frame("PetActionButton2")
  fakes.withGlobals({ PetActionButton1 = p1, PetActionButton2 = p2 }, function()
    local spec = ns.Modules.get("pet")
    spec.create(spec)
  end)
  h.eq(rec.badges, { p1, p2 })
  client.restore()
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

h.test("final: pet and stance updates refresh their buttons", function()
  local ns = load()
  local refreshed = {}
  ns.Skin.Button.refresh = function(b) refreshed[#refreshed + 1] = b end
  local p1, s1 = fakes.frame("PetActionButton1"), fakes.frame("StanceButton1")
  local petBar, stanceBar = { Update = function() end }, { UpdateState = function() end }
  local client = fakes.client()
  fakes.withGlobals({ PetActionButton1 = p1, StanceButton1 = s1, PetActionBar = petBar, StanceBar = stanceBar,
    GetPetActionInfo = function() return nil, nil, nil, nil, false, false end }, function()
    ns.Modules.get("pet").create(ns.Modules.get("pet"))
    ns.Modules.get("stance").create(ns.Modules.get("stance"))
    refreshed = {}
    petBar:Update()
    stanceBar:UpdateState()
  end)
  h.eq(refreshed, { p1, s1 })
  client.restore()
end)

h.test("padding defaults: own padding on except the Stance Bar", function()
  local ns = load()
  for _, spec in ipairs(ns.Modules.list()) do
    h.eq(spec.defaults.hideArt, true, spec.id)
    h.eq(spec.defaults.padding, 2, spec.id)
    h.eq(spec.defaults.ownPadding, spec.id ~= "stance", spec.id)
  end
end)

h.test("the Stance Bar's own padding tooltip says why it starts off", function()
  local ns = load()
  local function tip(id)
    for _, s in ipairs(ns.Modules.get(id).settings) do
      for _, c in ipairs(s.controls) do if c.key == "ownPadding" then return c.tooltip end end
    end
  end
  h.eq(tip("stance"), "The Stance Bar re-lays out in combat; its gaps return to Blizzard's until combat ends")
  h.eq(tip("bar1") ~= tip("stance"), true)
end)

h.test("every label fits in 24 characters", function()
  local ns = load()
  for _, spec in ipairs(ns.Modules.list()) do
    for _, s in ipairs(spec.settings) do
      for _, c in ipairs(s.controls) do h.eq(#c.label <= 24, true, c.label) end
    end
  end
end)

-- Records Layout calls instead of moving frames.
local function stubLayout(ns)
  local rec = { repack = {}, reset = {}, watch = {}, show = {} }
  ns.Layout.repack = function(id, spacing) rec.repack[#rec.repack + 1] = { id, spacing } end
  ns.Layout.reset = function(id) rec.reset[#rec.reset + 1] = id end
  ns.Layout.watch = function(id, fn) rec.watch[id] = fn end
  ns.Layout.onShowRepack = function(id, fn) rec.show[id] = fn end
  return rec
end

h.test("create repacks with the bar's padding", function()
  local ns = load()
  local client = fakes.client()
  local rec = stubLayout(ns)
  local spec = ns.Modules.get("bar2")
  spec.create(spec)
  h.eq(rec.repack, { { "bar2", 2 } })
  client.restore()
end)

h.test("padding 0 uses the edge step", function()
  local ns = load()
  local client = fakes.client()
  local rec = stubLayout(ns)
  ns.DB.profile().skin = "slate"
  ns.Options.set("bar2", "padding", 0)
  -- Slate edge 2: 36 px buttons step 36 - 4 + 1 = 33, a gap of -3
  h.eq(rec.repack[#rec.repack], { "bar2", -3 })
  client.restore()
end)

h.test("own padding off resets the bar", function()
  local ns = load()
  local client = fakes.client()
  local rec = stubLayout(ns)
  ns.Options.set("bar1", "ownPadding", false)
  h.eq(rec.reset, { "bar1" })
  h.eq(rec.repack, {})
  client.restore()
end)

h.test("the stance bar starts at Blizzard's padding", function()
  local ns = load()
  local client = fakes.client()
  local rec = stubLayout(ns)
  fakes.withGlobals({ StanceBar = { UpdateState = function() end } }, function()
    local spec = ns.Modules.get("stance")
    spec.create(spec)
  end)
  h.eq(rec.repack, {})
  h.eq(rec.reset, { "stance" })
  client.restore()
end)

h.test("Blizzard's layout, a shown button and the layout events re-run it", function()
  local ns = load()
  local client = fakes.client()
  local rec = stubLayout(ns)
  local spec = ns.Modules.get("bar2")
  spec.create(spec)
  rec.watch.bar2("bar2", false)
  rec.show.bar2()
  h.eq(#rec.repack, 3)
  client.fire("EDIT_MODE_LAYOUTS_UPDATED")
  client.fire("PLAYER_ENTERING_WORLD")
  -- created bars only: bar2 twice more
  h.eq(#rec.repack, 5)
  for _, r in ipairs(rec.repack) do h.eq(r[1], "bar2") end
  client.restore()
end)

h.test("a skin change re-runs every created bar's layout", function()
  local ns = load()
  local client = fakes.client()
  local rec = stubLayout(ns)
  ns.Modules.get("bar2").create(ns.Modules.get("bar2"))
  rec.repack = {}
  ns.BarModules.Common.layoutAll()
  h.eq(rec.repack, { { "bar2", 2 } })
  client.restore()
end)

h.test("the bar's art follows Hide Blizzard art", function()
  local ns = load()
  local client = fakes.client()
  stubLayout(ns)
  local got = {}
  ns.Skin.Art.apply = function(id, hide) got[#got + 1] = { id, hide } end
  ns.Modules.get("bar1").create(ns.Modules.get("bar1"))
  ns.Options.set("bar1", "hideArt", false)
  h.eq(got, { { "bar1", true }, { "bar1", false } })
  client.restore()
end)

h.test("the bar frame shows at own padding 0 only", function()
  local ns = load()
  local client = fakes.client()
  local rec = stubLayout(ns)
  local got = {}
  ns.Skin.BarFrame.apply = function(id, on) got[#got + 1] = { id, on }; rec.order = (rec.order or "") .. "f" end
  local repack = ns.Layout.repack
  ns.Layout.repack = function(...) rec.order = (rec.order or "") .. "r"; repack(...) end
  ns.Modules.get("bar1").create(ns.Modules.get("bar1"))
  ns.Options.set("bar1", "padding", 0)
  ns.Options.set("bar1", "ownPadding", false)
  h.eq(got, { { "bar1", false }, { "bar1", true }, { "bar1", false } })
  h.eq(rec.order, "rfrf" .. "f")
  client.restore()
end)
