local h = ...

local function load()
  return h.load({ "Core/Util.lua", "Core/Bars.lua" })
end

h.test("ten bars in order", function()
  local ids = {}
  for i, bar in ipairs(load().Bars.list) do ids[i] = bar.id end
  h.eq(ids, { "bar1", "bar2", "bar3", "bar4", "bar5", "bar6", "bar7", "bar8", "stance", "pet" })
end)

h.test("ids unique and labels set", function()
  local ns = load()
  local seen = {}
  for _, bar in ipairs(ns.Bars.list) do
    h.eq(seen[bar.id], nil, bar.id .. " unique")
    seen[bar.id] = true
    h.eq(type(bar.label), "string", bar.id .. " label")
    h.eq(type(bar.frame), "string", bar.id .. " frame")
    h.eq(type(bar.button), "string", bar.id .. " button")
    h.eq(type(bar.count), "number", bar.id .. " count")
    h.eq(type(bar.system), "string", bar.id .. " system")
    h.eq(ns.Bars.get(bar.id), bar)
  end
  h.eq(ns.Bars.get("bar1").frame, "MainActionBar")
  h.eq(ns.Bars.get("bar4").system, "RightBar1")
  h.eq(ns.Bars.get("pet").count, 10)
  h.eq(ns.Bars.get("nope"), nil)
end)

h.test("the main bar's frame is MainActionBar, MainMenuBar on older clients", function()
  local ns = load()
  h.eq(ns.Bars.frame("bar1"), nil)
  local old = {}
  _G.MainMenuBar = old
  h.eq(ns.Bars.frame("bar1"), old)
  local new = {}
  _G.MainActionBar = new
  h.eq(ns.Bars.frame("bar1"), new)
  _G.MainMenuBar, _G.MainActionBar = nil, nil
end)

h.test("other bars resolve their one frame name", function()
  local ns = load()
  local f = {}
  _G.MultiBarBottomLeft = f
  h.eq(ns.Bars.frame("bar2"), f)
  _G.MultiBarBottomLeft = nil
  h.eq(ns.Bars.frame("bar2"), nil)
  h.eq(ns.Bars.frame("nope"), nil)
end)
