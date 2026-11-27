local h = ...
local fakes = dofile("tests/fakes.lua")

local FILES = { "Core/Util.lua", "Core/Theme.lua", "Core/DB.lua", "Core/Combat.lua", "Core/Bars.lua",
  "Core/Grid.lua", "Core/Layout.lua", "Core/Look.lua", "Skin/Draw.lua", "Skin/BarFrame.lua" }

-- A fake main bar of `n` buttons in rows of 3, with Layout's last repack
-- faked: cells as Grid would give them.
local function setup(n, skin)
  local client = fakes.client()
  local bar = fakes.frame("MainMenuBar")
  _G.MainMenuBar = bar
  local ns = h.load(FILES)
  ns.db, ns.chardb = ns.DB.init(nil, nil)
  ns.DB.profile().skin = skin or "slate"
  local cells, buttons = {}, {}
  for i = 1, n do
    local b = fakes.frame("ActionButton" .. i)
    b.GetFrameLevel = function() return 5 end
    buttons[i] = b
    cells[i] = { (i - 1) % 3, -math.floor((i - 1) / 3) }
  end
  ns.Layout.cells = function() return cells, buttons end
  local function edges()
    local last = buttons[n]
    return { left = buttons[1], right = buttons[math.min(n, 3)], top = buttons[1], bottom = last }
  end
  ns.Layout.edges = edges
  local function cleanup()
    _G.MainMenuBar = nil
    client.restore()
  end
  return ns, client, bar, buttons, cleanup
end

local function shownLines(ns)
  local n = 0
  for _, t in ipairs(ns.Skin.BarFrame.state("bar1").lines) do if t._shown then n = n + 1 end end
  return n
end

local function pointsOf(t)
  local out = {}
  for _, p in ipairs(t._points or {}) do out[p[1]] = { p[2], p[3], p[4], p[5] } end
  return out
end

h.test("padding 0 shows one frame around the bar", function()
  local ns, _, _, buttons, cleanup = setup(6)
  ns.Skin.BarFrame.apply("bar1", true)
  local st = ns.Skin.BarFrame.state("bar1")
  h.eq(st.frame._shown, true)
  local p = pointsOf(st.frame)
  h.eq(p.LEFT[1], buttons[1])
  h.eq(p.RIGHT[1], buttons[3])
  h.eq(p.TOP[1], buttons[1])
  h.eq(p.BOTTOM[1], buttons[6])
  h.eq(st.frame._level, 3)
  cleanup()
end)

h.test("one 1 px divider between each pair of neighbours", function()
  local ns, _, _, buttons, cleanup = setup(6)
  ns.Skin.BarFrame.apply("bar1", true)
  h.eq(shownLines(ns), 7)
  local st = ns.Skin.BarFrame.state("bar1")
  -- the first divider: between buttons 1 and 2 (Slate edge 2)
  local p = pointsOf(st.lines[1])
  h.eq(p.TOPLEFT, { buttons[1], "TOPRIGHT", -2, -2 })
  h.eq(p.BOTTOMRIGHT, { buttons[1], "BOTTOMRIGHT", -1, 2 })
  cleanup()
end)

h.test("a horizontal divider sits in the 1 px under the upper icon", function()
  local ns, _, _, buttons, cleanup = setup(4)
  ns.Skin.BarFrame.apply("bar1", true)
  local st = ns.Skin.BarFrame.state("bar1")
  local found
  for _, t in ipairs(st.lines) do
    local p = pointsOf(t)
    if t._shown and p.TOPLEFT and p.TOPLEFT[2] == "BOTTOMLEFT" then found = p end
  end
  h.eq(found.TOPLEFT, { buttons[1], "BOTTOMLEFT", 2, 2 })
  h.eq(found.BOTTOMRIGHT, { buttons[1], "BOTTOMRIGHT", -2, 1 })
  cleanup()
end)

h.test("Slate draws its edge lines, Classic the round backdrop", function()
  local ns, _, _, _, cleanup = setup(3, "slate")
  ns.Skin.BarFrame.apply("bar1", true)
  local st = ns.Skin.BarFrame.state("bar1")
  local shown = 0
  for _, r in ipairs(st.rects) do if r[1]._shown then shown = shown + 1 end end
  h.eq(shown, 2)
  cleanup()
  local ns2, _, _, _, cleanup2 = setup(3, "classic")
  ns2.Skin.BarFrame.apply("bar1", true)
  local st2 = ns2.Skin.BarFrame.state("bar1")
  h.eq(type(st2.frame._backdrop), "table")
  for _, r in ipairs(st2.rects) do h.eq(r[1]._shown, false) end
  cleanup2()
end)

h.test("off hides the frame; a smaller bar hides the extra lines", function()
  local ns, _, _, _, cleanup = setup(6)
  ns.Skin.BarFrame.apply("bar1", true)
  ns.Skin.BarFrame.apply("bar1", false)
  h.eq(ns.Skin.BarFrame.state("bar1").frame._shown, false)
  cleanup()
  local ns2, _, _, buttons, cleanup2 = setup(6)
  ns2.Skin.BarFrame.apply("bar1", true)
  local cells = { { 0, 0 }, { 1, 0 }, { 2, 0 } }
  ns2.Layout.cells = function() return cells, { buttons[1], buttons[2], buttons[3] } end
  ns2.Skin.BarFrame.apply("bar1", true)
  h.eq(shownLines(ns2), 2)
  cleanup2()
end)

h.test("applying twice makes one frame", function()
  local ns, _, _, _, cleanup = setup(3)
  ns.Skin.BarFrame.apply("bar1", true)
  local f = ns.Skin.BarFrame.state("bar1").frame
  ns.Skin.BarFrame.apply("bar1", true)
  h.eq(ns.Skin.BarFrame.state("bar1").frame, f)
  cleanup()
end)

h.test("no repack yet: nothing drawn, no error", function()
  local ns, _, _, _, cleanup = setup(3)
  ns.Layout.cells = function() return nil end
  ns.Layout.edges = function() return nil end
  ns.Skin.BarFrame.apply("bar1", true)
  h.eq(ns.Skin.BarFrame.state("bar1"), nil)
  cleanup()
end)
