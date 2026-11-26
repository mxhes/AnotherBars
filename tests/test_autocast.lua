local h = ...
local fakes = dofile("tests/fakes.lua")

local FILES = { "Core/Util.lua", "Core/Theme.lua", "Core/DB.lua", "Core/Look.lua",
  "Skin/Blizzard.lua", "Skin/Draw.lua", "Skin/Autocast.lua" }

local function setup()
  local client = fakes.client()
  local ns = h.load(FILES)
  ns.db, ns.chardb = ns.DB.init(nil, nil)
  local b = fakes.frame("PetActionButton1")
  b.AutoCastOverlay = fakes.frame()
  local badge = ns.Skin.Autocast.attach(b, fakes.frame())
  return ns, b, badge, client
end

h.test("no badge when the ability can't autocast", function()
  local ns, b, badge, client = setup()
  ns.Skin.Autocast.set(b, false, false)
  h.eq(badge.frame._shown, false)
  client.restore()
end)

h.test("empty badge when autocast is off", function()
  local ns, b, badge, client = setup()
  ns.Skin.Autocast.set(b, true, false)
  h.eq(badge.frame._shown, true)
  h.eq(badge.dot._shown, false)
  client.restore()
end)

h.test("gold dot when autocast is on", function()
  local ns, b, badge, client = setup()
  ns.Skin.Autocast.set(b, true, true)
  h.eq(badge.frame._shown, true)
  h.eq(badge.dot._shown, true)
  h.eq(badge.playing, true)
  ns.Skin.Autocast.set(b, true, false)
  h.eq(badge.playing, false)
  client.restore()
end)

h.test("secret autocast values change nothing", function()
  local ns, b, badge, client = setup()
  ns.Skin.Autocast.set(b, true, true)
  ns.Skin.Autocast.set(b, fakes.secret(1), false)
  ns.Skin.Autocast.set(b, true, fakes.secret(2))
  h.eq(badge.frame._shown, true)
  h.eq(badge.dot._shown, true)
  client.restore()
end)

h.test("Blizzard's autocast art goes to alpha 0", function()
  local _, b, _, client = setup()
  h.eq(b.AutoCastOverlay._alpha, 0)
  client.restore()
end)

h.test("ring lines follow the skin", function()
  local ns, _, badge, client = setup()
  h.eq(#badge.shown, #ns.Theme.ringRoundShades)
  ns.DB.profile().skin = "gilded"
  ns.Skin.Autocast.relayoutAll()
  h.eq(#badge.shown, #ns.Theme.edgeRects("gilded"))
  client.restore()
end)

h.test("final: attaching twice keeps one badge", function()
  local ns, b, badge, client = setup()
  h.eq(ns.Skin.Autocast.attach(b, fakes.frame()) == badge, true)
  client.restore()
end)
