local h = ...
local fakes = dofile("tests/fakes.lua")

-- A fake bar1 (MainMenuBar) with three 36 px buttons in a row, 2 px apart.
-- As on Forever's main bar, each button sits in its own container and is
-- anchored CENTER to it (Blizzard's anchor); Blizzard moves the containers.
local function setup(inCombat)
  local client = fakes.client({ inCombat = inCombat })
  local bar = fakes.frame("MainMenuBar")
  bar.UpdateGridLayout = function() end
  _G.MainMenuBar = bar
  local buttons = {}
  for i = 1, 3 do
    local c = fakes.frame("MainActionBarButtonContainer" .. i)
    local b = fakes.frame("ActionButton" .. i)
    b._left, b._bottom, b._width, b._height = 100 + (i - 1) * 38, 50, 36, 36
    b._points = { { "CENTER", c, "CENTER", 0, 0 } }
    b._container = c
    _G["ActionButton" .. i] = b
    buttons[i] = b
  end
  local ns = h.load({ "Core/Util.lua", "Core/DB.lua", "Core/Combat.lua", "Core/Bars.lua", "Core/Grid.lua", "Core/Layout.lua" })
  local function cleanup()
    _G.MainMenuBar = nil
    for i = 1, 12 do _G["ActionButton" .. i] = nil end
    client.restore()
  end
  return ns, client, bar, buttons, cleanup
end

local function points(b)
  local out = {}
  for _, c in ipairs(b.calls) do
    if c[1] == "SetPoint" then out[#out + 1] = { c[2], c[3], c[4], c[5], c[6] } end
  end
  return out
end

local function keys(t)
  local out = {}
  for k in pairs(t) do if k ~= "calls" then out[#out + 1] = tostring(k) end end
  table.sort(out)
  return out
end

h.test("repack moves buttons 2..n, never button 1", function()
  local ns, _, _, buttons, cleanup = setup(false)
  ns.Layout.repack("bar1", 0)
  h.eq(points(buttons[1]), {})
  h.eq(points(buttons[2]), { { "CENTER", buttons[2]._container, "CENTER", -2, 0 } })
  h.eq(points(buttons[3]), { { "CENTER", buttons[3]._container, "CENTER", -4, 0 } })
  cleanup()
end)

h.test("relayout in combat queues the repack", function()
  local ns, client, _, buttons, cleanup = setup(true)
  ns.Layout.repack("bar1", 0)
  h.eq(points(buttons[2]), {})
  h.eq(ns.Combat.pending(), 1)
  client.setCombat(false)
  client.fire("PLAYER_REGEN_ENABLED")
  h.eq(points(buttons[2]), { { "CENTER", buttons[2]._container, "CENTER", -2, 0 } })
  cleanup()
end)

h.test("repack skips hidden buttons without a position", function()
  local ns, _, _, buttons, cleanup = setup(false)
  buttons[3]._shown = false
  buttons[3]._left = nil
  ns.Layout.repack("bar1", 0)
  h.eq(points(buttons[3]), {})
  h.eq(points(buttons[2]), { { "CENTER", buttons[2]._container, "CENTER", -2, 0 } })
  cleanup()
end)

h.test("repack keeps the slot of a hidden middle button", function()
  local ns, _, _, buttons, cleanup = setup(false)
  buttons[2]._shown = false
  ns.Layout.repack("bar1", 0)
  h.eq(points(buttons[3]), { { "CENTER", buttons[3]._container, "CENTER", -4, 0 } })
  cleanup()
end)

-- Moves a fake button by (dx, dy), as the client would after SetPoint.
local function move(b, dx, dy)
  b._left, b._bottom = b._left + dx, b._bottom + dy
end

h.test("repack twice gives the same anchors", function()
  local ns, _, _, buttons, cleanup = setup(false)
  ns.Layout.repack("bar1", 0)
  move(buttons[2], -2, 0)
  move(buttons[3], -4, 0)
  for i = 1, 3 do buttons[i].calls = {} end
  ns.Layout.repack("bar1", 0)
  h.eq(points(buttons[2]), { { "CENTER", buttons[2]._container, "CENTER", -2, 0 } })
  h.eq(points(buttons[3]), { { "CENTER", buttons[3]._container, "CENTER", -4, 0 } })
  cleanup()
end)

h.test("buttons follow when Blizzard moves the containers", function()
  -- after our repack Blizzard lays the bar out again by moving the
  -- containers (the buttons keep our offsets to them): a new repack keeps
  -- the same offsets, it does not add them up
  local ns, _, _, buttons, cleanup = setup(false)
  ns.Layout.repack("bar1", 0)
  move(buttons[2], -2, 0)
  move(buttons[3], -4, 0)
  for i = 1, 3 do move(buttons[i], 0, 300); buttons[i].calls = {} end
  ns.Layout.repack("bar1", 0)
  h.eq(points(buttons[3]), { { "CENTER", buttons[3]._container, "CENTER", -4, 0 } })
  cleanup()
end)

h.test("a Blizzard re-anchor becomes the new base", function()
  local ns, _, _, buttons, cleanup = setup(false)
  ns.Layout.repack("bar1", 0)
  move(buttons[2], -2, 0)
  -- Blizzard anchors button 2 anew (its own offset, our offset gone)
  local other = fakes.frame("Other")
  buttons[2]._points = { { "TOPLEFT", other, "TOPLEFT", 5, 0 } }
  move(buttons[2], 2, 0)
  buttons[2].calls = {}
  ns.Layout.repack("bar1", 0)
  h.eq(points(buttons[2]), { { "TOPLEFT", other, "TOPLEFT", 3, 0 } })
  cleanup()
end)

h.test("a button with two anchors is left alone", function()
  local ns, _, _, buttons, cleanup = setup(false)
  buttons[3]._points[2] = { "BOTTOMRIGHT", buttons[3]._container, "BOTTOMRIGHT", 0, 0 }
  ns.Layout.repack("bar1", 0)
  h.eq(points(buttons[3]), {})
  cleanup()
end)

h.test("watch calls back with combat flag", function()
  local ns, client, bar, _, cleanup = setup(false)
  local got = {}
  ns.Layout.watch("bar1", function(id, inCombat) got[#got + 1] = { id, inCombat } end)
  bar:UpdateGridLayout()
  client.setCombat(true)
  bar:UpdateGridLayout()
  h.eq(got, { { "bar1", false }, { "bar1", true } })
  cleanup()
end)

h.test("watch hooks a bar only once", function()
  local ns, _, bar, _, cleanup = setup(false)
  local n = 0
  ns.Layout.watch("bar1", function() n = n + 1 end)
  ns.Layout.watch("bar1", function() n = n + 1 end)
  bar:UpdateGridLayout()
  h.eq(n, 1)
  cleanup()
end)

h.test("missing bar is ignored", function()
  local ns, _, _, _, cleanup = setup(false)
  _G.MainMenuBar = nil
  ns.Layout.watch("bar1", function() end)
  ns.Layout.repack("bar1", 0)
  ns.Layout.watch("nope", function() end)
  ns.Layout.repack("bar2", 0) -- no MultiBarBottomLeft buttons exist
  cleanup()
end)

h.test("no fields written on Blizzard frames", function()
  local ns, _, bar, buttons, cleanup = setup(false)
  local before = { keys(bar) }
  for i = 1, 3 do before[#before + 1] = keys(buttons[i]) end
  ns.Layout.repack("bar1", 0)
  local after = { keys(bar) }
  for i = 1, 3 do after[#after + 1] = keys(buttons[i]) end
  h.eq(after, before)
  cleanup()
end)

h.test("hidden buttons stay out of the grid and the edges", function()
  -- "# of Icons" 2: Blizzard hides button 3 on a stale anchor far away
  local ns, _, _, buttons, cleanup = setup(false)
  buttons[3]._shown = false
  buttons[3]._left = 900
  ns.Layout.repack("bar1", 0)
  h.eq(points(buttons[3]), {})
  h.eq(ns.Layout.edges("bar1").right, buttons[2])
  local cells = ns.Layout.cells("bar1")
  h.eq(#cells, 2)
  cleanup()
end)

h.test("reset leaves a button Blizzard re-anchored since our repack", function()
  local ns, _, _, buttons, cleanup = setup(false)
  ns.Layout.repack("bar1", 0)
  local other = fakes.frame("Other")
  buttons[2]._points = { { "TOPLEFT", other, "TOPLEFT", 7, 0 } }
  buttons[2].calls = {}
  ns.Layout.reset("bar1")
  h.eq(points(buttons[2]), {})
  cleanup()
end)

h.test("reset puts back Blizzard's anchors", function()
  local ns, _, _, buttons, cleanup = setup(false)
  ns.Layout.repack("bar1", 0)
  move(buttons[2], -2, 0)
  move(buttons[3], -4, 0)
  ns.Layout.reset("bar1")
  h.eq(points(buttons[1]), {})
  local p2, p3 = points(buttons[2]), points(buttons[3])
  h.eq(p2[#p2], { "CENTER", buttons[2]._container, "CENTER", 0, 0 })
  h.eq(p3[#p3], { "CENTER", buttons[3]._container, "CENTER", 0, 0 })
  -- a second reset has nothing left to put back
  for i = 1, 3 do buttons[i].calls = {} end
  ns.Layout.reset("bar1")
  h.eq(points(buttons[2]), {})
  cleanup()
end)

h.test("reset in combat replaces a queued repack", function()
  local ns, client, _, buttons, cleanup = setup(false)
  ns.Layout.repack("bar1", 0)
  client.setCombat(true)
  ns.Layout.repack("bar1", 5)
  ns.Layout.reset("bar1")
  h.eq(ns.Combat.pending(), 1)
  client.setCombat(false)
  client.fire("PLAYER_REGEN_ENABLED")
  local p2 = points(buttons[2])
  h.eq(p2[#p2], { "CENTER", buttons[2]._container, "CENTER", 0, 0 })
  cleanup()
end)

h.test("cells and edges of the last repack", function()
  local ns, _, _, buttons, cleanup = setup(false)
  ns.Layout.repack("bar1", 0)
  local cells, list = ns.Layout.cells("bar1")
  h.eq(cells, { { 0, 0 }, { 1, 0 }, { 2, 0 } })
  h.eq(list, buttons)
  local e = ns.Layout.edges("bar1")
  h.eq(e.left, buttons[1])
  h.eq(e.right, buttons[3])
  h.eq(e.top == buttons[1] or e.top == buttons[2] or e.top == buttons[3], true)
  h.eq(e.bottom ~= nil, true)
  h.eq(ns.Layout.edges("bar2"), nil)
  cleanup()
end)

h.test("onShowRepack hooks each button's OnShow once", function()
  local ns, _, _, buttons, cleanup = setup(false)
  local n = 0
  ns.Layout.onShowRepack("bar1", function() n = n + 1 end)
  ns.Layout.onShowRepack("bar1", function() n = n + 100 end)
  buttons[2]._scripts.OnShow(buttons[2])
  h.eq(n, 1)
  cleanup()
end)
