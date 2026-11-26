local h = ...
local fakes = dofile("tests/fakes.lua")

local function load()
  local ns = h.load({ "Core/Util.lua", "Core/Theme.lua", "Core/DB.lua", "Core/Look.lua" })
  ns.db, ns.chardb = ns.DB.init(nil, nil)
  return ns
end

h.test("edge width per border", function()
  local Look = load().Look
  h.eq(Look.edgeWidth("round"), 3)
  h.eq(Look.edgeWidth("bevel"), 5)
  h.eq(Look.edgeWidth("thin"), 2)
end)

h.test("edges shade panelBorder, goldLine on hover", function()
  local ns = load()
  local T, Look = ns.Theme, ns.Look
  local rects = T.edgeRects("bevel")
  local edges = Look.edges("bevel", false)
  h.eq(#edges, 5)
  for i, e in ipairs(edges) do
    h.eq(e.inset, rects[i].inset)
    h.eq(e.color, T.scaleColor(T.colors.panelBorder, rects[i].shade))
  end
  local hover = Look.edges("bevel", true)
  h.eq(hover[2].color, T.scaleColor(T.colors.goldLine, rects[2].shade))
  local round = Look.edges("round", false)
  h.eq(#round, 3)
  h.eq(round[1].color, T.scaleColor(T.colors.panelBorder, 0.35))
end)

h.test("shading follows the skin unless the bar picks one", function()
  local ns = load()
  h.eq(ns.Look.shading("Skin", ns.Theme.skins.forge), "raised")
  h.eq(ns.Look.shading("Flat", ns.Theme.skins.forge), "flat")
  h.eq(ns.Look.shading(nil, ns.Theme.skins.classic), "bronze")
end)

h.test("icon tint: range, then mana, then unusable", function()
  local Look = load().Look
  h.eq(Look.iconTint(false, true, false), { 0.8, 0.1, 0.1 })
  h.eq(Look.iconTint(true, false, true), { 0.5, 0.5, 1 })
  h.eq(Look.iconTint(true, false, false), { 0.55, 0.55, 0.55, desaturate = true })
  h.eq(Look.iconTint(true, true, false), { 1, 1, 1 })
  h.eq(Look.iconTint(nil, true, false), nil)
  h.eq(Look.iconTint(true, nil, false), nil)
end)

h.test("font sizes scale from the hotkey size", function()
  local Look = load().Look
  h.eq(Look.fontSizes(10), { hotkey = 10, count = 12, macro = 9, cooldown = 15 })
  h.eq(Look.fontSizes(nil).hotkey, 10)
end)

h.test("skin comes from the profile, Classic when unknown", function()
  local ns = load()
  h.eq(ns.Look.skin().id, "classic")
  ns.DB.profile().skin = "slate"
  h.eq(ns.Look.skin().id, "slate")
  ns.DB.profile().skin = "gilded" -- removed skin: a saved one shows as Classic
  h.eq(ns.Look.skin().id, "classic")
  ns.DB.profile().skin = "nope"
  h.eq(ns.Look.skin().id, "classic")
end)

h.test("plain drops secret values", function()
  local ns = load()
  local s = fakes.secret(1)
  fakes.withGlobals({ issecretvalue = fakes.isSecret }, function()
    h.eq(ns.Util.plain(s), nil)
    h.eq(ns.Util.plain(false), false)
  end)
  fakes.withGlobals({ issecretvalue = fakes.NIL }, function()
    h.eq(ns.Util.plain(true), true)
  end)
end)

h.test("framed only at own padding and padding 0", function()
  local Look = load().Look
  h.eq(Look.framed(true, 0), true)
  h.eq(Look.framed(true, 2), false)
  h.eq(Look.framed(false, 0), false)
end)
