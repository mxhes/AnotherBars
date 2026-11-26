local h = ...
local fakes = dofile("tests/fakes.lua")

-- A fake bar1 (MainMenuBar) with three 36 px buttons in a row, 2 px apart.
local function setup(inCombat)
  local client = fakes.client({ inCombat = inCombat })
  local bar = fakes.frame("MainMenuBar")
  bar.UpdateGridLayout = function() end
  _G.MainMenuBar = bar
  local buttons = {}
  for i = 1, 3 do
    local b = fakes.frame("ActionButton" .. i)
    b._left, b._bottom, b._width, b._height = 100 + (i - 1) * 38, 50, 36, 36
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
  h.eq(points(buttons[2]), { { "TOPLEFT", buttons[1], "TOPLEFT", 36, 0 } })
  h.eq(points(buttons[3]), { { "TOPLEFT", buttons[1], "TOPLEFT", 72, 0 } })
  cleanup()
end)

h.test("relayout in combat queues the repack", function()
  local ns, client, _, buttons, cleanup = setup(true)
  ns.Layout.repack("bar1", 0)
  h.eq(points(buttons[2]), {})
  h.eq(ns.Combat.pending(), 1)
  client.setCombat(false)
  client.fire("PLAYER_REGEN_ENABLED")
  h.eq(points(buttons[2]), { { "TOPLEFT", buttons[1], "TOPLEFT", 36, 0 } })
  cleanup()
end)

h.test("repack skips hidden buttons", function()
  local ns, _, _, buttons, cleanup = setup(false)
  buttons[3]._shown = false
  ns.Layout.repack("bar1", 0)
  h.eq(points(buttons[3]), {})
  h.eq(points(buttons[2]), { { "TOPLEFT", buttons[1], "TOPLEFT", 36, 0 } })
  cleanup()
end)

h.test("repack keeps the slot of a hidden middle button", function()
  local ns, _, _, buttons, cleanup = setup(false)
  buttons[2]._shown = false
  ns.Layout.repack("bar1", 0)
  h.eq(points(buttons[3]), { { "TOPLEFT", buttons[1], "TOPLEFT", 72, 0 } })
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
